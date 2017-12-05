//
//  XADVASTViewController.swift
//  XADVAST
//
// XADVASTViewController is the main component of the PublisherSDK VAST Implementation.
//
// This class creates and manages an iOS MPMediaPlayerViewController to playback a video from a VAST 2.0 document.
// The document may be loaded using a URL or directly from an exisitng XML document (as Data).
//
// See the XADVASTViewControllerDelegate Protocol for the required vastReady: and other useful methods.
// Screen controls are exposed for play, pause, info, and dismiss, which are handled by the XADVASTControlView class as an overlay toolbar.
//
// VASTEventProcessor handles tracking events and impressions.
// Errors encountered are listed in in VASTError.h
//
// Please note:  Only one video may be played at a time, you must wait for the vastReady: callback before sending the 'play' message.

//  Created by Phillip Corrigan on 8/5/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import MediaPlayer
import UIKit
import SystemConfiguration

let kPlaybackFinishedUserInfoErrorKey = "error"

protocol XADVASTViewControllerDelegate: class{
    func vastReady(vastVC: XADVASTViewController)
    func vastError(vastVC: XADVASTViewController, error: XADVASTError)
    func vastWillPresentFullScreen(vastVC: XADVASTViewController)
    func vastVideoStartPlaying(vastVC: XADVASTViewController)
    func vastDidDismissFullScreen(vastVC: XADVASTViewController)
    func vastOpenBrowseWithUrl(vastVC: XADVASTViewController, url: URL)
    func vastTrackingEvent(eventName: String)
}

enum CurrentVASTQuartile:Int {
    case first
    case second
    case third
    case four
}

open class XADVASTViewController: UIViewController, UIGestureRecognizerDelegate {
    
    fileprivate var mediaFileURL: URL?
    fileprivate var clickTracking: [XADVASTUrlWithId]?
    fileprivate var vastErrors:[XADVASTUrlWithId]? //change
    fileprivate var impressions:[XADVASTUrlWithId]?
    
    fileprivate var playbackTimer: Timer?
    fileprivate var initialDelayTimer: Timer?
    fileprivate var videoLoadTimeoutTimer: Timer?
    fileprivate var movieDuration: TimeInterval = 0.0
    fileprivate var playedSeconds: TimeInterval = 0.0
    
//    fileprivate var controlView: XADVASTControlView?
    
    fileprivate var currentPlayedPercentage: CGFloat = 0.0
    fileprivate var isViewOnScreen:Bool = false
    fileprivate var hasPlayerStarted:Bool = false
    fileprivate var isLoadCalled:Bool = false
    
    
    fileprivate var statusBarHidden:Bool = false
    
    fileprivate var currentQuartile:CurrentVASTQuartile = .first
    fileprivate var loadingIndicator: UIActivityIndicatorView?
    fileprivate var curViewController: UIViewController!
    
    fileprivate var reachabilityForVAST: Reachability!
    fileprivate var networkReachableBlock: Reachability.NetworkReachable?
    fileprivate var networkUnreachableBlock: Reachability.NetworkUnreachable?
    
    fileprivate var moviePlayer: MPMoviePlayerController?
    fileprivate var touchGestureRecognizer: UITapGestureRecognizer!
    fileprivate var eventProcessor: XADVASTEventProcessor?
    fileprivate var videoHangTest: [Int]?
    fileprivate var networkCurrentlyReachable:Bool = false
    fileprivate var isCloseButtonAdded: Bool = false
    fileprivate var isVideoCompleted: Bool = false
    
    fileprivate var xmlForReport: String!
    fileprivate var adGroupId: String!
    
    var isPlaying:Bool = false
    var vastReady:Bool = false
    var clickThrough: URL?
    
    weak var testDelegate: XADDisplayTestDelegate?
    weak var delegate: XADVASTViewControllerDelegate?
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // designated initializer for VASTViewController
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    convenience init(delegate: XADVASTViewControllerDelegate, withViewController viewController: UIViewController){
        self.init()
        self.delegate = delegate
        curViewController = viewController
        currentQuartile = CurrentVASTQuartile.first
        self.videoHangTest = [Int]() /* capacity: 20 */
        self.setupReachability()
    }
    
