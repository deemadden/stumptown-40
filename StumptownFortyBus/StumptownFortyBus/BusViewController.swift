//
//  BusViewController.swift
//  StumptownFortyBus
//
//  Created by Dee Madden on 5/9/15.
//  Copyright (c) 2015 RGA. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import CoreData
import Alamofire
import FastImageCache
import SwiftyJSON

class BusViewController: UIViewController {

    @IBOutlet weak var windowOneView: UIView!
    @IBOutlet weak var windowTwoView: UIView!
    @IBOutlet weak var windowThreeView: UIView!
    @IBOutlet weak var windowOneImageView: UIImageView!
    @IBOutlet weak var windowTwoImageView: UIImageView!
    @IBOutlet weak var windowThreeImageView: UIImageView!
    @IBOutlet weak var bannerView: UIView!

    // MARK: Async & CoreData properties
    var coreDataStack: CoreDataStack!
    var populatingContent = false
    var shouldLogin = false
    var user: User? {
        didSet {
            if user != nil {
                handleRefresh()
                //hideLogoutButtonItem(false)
                
            } else {
                shouldLogin = true
                //hideLogoutButtonItem(true)
            }
        }
    }
    
    // MARK: Movie players
    private var windowOneMoviePlayer: MPMoviePlayerController!
    private var windowTwoMoviePlayer: MPMoviePlayerController!
    private var windowThreeMoviePlayer: MPMoviePlayerController!
    private var bannerVideoPlayer: MPMoviePlayerController!
    
    // MARK: Data containers
    private var instagramRemoteContentCollection: Array<NSURL> = []
    private var instagramLocalContentCollection = (NSFileManager.defaultManager()
                                                .contentsOfDirectoryAtPath(
                                                    NSBundle.mainBundle().bundlePath, error: nil
                                                ) as! [String])
                                                .filter({ $0.endsWith(".jpg") || $0.endsWith(".mp4") })
    
    // MARK: MoviePlayer constraints
    private var moviePlayerHorizontalConstraint:Array<AnyObject> = []
    private var moviePlayerVerticalConstraint:Array<AnyObject> = []
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        var error: NSError?
        if let fetchRequest = coreDataStack.model.fetchRequestTemplateForName("UserFetchRequest") {
            let results = coreDataStack.context.executeFetchRequest(fetchRequest,error: &error) as! [User]
            user = results.first
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldLogin {
            performSegueWithIdentifier("login", sender: self)
            shouldLogin = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "login" && segue.destinationViewController.isKindOfClass(OauthLoginViewController.classForCoder()) {
            if let oauthLoginViewController = segue.destinationViewController as? OauthLoginViewController {
                oauthLoginViewController.coreDataStack = coreDataStack
            }
            
            if self.user != nil {
                coreDataStack.context.deleteObject(user!)
                coreDataStack.saveContext()
            }
        }
    }
    
    @IBAction func unwindToBusView (segue : UIStoryboardSegue) { }
    
    private func handleRefresh() {
        initializeMoviePlayers()
        refreshView()
        refreshContent()
        
        var timer1 = NSTimer.scheduledTimerWithTimeInterval(15.0, target: self, selector: Selector("refreshWindowOne"), userInfo: nil, repeats: true)
        var timer2 = NSTimer.scheduledTimerWithTimeInterval(17.0, target: self, selector: Selector("refreshWindowTwo"), userInfo: nil, repeats: true)
        var timer3 = NSTimer.scheduledTimerWithTimeInterval(19.0, target: self, selector: Selector("refreshWindowThree"), userInfo: nil, repeats: true)
        var timer4 = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: Selector("refreshContent"), userInfo: nil, repeats: true)
    }

    private func initializeMoviePlayers() {
        let path = NSBundle.mainBundle().pathForResource("video1", ofType:"mp4")
        let url = NSURL.fileURLWithPath(path!)
        windowOneMoviePlayer = MPMoviePlayerController(contentURL: url)!
        windowTwoMoviePlayer = MPMoviePlayerController(contentURL: url)!
        windowThreeMoviePlayer = MPMoviePlayerController(contentURL: url)!
    }

    internal func refreshView() {
        windowOneView.contentFile = ""
        windowTwoView.contentFile = ""
        windowThreeView.contentFile = ""

        refreshWindowOne()
        refreshWindowTwo()
        refreshWindowThree()
    }

    internal func refreshContent() {
        if user != nil {
            let urlString = Instagram.Router.PopularPhotos(user!.userID, user!.accessToken)
            refreshInstagramContentCollection(urlString)
        }
    }
    
    internal func refreshWindowOne() {
         refreshWindow(windowOneView,
                windowImageView: windowOneImageView,
                windowMoviePlayer: windowOneMoviePlayer)
    }

    internal func refreshWindowTwo() {
        refreshWindow(windowTwoView,
                windowImageView: windowTwoImageView,
                windowMoviePlayer: windowTwoMoviePlayer)
    }

    internal func refreshWindowThree() {
        refreshWindow(windowThreeView,
                windowImageView: windowThreeImageView,
                windowMoviePlayer: windowThreeMoviePlayer)
    }

