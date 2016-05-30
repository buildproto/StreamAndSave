//
//  ViewController.swift
//  StreamAndSave
//
//  Created by Sean M Kirkpatrick on 5/26/16.
//  Copyright © 2016 Proto Venture Technology, Inc. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class Utilities {
    // MARK: C Pointer helper funcs
    
    static func bridge<T: AnyObject>(obj: T) -> UnsafePointer<Void> {
        return UnsafePointer(Unmanaged.passUnretained(obj).toOpaque())
    }
    
    static func bridge<T: AnyObject>(ptr: UnsafePointer<Void>) -> T {
        return Unmanaged<T>.fromOpaque(COpaquePointer(ptr)).takeUnretainedValue()
    }
    
    static func bridge<T: AnyObject>(ptr: UnsafeMutablePointer<Void>) -> T {
        return Unmanaged<T>.fromOpaque(COpaquePointer(ptr)).takeUnretainedValue()
    }
}


private var AVPlayerItemStatusObserverContext = 0

class ViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    
    // Network data
    private var session: NSURLSession?
    
    // Audio playback
    private var audioFileStream: AudioFileStreamID?
    
    private let AudioFileStreamPropertyListenerProc: AudioFileStream_PropertyListenerProc = { inClientData, inAudioFileStreamID, inPropertyID, ioFlags in
        let viewController: ViewController = Utilities.bridge(inClientData)
        viewController.handlePropertyChangeForFileStream(inAudioFileStreamID, propertyId:inPropertyID, flags:ioFlags)
    }
    
    private let AudioFileStreamPacketsProc: AudioFileStream_PacketsProc = { inClientData, inNumberBytes, inNumberPackets, inInputData, inPacketDescriptions in
        let viewController: ViewController = Utilities.bridge(inClientData)
        viewController.handleAudioPackets(inInputData, numberOfBytes:inNumberBytes, numberOfPackets:inNumberPackets, packetDescriptions:inPacketDescriptions)
    }
    
    // AVFoundation approach
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        DLog("constructing ViewController...");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        DLog("Fire up mp3 request...");
        var mp3 = NSURL(string: "http://traffic.libsyn.com/atpfm/atp24.mp3")!
        
        /*
        let configuration : NSURLSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("podcastStreamer")
        self.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let request = NSURLRequest(URL: NSURL(string: "http://traffic.libsyn.com/atpfm/atp24.mp3")! )
        let task = self.session!.dataTaskWithRequest(request)
        //let task = self.session.downloadTaskWithRequest(request)
        task.resume()
        
        let error: OSStatus = AudioFileStreamOpen(UnsafeMutablePointer<Void>(Utilities.bridge(self)), self.AudioFileStreamPropertyListenerProc, <#T##AudioFileStream_PacketsProc##AudioFileStream_PacketsProc##(UnsafeMutablePointer<Void>, UInt32, UInt32, UnsafePointer<Void>, UnsafeMutablePointer<AudioStreamPacketDescription>) -> Void#>, <#T##AudioFileTypeID#>, <#T##UnsafeMutablePointer<AudioFileStreamID>#>)
        */
        
        let asset = AVURLAsset(URL: mp3, options: nil)
        let requestedKeys = ["playable"];
        asset.loadValuesAsynchronouslyForKeys(requestedKeys, completionHandler: {
            dispatch_async(dispatch_get_main_queue()) {
                for key in requestedKeys {
                    var error: NSError? = nil
                    let status : AVKeyValueStatus = asset.statusOfValueForKey(key, error: &error)
                    if status == AVKeyValueStatus.Failed {
                        DLog("\(key) key failed to load")
                        return
                    }
                    else if status == AVKeyValueStatus.Cancelled {
                        DLog("\(key) key loading cancelled, unwind...")
                        return
                    }
                }
                
                if !asset.playable {
                    DLog("Asset is not playable, bailing")
                    return
                }
                
                self.playerItem = AVPlayerItem(asset: asset)
                self.playerItem?.addObserver(self, forKeyPath: "status", options: [.Initial, .New], context: &AVPlayerItemStatusObserverContext)
                
                self.player = AVPlayer(playerItem: self.playerItem!)
            }
        })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &AVPlayerItemStatusObserverContext {
            let status = change![NSKeyValueChangeNewKey] as! Int
            switch status {
            case AVPlayerStatus.ReadyToPlay.rawValue:
                DLog("ReadyToPlay, starting playback")
                self.player?.play()
            default:
                DLog("ignored status: \(status)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: NSURLSessionDelegate
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        DLog("error: \(error)")
        /* The last message a session receives.  A session will only become
         * invalid because of a systemic error or when it has been
         * explicitly invalidated, in which case the error parameter will be nil.
         */
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        DLog("session: \(session), task: \(task), challenge: \(challenge)")
        /* If implemented, when a connection level authentication challenge
         * has occurred, this delegate will be given the opportunity to
         * provide authentication credentials to the underlying
         * connection. Some types of authentication will apply to more than
         * one request on a given connection to a server (SSL Server Trust
         * challenges).  If this delegate message is not implemented, the
         * behavior will be to use the default handling, which may involve user
         * interaction.
         */
        completionHandler(NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil)
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        DLog("session: \(session)")
        /* If an application has received an
         * -application:handleEventsForBackgroundURLSession:completionHandler:
         * message, the session delegate will receive this message to indicate
         * that all messages previously enqueued for this session have been
         * delivered.  At this time it is safe to invoke the previously stored
         * completion handler, or to begin any internal updates that will
         * result in invoking the completion handler.
         */
    }
    
    // MARK: NSURLSessionTaskDelegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        DLog("session: \(session), task: \(task), response: \(response), request: \(request)")
        /* An HTTP request is attempting to perform a redirection to a different
         * URL. You must invoke the completion routine to allow the
         * redirection, allow the redirection with a modified request, or
         * pass nil to the completionHandler to cause the body of the redirection
         * response to be delivered as the payload of this request. The default
         * is to follow redirections.
         *
         * For tasks in background sessions, redirections will always be followed and this method will not be called.
         */
        completionHandler(request)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        DLog("session: \(session), task: \(task), error: \(error)")
        /* Sent as the last message related to a specific task.  Error may be
         * nil, which implies that no error occurred and this task is complete.
         */
    }
    
    // MARK: NSURLSessionDataDelegate
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        DLog("session: \(session), dataTask: \(dataTask), response: \(response)")
        /* The task has received a response and no further messages will be
         * received until the completion block is called. The disposition
         * allows you to cancel a request or to turn a data task into a
         * download task. This delegate message is optional - if you do not
         * implement it, you can get the response as a property of the task.
         *
         * This method will not be called for background upload tasks (which cannot be converted to download tasks).
         */
        completionHandler(NSURLSessionResponseDisposition.Allow);
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
        DLog("session: \(session), dataTask: \(dataTask), downloadTask: \(downloadTask)")
        /* Notification that a data task has become a download task.  No
         * future messages will be sent to the data task.
         */
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) {
        DLog("session: \(session), dataTask: \(dataTask), streamTask: \(streamTask)")
        /*
         * Notification that a data task has become a bidirectional stream
         * task.  No future messages will be sent to the data task.  The newly
         * created streamTask will carry the original request and response as
         * properties.
         *
         * For requests that were pipelined, the stream object will only allow
         * reading, and the object will immediately issue a
         * -URLSession:writeClosedForStream:.  Pipelining can be disabled for
         * all requests in a session, or by the NSURLRequest
         * HTTPShouldUsePipelining property.
         *
         * The underlying connection is no longer considered part of the HTTP
         * connection cache and won't count against the total number of
         * connections per host.
         */
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        DLog("session: \(session), dataTask: \(dataTask)")
        /* Sent when data is available for the delegate to consume.  It is
         * assumed that the delegate will retain and not copy the data.  As
         * the data may be discontiguous, you should use
         * [NSData enumerateByteRangesUsingBlock:] to access it.
         */
    }
    
    // MARK: NSURLSessionDownloadDelegate

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        DLog("session: \(session), downloadTask: \(downloadTask), location: \(location)")
        /* Sent when a download task that has completed a download.  The delegate should
         * copy or move the file at the given location to a new location as it will be
         * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
         * still be called.
         */
    }
    
    // MARK: AudioFileStream methods
    
    func handlePropertyChangeForFileStream(audioFileStream: AudioFileStreamID, propertyId: AudioFileStreamPropertyID, flags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
        
        switch (propertyId)
        {
        case kAudioFileStreamProperty_BitRate:
            DLog("kAudioFileStreamProperty_BitRate")
            break;
        case kAudioFileStreamProperty_DataFormat:
            DLog("kAudioFileStreamProperty_DataFormat")
            break;
        case kAudioFileStreamProperty_DataOffset:
            DLog("kAudioFileStreamProperty_DataOffset")
            break;
        case kAudioFileStreamProperty_FileFormat:
            DLog("kAudioFileStreamProperty_FileFormat")
            break;
        case kAudioFileStreamProperty_FormatList:
            DLog("kAudioFileStreamProperty_FormatList")
            break;
        case kAudioFileStreamProperty_ByteToPacket:
            DLog("kAudioFileStreamProperty_ByteToPacket")
            break;
        case kAudioFileStreamProperty_PacketToByte:
            DLog("kAudioFileStreamProperty_PacketToByte")
            break;
        case kAudioFileStreamProperty_ChannelLayout:
            DLog("kAudioFileStreamProperty_ChannelLayout")
            break;
        case kAudioFileStreamProperty_ReadyToProducePackets:
            DLog("kAudioFileStreamProperty_ReadyToProducePackets")
            break;
        case kAudioFileStreamProperty_MagicCookieData:
            DLog("kAudioFileStreamProperty_MagicCookieData")
            break;
        case kAudioFileStreamProperty_AudioDataByteCount:
            DLog("kAudioFileStreamProperty_AudioDataByteCount")
            break;
        case kAudioFileStreamProperty_AudioDataPacketCount:
            DLog("kAudioFileStreamProperty_AudioDataPacketCount")
            break;
        case kAudioFileStreamProperty_MaximumPacketSize:
            DLog("kAudioFileStreamProperty_MaximumPacketSize")
            break;
        case kAudioFileStreamProperty_PacketToFrame:
            DLog("kAudioFileStreamProperty_PacketToFrame")
            break;
        case kAudioFileStreamProperty_FrameToPacket:
            DLog("kAudioFileStreamProperty_FrameToPacket")
            break;
        case kAudioFileStreamProperty_PacketTableInfo:
            DLog("kAudioFileStreamProperty_PacketTableInfo")
            break;
        case kAudioFileStreamProperty_PacketSizeUpperBound:
            DLog("kAudioFileStreamProperty_PacketSizeUpperBound")
            break;
        case kAudioFileStreamProperty_AverageBytesPerPacket:
            DLog("kAudioFileStreamProperty_AverageBytesPerPacket")
            break;
        case kAudioFileStreamProperty_InfoDictionary:
            DLog("kAudioFileStreamProperty_InfoDictionary")
            break;
        default:
            break;
        }
    }
    
    func handleAudioPackets(inputData: UnsafePointer<Void>, numberOfBytes: UInt32, numberOfPackets: UInt32, packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>) {
        
    }
}