    fileprivate func addMediaPlayerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.trySetMovieDuration), name: .MPMovieDurationAvailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.moviePlayBackDidFinish), name: .MPMoviePlayerPlaybackDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playbackStateChangeNotification), name: .MPMoviePlayerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.moviePlayerLoadStateChanged), name: .MPMoviePlayerLoadStateDidChange, object: nil)
        
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.old, .new], context: nil)
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let change = change {
            let oldOutputVolume = change[.oldKey] as! Float
            let newOutputVolume = change[.newKey] as! Float
            if newOutputVolume == 0.0 && oldOutputVolume == 0.0625 {
                self.eventProcessor?.trackEvent(.mute)
            } else if newOutputVolume == 0.0625 && oldOutputVolume == 0.0 {
                self.eventProcessor?.trackEvent(.unmute)
            }
            
        }
    }
    
    //MARK: - Load methods
    //load and prepare to play a VAST video from a URL
    //No usage currently
    open func loadVideoWithURL(url: NSURL) {
        do {
            self.xmlForReport = try String(contentsOf: url as URL)
            self.adGroupId = "0"
            self.loadVideoUsingSource(source: url)
        } catch {
            sendError(errorCode: .contentError, payload: url.absoluteString!)
        }
    }
    
    // load and prepare to play a VAST video from existing XML data
    open func loadVideoWithData(xmlContent: Data, adGroupId: String) {
        self.xmlForReport = String(data: xmlContent, encoding: .utf8)
        self.adGroupId = adGroupId
        self.loadVideoUsingSource(source: xmlContent as AnyObject)
    }
    
    func loadVideoUsingSource(source: AnyObject) {
        if source is NSURL {
            XADLogger.debug(message: "Starting loadVideoWithURL")
        }
        else {
            XADLogger.debug(message: "Starting loadVideoWithData")
        }
        
        if isLoadCalled {
            XADLogger.debug(message: "Ignoring loadVideo because a load is in progress.")
            return
        }
        isLoadCalled = true
        
        let parserCompletionBlock = {[weak self](vastModel: XADVASTModel?, vastError: XADVASTError) -> Void in
            guard let _self = self else {
                return
            }
            
            XADLogger.debug(message: "back from block in loadVideoFromData")
            
            guard let vastModel = vastModel else{
                XADLogger.error(message: "parser error")
                    // The VAST document was not readable, so no Error urls exist, thus none are sent.
                sendError(errorCode: .contentCannotLoadError, payload: _self.xmlForReport, adGroupId: _self.adGroupId)
                _self.delegate?.vastError(vastVC: _self, error: vastError)
                return
            }
            _self.eventProcessor = XADVASTEventProcessor(trackingEvents: vastModel.trackingEvents(), withDelegate: _self.delegate, withTestDelegate: _self.testDelegate)
            _self.impressions = vastModel.impressions()
            _self.vastErrors = vastModel.errors()
            if let clickThroughFromModel = vastModel.clickThrough() {
                _self.clickThrough = clickThroughFromModel.url
            }
            _self.clickTracking = vastModel.clickTracking()
            _self.mediaFileURL = XADVASTMediaFilePicker.pick(vastModel.mediaFiles())?.url as URL?
            
            guard _self.mediaFileURL != nil else {
                XADLogger.error(message: "Error - VASTMediaFilePicker did not find a compatible mediaFile - VASTViewcontroller will not be presented")
                _self.sendErrorEvent(errorsUrls: _self.vastErrors)
                sendError(errorCode: .contentNoMediaFileError, payload: _self.xmlForReport, adGroupId: _self.adGroupId)
                _self.delegate?.vastError(vastVC: _self, error: .noCompatibleMediaFile)
                return
            }
            // VAST document parsing OK, player ready to attempt play, so send vastReady
            XADLogger.debug(message: "Sending vastReady: callback")
            _self.vastReady = true
            _self.delegate?.vastReady(vastVC: _self)
        }
        
        let parser = XADVAST2Parser()
        if source is NSURL {
            if !networkCurrentlyReachable {
                XADLogger.error(message: "No network available - VASTViewcontroller will not be presented")
                self.delegate?.vastError(vastVC: self, error:  .noInternetConnection)
                return
            }
            // Load the and parse the VAST document at the supplied URL  () -> Void
            parser.parseWithUrl((source as! NSURL) as URL, completion: parserCompletionBlock)
            
        } else if source is Data{
            parser.parseWithData(source as! Data, completion: parserCompletionBlock)
        }
    }
    //MARK: -
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewOnScreen = true
        if let moviePlayer = self.moviePlayer {
            moviePlayer.view.frame = self.view.bounds
            assert(moviePlayer.view.frame.width > moviePlayer.view.frame.height, "Video orientation wrong")
            self.view.addSubview(moviePlayer.view)
        }
        if !hasPlayerStarted {
            loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            loadingIndicator!.frame = CGRect(x: (self.view.frame.size.width / 2) - 25.0, y: (self.view.frame.size.height / 2) - 25.0, width: 50, height: 50)
            loadingIndicator!.startAnimating()
            self.view.addSubview(loadingIndicator!)
            self.eventProcessor?.trackEvent(.creativeView)
        } else {
            // resuming from background or phone call, so resume if was playing, stay paused if manually paused
            self.handleResumeState()
        }
    }
    
    override open var prefersStatusBarHidden : Bool {
        get {
            return true
        }
    }
    
    // MARK: - MPMoviePlayerController notifications
    func playbackStateChangeNotification(notification: NSNotification) {
        let lockQueue = DispatchQueue(label: "com.xad.LockQueue")
        lockQueue.sync{
            guard let moviePlayer = self.moviePlayer else {
                XADLogger.debug(message: "No movie player available")
                return
            }
            let state = moviePlayer.playbackState
            XADLogger.debug(message: "playback state change to \(state))")
            switch state {
            case .stopped:
                XADLogger.debug(message: "video stopped")
            case .playing:
                isPlaying = true
                if let loadingIndicator = self.loadingIndicator {
                    self.stopVideoLoadTimeoutTimer()
                    loadingIndicator.stopAnimating()
                    loadingIndicator.removeFromSuperview()
                    self.loadingIndicator = nil
                }
                if isViewOnScreen {
                    XADLogger.debug(message: "video is playing")
                    self.startPlaybackTimer()
                }
            case .paused:
                self.stopPlaybackTimer()
                XADLogger.debug(message: "video paused")
                isPlaying = false
                if !self.isCloseButtonAdded {
                    self.addCloseButton(toSuperView: self.view)
                }
            case .interrupted:
                XADLogger.debug(message: "video is bufferring")
                if !self.isCloseButtonAdded {
                    self.addCloseButton(toSuperView: self.view)
                }
            case .seekingForward:
                XADLogger.debug(message: "video seeking forward")
            case .seekingBackward:
                XADLogger.debug(message: "video seeking backward")
            }
            
        }
    }
    
    func moviePlayerLoadStateChanged(notification: NSNotification) {
        guard let moviePlayer = self.moviePlayer else {
            return
        }
        XADLogger.debug(message: "movie player load state is \(moviePlayer.loadState)")
        if moviePlayer.loadState == .playable {
            self.doPlayVideo()
            self.stopVideoLoadTimeoutTimer()
        } else if moviePlayer.loadState == .stalled {
            XADLogger.debug(message: "Video is stalled")
        }
    }
    
    func moviePlayBackDidFinish(notification: NSNotification) {
        let lockQueue = DispatchQueue(label: "com.xad.LockQueue")
        lockQueue.sync{
            XADLogger.debug(message: "playback did finish")
            if let userInfo = notification.userInfo,
                let error = userInfo[kPlaybackFinishedUserInfoErrorKey] {
                self.stopVideoLoadTimeoutTimer()
                // don't time out if there was a playback error
                XADLogger.error(message: "playback error:  \(error)")
                self.delegate?.vastError(vastVC: self, error: .playbackError)
                self.sendErrorEvent(errorsUrls: self.vastErrors)
                sendError(errorCode: .contentVideoPlayBackError, payload: self.xmlForReport, adGroupId: self.adGroupId)
            }
            else {
                // no error, clean finish, so send track complete
                self.isVideoCompleted = true
                self.eventProcessor?.trackEvent(.complete)
                self.updatePlayedSeconds()
                if !self.isCloseButtonAdded {
                    self.addCloseButton(toSuperView: self.view)
                    self.isCloseButtonAdded = true
                }
            }
        }
    }
    
    func trySetMovieDuration(notification: NSNotification) {
        guard let moviePlayer = self.moviePlayer else {
            return
        }
        movieDuration = moviePlayer.duration
        // The movie too short error will fire if movieDuration is < 0.5 or is a NaN value, so no need for further action here.
        XADLogger.debug(message: "playback duration is \(movieDuration)")
        if movieDuration < 0.5 || movieDuration.isNaN {
            // movie too short - ignore it
            self.stopVideoLoadTimeoutTimer()
            // don't time out in this case
            XADLogger.warning(message: "Movie too short - will dismiss player")
            self.delegate?.vastError(vastVC: self, error: .movieTooShort)
            self.sendErrorEvent(errorsUrls: self.vastErrors)
            sendError(errorCode: .contentVideoDurationError, payload: self.xmlForReport, adGroupId: self.adGroupId)
            self.close()
        }
    }
    
    // MARK: - Orientation handling
    // force to always play in Landscape
    override open var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get {
            return .landscape
        }
    }
    
    override open var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        get {
            let currentInterfaceOrientation = UIApplication.shared.statusBarOrientation
            return UIInterfaceOrientationIsLandscape(currentInterfaceOrientation) ? currentInterfaceOrientation : .landscapeRight
        }
    }
    
    // MARK: - Timers
    // playbackTimer - keeps track of currentPlayedPercentage
    func startPlaybackTimer() {
        let lockQueue = DispatchQueue(label: "com.xad.LockQueue")
        lockQueue.sync{
            self.stopPlaybackTimer()
            XADLogger.debug(message: "start playback timer")
            playbackTimer = Timer.scheduledTimer(timeInterval: XADVASTSettings.kPlayTimeCounterInterval, target: self, selector: #selector(self.updatePlayedSeconds), userInfo: nil, repeats: true)
        }
    }
    
    func stopPlaybackTimer() {
        XADLogger.debug(message: "stop playback timer")
        self.playbackTimer?.invalidate()
        self.playbackTimer = nil
    }
    
    func updatePlayedSeconds() {
        guard let moviePlayer = self.moviePlayer else {
            return
        }
        
        playedSeconds = moviePlayer.currentPlaybackTime
        // The hang test below will fire if playedSeconds doesn't update (including a NaN value), so no need for further action here.
        if var videoHangTest = self.videoHangTest,
            !playedSeconds.isNaN {
            videoHangTest.append((Int(playedSeconds * 10.0)))
            // add new number to end of hang test buffer
            if videoHangTest.count > 20 {
                // only check for hang if we have at least 20 elements or about 5 seconds of played video, to prevent false positives
                if videoHangTest.first == videoHangTest.last {
                    XADLogger.error(message: "Video error - video player hung at playedSeconds: \(playedSeconds)")
                    self.delegate?.vastError(vastVC: self, error: .playerHung)
                    self.sendErrorEvent(errorsUrls: self.vastErrors)
                    self.close()
                }
                // remove oldest number from start of hang test buffer
                videoHangTest.remove(at: 0)
                
            }
        }
        
        if playedSeconds >= 5 {
            if !self.isCloseButtonAdded {
                self.addCloseButton(toSuperView: self.view)
                self.isCloseButtonAdded = true
            }
        }
        
        currentPlayedPercentage = CGFloat(100.0 * (playedSeconds / movieDuration))
        switch currentQuartile {
        case .first:
            if currentPlayedPercentage > 25.0 {
                self.eventProcessor?.trackEvent(.firstQuartile)
                currentQuartile = .second
            }
        case .second:
            if currentPlayedPercentage > 50.0 {
                self.eventProcessor?.trackEvent(.midpoint)
                currentQuartile = .third
            }
        case .third:
            if currentPlayedPercentage > 75.0 {
                self.eventProcessor?.trackEvent(.thirdQuartile)
                currentQuartile = .four
            }
        default:
            break
        }
        
    }
    // Reports error if vast video document times out while loading
    
    func startVideoLoadTimeoutTimer() {
        XADLogger.error(message: "Start Video Load Timer")
        videoLoadTimeoutTimer = Timer.scheduledTimer(timeInterval: XADVASTSettings.vastVideoLoadTimeout, target: self, selector: #selector(self.videoLoadTimerFired), userInfo: nil, repeats: false)
    }
    
    func stopVideoLoadTimeoutTimer() {
        if self.videoLoadTimeoutTimer != nil {
            self.videoLoadTimeoutTimer!.invalidate()
            self.videoLoadTimeoutTimer = nil
            XADLogger.debug(message: "Stop Video Load Timer")
        }
    }
    
    func videoLoadTimerFired() {
        XADLogger.error(message: "Video Load Timeout")
        self.close()
        self.sendErrorEvent(errorsUrls: self.vastErrors)
        self.delegate?.vastError(vastVC: self, error: .loadTimeout)
    }
    func killTimers() {
        self.stopPlaybackTimer()
        self.stopVideoLoadTimeoutTimer()
    }
    
    func play() {
        let lockQueue = DispatchQueue(label: "com.xad.LockQueue")
        lockQueue.sync{
            XADLogger.debug(message: "playVideo")
            if !vastReady {
                delegate?.vastError(vastVC: self, error:.playerNotReady)
                // This is not a VAST player error, so no external Error event is sent.
                XADLogger.error(message: "Ignoring call to playVideo before the player has sent vastReady.")
                return
            }
            if isViewOnScreen {
                // This is not a VAST player error, so no external Error event is sent.
                delegate?.vastError(vastVC: self, error: .playerNotReady)
                XADLogger.error(message: "Ignoring call to playVideo while playback is already in progress")
                return
            }
            if !self.networkCurrentlyReachable {
                XADLogger.error(message: "No network available - VASTViewcontroller will not be presented")
                delegate?.vastError(vastVC: self, error: .playerNotReady)
                return
            }
            // Now we are ready to launch the player and start buffering the content
            // It will throw error if the url is invalid for any reason. In this case, we don't even need to open ViewController.
            XADLogger.debug(message: "initializing player")
            if let mediaFileURL = self.mediaFileURL {
                self.addMediaPlayerObservers()
                XADLogger.debug(message: "Media file url: \(mediaFileURL.absoluteString)")
                self.playedSeconds = 0.0
                self.currentPlayedPercentage = 0.0
                self.startVideoLoadTimeoutTimer()
                self.moviePlayer = MPMoviePlayerController(contentURL: mediaFileURL)
                self.moviePlayer!.controlStyle = .none
                self.moviePlayer!.prepareToPlay()
                self.presentPlayer()
            } else {
                delegate?.vastError(vastVC: self, error: .noCompatibleMediaFile)
                self.sendErrorEvent(errorsUrls: self.vastErrors)
                sendError(errorCode: .contentNoMediaFileError, payload: self.xmlForReport, adGroupId: self.adGroupId)
            }
        }
    }

    // pause the video, useful when modally presenting a browser, for example
    func pause() {
        XADLogger.debug(message: "pause")
        self.handlePauseState()
    }
    // resume the video, useful when modally dismissing a browser, for example
    func resume() {
        XADLogger.debug(message: "resume")
        self.handleResumeState()
    }
    func close() {
        let lockQueue = DispatchQueue(label: "com.xad.LockQueue")
        lockQueue.sync{
            self.removeObservers()
            self.killTimers()
            if let moviePlayer = self.moviePlayer {
                moviePlayer.stop()
            }
            self.moviePlayer = nil
            if isViewOnScreen {
                // send close any time the player has been dismissed
                self.eventProcessor?.trackEvent(.close)
                XADLogger.debug(message: "Dismissing VASTViewController")
                self.dismiss(animated: false, completion: { _ in })
                self.delegate?.vastDidDismissFullScreen(vastVC: self)
            }
        }
    }
    
    deinit {
        XADLogger.debug(message: "deinit")
        reachabilityForVAST.stopNotifier()
        self.removeObservers()
        XADLogger.debug(message: "VideoAd is deinit")
    }

    // Handle touches
    //
    // MARK: - Gesture setup & delegate
    func setUpTapGestureRecognizer() {
        self.touchGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTouches))
        self.touchGestureRecognizer.delegate = self
        self.touchGestureRecognizer.numberOfTouchesRequired = 1
        self.touchGestureRecognizer.cancelsTouchesInView = false
        if let moviePlayer = self.moviePlayer {
            moviePlayer.view.addGestureRecognizer(self.touchGestureRecognizer)
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func handleTouches() {
        if let clickTracking = self.clickTracking , clickTracking.count > 0 {
            XADLogger.debug(message: "Sending clickTracking requests")
            self.eventProcessor?.sendVASTUrlsWithId(clickTracking)
        }
        if let clickThrough = self.clickThrough{
            XADLogger.debug(message: "open click through")
            self.handlePauseState()
            self.delegate?.vastOpenBrowseWithUrl(vastVC: self, url: clickThrough)
        }
    }
    
    // MARK: - Reachability
    func setupReachability() {
        do {
            reachabilityForVAST = Reachability()
            reachabilityForVAST.reachableOnWWAN = true
            // Do allow 3G/WWAN for reachablity
            let self_ = self
            // avoid block retain cycle change
            networkReachableBlock = {(Reachability) -> Void in
                XADLogger.debug(message: "Network reachable")
                self_.networkCurrentlyReachable = true
            }
            networkUnreachableBlock = {(Reachability) -> Void in
                XADLogger.debug(message: "Network not reachable")
                self_.networkCurrentlyReachable = false
            }
            reachabilityForVAST.whenReachable = networkReachableBlock
            reachabilityForVAST.whenUnreachable = networkUnreachableBlock
            try reachabilityForVAST.startNotifier()
            self.networkCurrentlyReachable = reachabilityForVAST.isReachable
            XADLogger.debug(message: "Network is reachable \(self.networkCurrentlyReachable)")
        } catch ReachabilityError.UnableToSetCallback{
            XADLogger.error(message: "Error - UnableToSetCallback")
        } catch ReachabilityError.UnableToSetDispatchQueue{
            XADLogger.error(message: "Error - UnableToSetDispatchQueue")
        } catch {
            XADLogger.error(message: "Error - Others")
        }
    }
    // MARK: - Other methods
    fileprivate func addCloseButton(toSuperView superView: UIView) {
        //create close region
        let closeEventRegion = UIButton(type: .custom)
        closeEventRegion.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        //Add close button image
        if let frameworkBundle = Bundle(identifier: "com.xad.XADDisplaySdk"),
            let closeButtonImage = UIImage(named: "CloseButton.png", in: frameworkBundle, compatibleWith: nil) {
            let closeButtonImageView = UIImageView(image:closeButtonImage , highlightedImage: closeButtonImage)
            closeEventRegion.add(subView: closeButtonImageView, withSize: (Constants.kCloseButtonSize, Constants.kCloseButtonSize), toPosition: [(.centerX, 0.0), (.centerY, 0.0)])
        } else {
            XADLogger.error(message: "Error when access CloseButton.png")
            sendError(errorCode: .internalError, payload: "Can't find close button image")
        }
        
        //Add close region onto contain view
        superView.add(subView: closeEventRegion, withSize: (Constants.kCloseEventRegionSize, Constants.kCloseEventRegionSize), toPosition: [(.top, Constants.kCloseEventRegionMargin), (.right, Constants.kCloseEventRegionMargin)])
    }
    
    func removeObservers() {
        //Only add observer after movieplayer is initialized, so only need remove observer if has movieplayer
        if self.moviePlayer != nil {
            NotificationCenter.default.removeObserver(self)
            AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        }
    }
    
    func handlePauseState() {
        let lockQueue = DispatchQueue(label: "com.xad.LockQueue")
        lockQueue.sync{
            guard !self.isVideoCompleted else {
                XADLogger.debug(message: "Video is completed, close it")
                return
            }
            
            if self.isPlaying {
                XADLogger.debug(message: "handle pausing player")
                if let moviePlayer = self.moviePlayer {
                    moviePlayer.pause()
                }
                self.isPlaying = false
                self.eventProcessor?.trackEvent(.pause)
            }
            self.stopPlaybackTimer()
            self.stopVideoLoadTimeoutTimer()
        }
    }
    
    func handleResumeState() {
        let lockQueue = DispatchQueue(label: "com.xad.LockQueue")
        lockQueue.sync{
            guard !self.isVideoCompleted else {
                XADLogger.debug(message: "Video is completed, close it")
                return
            }
            if !self.isPlaying {
                self.eventProcessor?.trackEvent(XADVASTEvent.resume)
                XADLogger.debug(message: "resuming video player")
                self.doPlayVideo()
            }
            
            if !self.hasPlayerStarted {
                self.startVideoLoadTimeoutTimer()
            }
        }
    }
    
    func doPlayVideo() {
        guard let moviePlayer = self.moviePlayer else {
            return
        }
        
        if !self.hasPlayerStarted {
            self.delegate?.vastVideoStartPlaying(vastVC: self)
            if let impressions = self.impressions , impressions.count > 0 {
                XADLogger.debug(message: "Sending Impressions requests")
                self.eventProcessor?.sendVASTUrlsWithId(impressions)
            }
            self.eventProcessor?.trackEvent(.start)
            self.setUpTapGestureRecognizer()
            self.hasPlayerStarted = true
        }
        moviePlayer.play()
        self.isPlaying = true
        self.startPlaybackTimer()
    }
    
    func sendErrorEvent(errorsUrls: [XADVASTUrlWithId]?) {
        if let errorsUrls = errorsUrls,
            errorsUrls.count > 0 {
            XADLogger.debug(message: "Sending Error requests")
            self.eventProcessor?.sendVASTUrlsWithId(errorsUrls)
        }
    }
    
    func presentPlayer() {
        self.delegate?.vastWillPresentFullScreen(vastVC: self)
        curViewController.present(self, animated: false) {
            self.eventProcessor?.trackEvent(XADVASTEvent.fullscreen)
        }
    }
}