    private func refreshWindow(windowView: UIView, windowImageView: UIImageView, windowMoviePlayer: MPMoviePlayerController) {
        
        if let randomContentFile = getRandomFile() as? String {
            windowView.contentFile = randomContentFile
        } else if let randomContentFile = getRandomFile() as? NSURL {
            windowView.contentFile = randomContentFile.absoluteString
        }

        println("windowView.contentFile:")
        println(windowView.contentFile!)
        
        if(windowView.contentFile!.endsWith(".jpg")) {
            UIView.animateWithDuration(0.2, animations: {
                windowView.alpha = 0
            }, completion: { finished in
                if (windowMoviePlayer.playbackState == MPMoviePlaybackState.Playing) {
                    windowMoviePlayer.stop()
                    windowView.removeConstraints(self.moviePlayerHorizontalConstraint)
                    windowView.removeConstraints(self.moviePlayerVerticalConstraint)
                    windowMoviePlayer.view.removeFromSuperview()
                }

                var contentImage: UIImage?
                
                if(windowView.contentFile!.beginsWith("https")) {
                    let url = NSURL(string: windowView.contentFile!)
                    
                    if let data = NSData(contentsOfURL: url!) {
                        println("Assigning remote Instagram image")
                        contentImage = UIImage(data: data)
                    }
                } else {
                    println("Loading local image")
                    contentImage = UIImage(named: windowView.contentFile!)
                }
                
                windowImageView.image = contentImage
                windowImageView.hidden = false

                UIView.animateWithDuration(0.3, animations: {
                    windowView.alpha = 1.0
                    }, completion: { finished in
                        return
                    })
            })
        } else {
            UIView.animateWithDuration(0.2, animations: {
                windowView.alpha = 0
            }, completion: { finished in
                windowImageView.hidden = true

                if (windowMoviePlayer.playbackState == MPMoviePlaybackState.Playing) {
                    windowMoviePlayer.stop()
                    windowView.removeConstraints(self.moviePlayerHorizontalConstraint)
                    windowView.removeConstraints(self.moviePlayerVerticalConstraint)
                    windowMoviePlayer.view.removeFromSuperview()
                }

                var url:NSURL?
                
                if(windowView.contentFile!.beginsWith("https")) {
                    // It's remote
                    println("Assigning remote Instagram video")
                    let url = NSURL(string: windowView.contentFile!)
                    windowMoviePlayer.movieSourceType = MPMovieSourceType.Streaming
                    windowMoviePlayer.contentURL = url
                } else {
                    // It's a local
                    println("Loading local video")
                    if let path = NSBundle.mainBundle().pathForResource(windowView.contentFile!.stringByDeletingPathExtension, ofType:"mp4") {
                        let url = NSURL.fileURLWithPath(path)
                        windowMoviePlayer.movieSourceType = MPMovieSourceType.File
                        windowMoviePlayer.contentURL = url
                    } else {
                        return
                    }
                }
                
                windowMoviePlayer.prepareToPlay()
                windowMoviePlayer.controlStyle = MPMovieControlStyle.None
                windowMoviePlayer.repeatMode = MPMovieRepeatMode.One
                windowMoviePlayer.view.setTranslatesAutoresizingMaskIntoConstraints(false)
                windowView.addSubview(windowMoviePlayer.view)

                let views = ["player": windowMoviePlayer.view]
                self.moviePlayerHorizontalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|[player]|", options: NSLayoutFormatOptions(0), metrics: nil, views: views)
                self.moviePlayerVerticalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:|[player]|", options: NSLayoutFormatOptions(0), metrics: nil, views: views)
                windowView.addConstraints(self.moviePlayerHorizontalConstraint)
                windowView.addConstraints(self.moviePlayerVerticalConstraint)

                windowMoviePlayer.play()

                UIView.animateWithDuration(0.3, animations: {
                    windowView.alpha = 1.0
                })
            })
        }
    }

    private func refreshInstagramContentCollection(request: URLRequestConvertible) {
        if populatingContent {
            return
        }
        
        populatingContent = true
        
        Alamofire.request(request).responseJSON() {
            [weak self](_ , _, jsonObject, error) in
            
            if (error == nil) {
                // println(jsonObject)
                
                let json = JSON(jsonObject!)
                self!.instagramRemoteContentCollection = []
                
                if (json["meta"]["code"].intValue  == 200) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                        let jsonArrayValue = json["data"].arrayValue
                        for jsonArrayItem in jsonArrayValue {
                            if(jsonArrayItem["type"].stringValue == "image") {
                                // println("\n\nAdding image URL:\n")
                                // println(jsonArrayItem["images"]["standard_resolution"]["url"].URL!)
                                let imageUrl = jsonArrayItem["images"]["standard_resolution"]["url"].URL!
                                self!.instagramRemoteContentCollection.append(imageUrl)
                            } else if (jsonArrayItem["type"].stringValue == "video") {
                                // println("\n\nAddingvideo URL:")
                                // println(jsonArrayItem["videos"]["standard_resolution"]["url"].URL!)
                                let videoUrl = jsonArrayItem["videos"]["standard_resolution"]["url"].URL!
                                self!.instagramRemoteContentCollection.append(videoUrl)
                            }
                        }
                    }
                }
            }
            
            println(self!.instagramRemoteContentCollection)
            
            self!.populatingContent = false
        }
    }

    private func getRandomFile() -> AnyObject {
        var instagramCollectionWithoutFilesInUse: Array<AnyObject> = []

        if(!populatingContent && instagramRemoteContentCollection.count > 0) {
            println("getting random file from remote content")
            instagramCollectionWithoutFilesInUse = instagramRemoteContentCollection.filter({
                $0.absoluteString != self.windowOneView.contentFile
                    || $0.absoluteString != self.windowTwoView.contentFile
                    || $0.absoluteString != self.windowThreeView.contentFile
            })
        } else {
            println("getting random file from remote content")
            instagramCollectionWithoutFilesInUse = instagramLocalContentCollection.filter({
                $0 != self.windowOneView.contentFile
                    || $0 != self.windowTwoView.contentFile
                    || $0 != self.windowThreeView.contentFile
            })
        }

        let randomIndex = Int(arc4random_uniform(UInt32(instagramCollectionWithoutFilesInUse.count)))

        return instagramCollectionWithoutFilesInUse[randomIndex]
    }
}

