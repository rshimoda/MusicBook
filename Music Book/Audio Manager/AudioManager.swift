//
//  AudioManager.swift
//  Music Book
//
//  Created by Sergio on 25/5/18.
//  Copyright © 2018 Sergio. All rights reserved.
//

import AVFoundation
import AudioKit
import AudioKitUI
import Sugar
import Log

enum AudioFrameworkType {
    case ak
    case ez
    case av
}

class AudioManager {
    
    static let shared =                     AudioManager()
    
    public let mic:                         AKMicrophone
    public var state:                       AKState
    
    fileprivate let Log =                   Logger()
    fileprivate let nc =                    NotificationCenter.default

    // MARK: - Delegates
    
    public var tuner:                       Tuner!
    public var noiseEvaluator:              NoiseEvaluator!
    public var recorder:                    Recorder!
    public var player:                      Player!
    public var analyzer:                    Analyzer!
    
    // MARK: - Common Variables

    let session = AVAudioSession.sharedInstance()
    
    // MARK: - Initializtion
    
    private init() {
        Log.info("Initializing Audio Manager...")
        
        AKSettings.playbackWhileMuted = true
        AKSettings.defaultToSpeaker = true
        AKSettings.audioInputEnabled = true
        AKSettings.playbackWhileMuted = true
        AKSettings.bufferLength = .medium
        
        mic = AKMicrophone()
        
        Log.debug("Setting up input device...")
        if let inputs = AudioKit.inputDevices {
            do {
                try AudioKit.setInputDevice(inputs[0])
                try mic.setDevice(inputs[0])
            } catch {
                Log.error("Failed to set up input device")
            }
        }
        Log.debug("Set to ", AudioKit.inputDevice ?? "None")
        
        /*
        /* Recorder Setup */
        Log.debug("Setting up recorder...")
        AKAudioFile.cleanTempDirectory()
        recorderMicMixer = AKMixer(mic)
        recorderMicBooster = AKBooster(recorderMicMixer, gain: 0)
        recorder = try! AKNodeRecorder(node: recorderMicMixer)
        Log.debug("Done")
        
        /* Player Setup */
        Log.debug("Setting up player...")
        let file = try! recorder.audioFile ?? AKAudioFile(forReading: URL(fileURLWithPath: Bundle.main.path(forResource: "Intro", ofType: "m4a") ?? ""))
        player = AKPlayer(audioFile: file)
        player.isLooping = true
        playerMoogLadder = AKMoogLadder(player)
        playerMainMixer = AKMixer(playerMoogLadder) //, recorderMicBooster)
        Log.debug("Done")
        */
        
        state = .ready
        
        /* Hadndle Route change and Interruption */
        
        nc.addObserver(self, selector: #selector(handleInterruption(notification:)), name: NSNotification.Name.AVAudioSessionInterruption, object: session)
        nc.addObserver(self, selector: #selector(handleRouteChange(notification:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: session)
        
        Log.info("Audio Manager setup complete")
    }
    
    // MARK: - Notifications
    
    @objc func handleInterruption(notification: NSNotification) {
        if let info = notification.userInfo {
            let type = AVAudioSessionInterruptionType(rawValue: info[AVAudioSessionInterruptionTypeKey] as! UInt)
            if type == .began {
                Log.warning("Interruption Detected")
            } else {
                let options = AVAudioSessionInterruptionOptions(rawValue: info[AVAudioSessionInterruptionOptionKey] as! UInt)
                
                if options == .shouldResume {
                    // Do something here...
                }
            }
        }
    }
    
    @objc func handleRouteChange(notification: NSNotification) {
        if let info = notification.userInfo {
            
            let reason = AVAudioSessionRouteChangeReason(rawValue: info[AVAudioSessionRouteChangeReasonKey] as! UInt)
            if reason == .oldDeviceUnavailable {
                let previousRoute = info[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
                let previousOutput = previousRoute!.outputs.first!
                if previousOutput.portType == AVAudioSessionPortHeadphones {
                    Log.warning("Headphones disconnected")
                }
            }
        }
    }
    
    // MARK: - Switch Mode
    
    fileprivate func switchState(to state: AKState) {
        Log.info("Swithcing Audio Manager to state \(state)")
        self.state = state
    }
    
    // MARK: - AudioKit
    
    public func start(shouldInitProperties: Bool = true) {
        Log.info("Starting AudioKit engine")
        
        if shouldInitProperties {
            tuner = Tuner(tuningInterval: 0.1, smoothing: 0.25)
            noiseEvaluator = NoiseEvaluator.shared
            recorder = Recorder(type: .av)
            player = Player(type: .av)
            analyzer = Analyzer()
    
            AudioKit.output = AKMixer([tuner.output, /*recorder.output,*/ player.output, analyzer.output])
        }
        
        
        let dispatchQueue = DispatchQueue(label: "com.app.queue")
        dispatchQueue.sync {
            do {
                try AudioKit.start()
            } catch {
                fatalError("Failed to start AudioKit - \(error.localizedDescription)")
            }
        }
        Log.info("AudioKit is running")
    }
    
    public func stop() {
        Log.info("Stopping AudioKit engine")
        let dispatchQueue = DispatchQueue(label: "com.app.queue")
        dispatchQueue.sync {
            do {
                try AudioKit.stop()
            } catch {
                fatalError("Failed to stop AudioKit - \(error.localizedDescription)")
            }
        }
        Log.info("AudioKit is stopped")
    }
}
