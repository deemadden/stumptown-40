//
//  BusViewController.swift
//  StumptownFortyBus
//
//  Created by Dee Madden on 5/9/15.
//  Copyright (c) 2015 RGA. All rights reserved.
//

import UIKit
import MediaPlayer

class BusViewController: UIViewController {

    @IBOutlet weak var windowOneView: UIView!
    @IBOutlet weak var windowTwoView: UIView!
    @IBOutlet weak var windowThreeView: UIView!
    @IBOutlet weak var windowOneImageView: UIImageView!
    @IBOutlet weak var windowTwoImageView: UIImageView!
    @IBOutlet weak var windowThreeImageView: UIImageView!
    @IBOutlet weak var bannerView: UIView!

    private var windowOneMoviePlayer: MPMoviePlayerController!
    private var windowTwoMoviePlayer: MPMoviePlayerController!
    private var windowThreeMoviePlayer: MPMoviePlayerController!
    private var bannerVideoPlayer: MPMoviePlayerController!

    private var instagramContentCollection = (NSFileManager.defaultManager()
                                                .contentsOfDirectoryAtPath(
                                                    NSBundle.mainBundle().bundlePath, error: nil
                                                ) as! [String])
                                                .filter({ $0.endsWith(".jpg") || $0.endsWith(".mp4") })
    
    private var moviePlayerHorizontalConstraint:Array<AnyObject> = []
    private var moviePlayerVerticalConstraint:Array<AnyObject> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        refreshInstagramContentCollection()
        initializeMoviePlayers()
        refreshView()

        var timer1 = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: Selector("refreshWindowOne"), userInfo: nil, repeats: true)
        var timer2 = NSTimer.scheduledTimerWithTimeInterval(7.0, target: self, selector: Selector("refreshWindowTwo"), userInfo: nil, repeats: true)
        var timer3 = NSTimer.scheduledTimerWithTimeInterval(9.0, target: self, selector: Selector("refreshWindowThree"), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        windowView.contentFile = getRandomFile()

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

                windowImageView.image = UIImage(named: windowView.contentFile!)
                windowImageView.hidden = false

                UIView.animateWithDuration(0.3, animations: {
                    windowView.alpha = 1.0
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

                let path = NSBundle.mainBundle().pathForResource(windowView.contentFile!.stringByDeletingPathExtension, ofType:"mp4")
                let url = NSURL.fileURLWithPath(path!)
                windowMoviePlayer.contentURL = url
                windowMoviePlayer.prepareToPlay()
                windowMoviePlayer.movieSourceType = MPMovieSourceType.File
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

    private func refreshInstagramContentCollection() {
    }

    private func getRandomFile() -> String {
        let instagramCollectionWithoutFilesInUse = instagramContentCollection.filter({
            $0 != self.windowOneView.contentFile
                    || $0 != self.windowTwoView.contentFile
                    || $0 != self.windowThreeView.contentFile
        })

        let randomIndex = Int(arc4random_uniform(UInt32(instagramContentCollection.count)))

        return instagramCollectionWithoutFilesInUse[randomIndex]
    }
}

