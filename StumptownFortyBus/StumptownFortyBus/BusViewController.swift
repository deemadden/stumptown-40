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
import AVKit
import AVFoundation
import CoreData
import Alamofire
import FastImageCache
import SwiftyJSON

class BusViewController: UIViewController {

    @IBOutlet weak var windowOneView: UIView!
    @IBOutlet weak var windowTwoView: UIView!
    @IBOutlet weak var windowThreeView: UIView!
    @IBOutlet weak var windowOneImageView: UIImageView!
    @IBOutlet weak var windowOneVideoContainerView: UIView!
    @IBOutlet weak var windowTwoImageView: UIImageView!
    @IBOutlet weak var windowTwoVideoContainerView: UIView!
    @IBOutlet weak var windowThreeImageView: UIImageView!
    @IBOutlet weak var windowThreeVideoContainerView: UIView!
    @IBOutlet weak var bannerView: UIView!

    // MARK: Async & CoreData properties
    var coreDataStack: CoreDataStack!
    var populatingContent = false
    var shouldLogin = false
    var user: User? {
        didSet {
            if user != nil {
                handleRefresh()
            } else {
                shouldLogin = true
            }
        }
    }
    
    // MARK: Movie players
    private var bannerVideoPlayer: MPMoviePlayerController!
    private var windowOneAVPlayerController: AVPlayerViewController!
    private var windowTwoAVPlayerController: AVPlayerViewController!
    private var windowThreeAVPlayerController: AVPlayerViewController!
    private var bannerVideoPlayerController: AVPlayerViewController!
    
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

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft) {
            println("landscape left")
            self.view.transform = CGAffineTransformMakeScale(1, 1);
        } else if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight) {
            println("landscape right")
             self.view.transform = CGAffineTransformMakeScale(-1, 1);
        }
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
        } else if segue.identifier == "windowOnePlayerSegue" && segue.destinationViewController.isKindOfClass(AVPlayerViewController.classForCoder()) {
            if let aVPlayerController = segue.destinationViewController as? AVPlayerViewController {
                self.windowOneAVPlayerController = aVPlayerController
                let url = NSURL(string: "https://scontent.cdninstagram.com/hphotos-xaf1/t50.2886-16/11237394_840898795979885_104026202_n.mp4")
                self.windowOneAVPlayerController.player = AVPlayer(URL: url)
                self.windowOneAVPlayerController.player.actionAtItemEnd = .None
                
                //set a listener for when the video ends
                NSNotificationCenter.defaultCenter().addObserver(self,
                    selector: "loopWindowOne",
                    name: AVPlayerItemDidPlayToEndTimeNotification,
                    object: self.windowOneAVPlayerController.player.currentItem)
                
                self.windowOneAVPlayerController.player.play()
            }
        } else if segue.identifier == "windowTwoPlayerSegue" && segue.destinationViewController.isKindOfClass(AVPlayerViewController.classForCoder()) {
            if let aVPlayerController = segue.destinationViewController as? AVPlayerViewController {
                self.windowTwoAVPlayerController = aVPlayerController
                let url = NSURL(string: "https://scontent.cdninstagram.com/hphotos-xaf1/t50.2886-16/11214739_1116462238380638_1015834890_n.mp4")
                self.windowTwoAVPlayerController.player = AVPlayer(URL: url)
                self.windowTwoAVPlayerController.player.actionAtItemEnd = .None
                
                //set a listener for when the video ends
                NSNotificationCenter.defaultCenter().addObserver(self,
                    selector: "loopWindowTwo",
                    name: AVPlayerItemDidPlayToEndTimeNotification,
                    object: self.windowTwoAVPlayerController.player.currentItem)
                
                self.windowTwoAVPlayerController.player.play()
            }
        } else if segue.identifier == "windowThreePlayerSegue" && segue.destinationViewController.isKindOfClass(AVPlayerViewController.classForCoder()) {
            if let aVPlayerController = segue.destinationViewController as? AVPlayerViewController {
                self.windowThreeAVPlayerController = aVPlayerController
                let url = NSURL(string: "https://scontent.cdninstagram.com/hphotos-xaf1/t50.2886-16/11250762_458654014292737_866203572_n.mp4")
                self.windowThreeAVPlayerController.player = AVPlayer(URL: url)
                self.windowThreeAVPlayerController.player.actionAtItemEnd = .None
                
                //set a listener for when the video ends
                NSNotificationCenter.defaultCenter().addObserver(self,
                    selector: "loopWindowThree",
                    name: AVPlayerItemDidPlayToEndTimeNotification,
                    object: self.windowThreeAVPlayerController.player.currentItem)
                
                self.windowThreeAVPlayerController.player.play()
            }
        }
    }
    
    @IBAction func unwindToBusView (segue : UIStoryboardSegue) { }
    
    private func handleRefresh() {
        refreshView()
        refreshContent()
        
        var timer1 = NSTimer.scheduledTimerWithTimeInterval(15.0, target: self, selector: Selector("refreshWindowOne"), userInfo: nil, repeats: true)
        var timer2 = NSTimer.scheduledTimerWithTimeInterval(17.0, target: self, selector: Selector("refreshWindowTwo"), userInfo: nil, repeats: true)
        var timer3 = NSTimer.scheduledTimerWithTimeInterval(19.0, target: self, selector: Selector("refreshWindowThree"), userInfo: nil, repeats: true)
        var timer4 = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: Selector("refreshContent"), userInfo: nil, repeats: true)
    }

    internal func refreshView() {
        windowOneView.contentFile = ""
        windowTwoView.contentFile = ""
        windowThreeView.contentFile = ""
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
                windowPlayerContainer: windowOneVideoContainerView,
                windowPlayerController: windowOneAVPlayerController)
    }

    internal func refreshWindowTwo() {
        refreshWindow(windowTwoView,
                windowImageView: windowTwoImageView,
                windowPlayerContainer: windowTwoVideoContainerView,
                windowPlayerController: windowTwoAVPlayerController)
    }

    internal func refreshWindowThree() {
        refreshWindow(windowThreeView,
                windowImageView: windowThreeImageView,
                windowPlayerContainer: windowThreeVideoContainerView,
                windowPlayerController: windowThreeAVPlayerController)
    }

    private func refreshWindow(windowView: UIView,
                                windowImageView: UIImageView,
                                windowPlayerContainer: UIView,
                                windowPlayerController: AVPlayerViewController) {
        
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
                if (windowPlayerController.player.rate > 0 && windowPlayerController.player.error == nil) {
                    windowPlayerController.player.pause()
                    windowPlayerContainer.hidden = true
                }

                var contentImage: UIImage?
                
                if(windowView.contentFile!.beginsWith("https")) {
                    let url = NSURL(string: windowView.contentFile!)
                    
                    if let data = NSData(contentsOfURL: url!) {
                        println("Assigning remote Instagram image")
                        contentImage = UIImage(data: data)
                    }
                } else {
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
                windowPlayerContainer.hidden = true
                
                if (windowPlayerController.player.rate > 0 && windowPlayerController.player.error == nil) {
                    windowPlayerController.player.pause()
                }

                var url:NSURL?
                
                if(windowView.contentFile!.beginsWith("https")) {
                    // It's remote
                    println("Assigning remote Instagram video")
                    let url = NSURL(string: windowView.contentFile!)
                    windowPlayerController.player.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: url))
                    windowPlayerController.player.actionAtItemEnd = .None
                } else {
                    // It's a local
                    println("Loading local video")
                    if let path = NSBundle.mainBundle().pathForResource(windowView.contentFile!.stringByDeletingPathExtension, ofType:"mp4") {
                        let url = NSURL.fileURLWithPath(path)
                        windowPlayerController.player.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: url))
                        windowPlayerController.player.actionAtItemEnd = .None
                    } else {
                        return
                    }
                }
                
                let seconds : Int64 = 1
                let preferredTimeScale : Int32 = 1
                let seekTime : CMTime = CMTimeMake(seconds, preferredTimeScale)
                windowPlayerController.player.seekToTime(seekTime)
                windowPlayerContainer.hidden = false

                UIView.animateWithDuration(2.0, animations: {
                    windowView.alpha = 1.0
                    }, completion: { finished in
                        windowPlayerController.player.play()
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
                                let imageUrl = jsonArrayItem["images"]["standard_resolution"]["url"].URL!
                                self!.instagramRemoteContentCollection.append(imageUrl)
                            } else if (jsonArrayItem["type"].stringValue == "video") {
                                let videoUrl = jsonArrayItem["videos"]["standard_resolution"]["url"].URL!
                                self!.instagramRemoteContentCollection.append(videoUrl)
                            }
                        }
                        
                        println(self!.instagramRemoteContentCollection)
                    }
                }
            }
            
            self!.populatingContent = false
        }
    }

    private func getRandomFile() -> AnyObject {
        var instagramCollectionWithoutFilesInUse: Array<AnyObject> = []

        if(!populatingContent && instagramRemoteContentCollection.count > 0) {
            println("getting random file from remote content")
            println(instagramRemoteContentCollection.count)
            
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
    
    internal func loopWindowOne() {
        let seconds : Int64 = 0
        let preferredTimeScale : Int32 = 1
        let seekTime : CMTime = CMTimeMake(seconds, preferredTimeScale)
        windowOneAVPlayerController.player.seekToTime(seekTime)
        windowOneAVPlayerController.player.play()
    }
    
    internal func loopWindowTwo() {
        let seconds : Int64 = 0
        let preferredTimeScale : Int32 = 1
        let seekTime : CMTime = CMTimeMake(seconds, preferredTimeScale)
        windowTwoAVPlayerController.player.seekToTime(seekTime)
        windowTwoAVPlayerController.player.play()
    }
    
    internal func loopWindowThree() {
        let seconds : Int64 = 0
        let preferredTimeScale : Int32 = 1
        let seekTime : CMTime = CMTimeMake(seconds, preferredTimeScale)
        windowThreeAVPlayerController.player.seekToTime(seekTime)
        windowThreeAVPlayerController.player.play()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

