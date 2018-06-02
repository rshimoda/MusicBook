//
//  AudioManager.swift
//  Music Book
//
//  Created by Sergio on 25/5/18.
//  Copyright © 2018 Sergio. All rights reserved.
//

import AudioKit
import AudioKitUI
import Sugar

protocol TunerDelegate {
    /**
     * The tuner calls this delegate function when it detects a new pitch. The
     * Pitch object is the nearest note (A-G) in the nearest octave. The
     * distance is between the actual tracked frequency and the nearest note.
     * Finally, the amplitude is the volume (note: of all frequencies).
     */
    func tunerDidMeasure(pitch: Pitch, distance: Double, amplitude: Double)
    func tunerWillMeasureNoiseLevel(duration: TimeInterval)
    func tunerDidMeasureNoiseLevel(noise: Double)
}

protocol RecorderDelegate {
    func recorderWillStartRecording()
    func recorderDidFinishRecording(successfully: Bool, tape: AKAudioFile?)
}

protocol PlayerDelegate: EZAudioPlayerDelegate {
    func playerDidFinishPlaying()
}

class AudioManager {
    
    // MARK: - Shared Instance
    
    static let shared =                     AudioManager()
    
    // MARK: - Delegates
    
    var tunerDelegate:                      TunerDelegate?
    var recorderDelegate:                   RecorderDelegate?
    var playerDelegate:                     PlayerDelegate?
    
    // MARK: - Common Variables
    
    public let mic:                         AKMicrophone
    fileprivate var silence:                AKBooster?
    
    public var state:                       AKState {
        willSet {
            if newValue == .ready {
//                startMeasuringNoiseLevel(during: 3.0)
            }
        }
    }
    
    // MARK: - Tuner Variables
    
    fileprivate var tunerTimer:             Timer?
    public var tuningTimeInterval =         0.1
    
    fileprivate let tracker:                AKFrequencyTracker
//    fileprivate let micTracker:             AKMicrophoneTracker
    fileprivate let tunerSilence:           AKBooster // output for tuner
    
    public var smoothing:                   Double
    fileprivate var smoothingBuffer:        [Double] = []
    fileprivate let smoothingBufferCount =  30
    
    // MARK: - Noise Detection Variables
    
    fileprivate var noiseDetectionTimer:    Timer?
    public var threshold:                   Double
    fileprivate var noiseLevels: [Double] = []
    
    // MARK: - Recorder Variables
    
    fileprivate let recorder:               AKNodeRecorder
    fileprivate let recorderMicMixer:       AKMixer
    fileprivate let recorderMicBooster:     AKBooster // output for recorder
    
    // MARK: - Player Variables
    
    fileprivate var player:                 AKPlayer
    fileprivate var playerMoogLadder:       AKMoogLadder
    fileprivate var playerMainMixer:        AKMixer // output for player
    
    fileprivate var ezPlayer:               EZAudioPlayer!
    
    // MARK: - Initializtion
    
    private init() {
        /* General Settings */
        AKSettings.playbackWhileMuted = true
        AKSettings.defaultToSpeaker = true
        AKSettings.audioInputEnabled = true
        AKSettings.playbackWhileMuted = true
        AKSettings.bufferLength = .medium
        
//        do {
//            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
//        } catch {
//            AKLog(error.localizedDescription)
//        }
        
        mic = AKMicrophone()
        silence = AKBooster(mic, gain: 0)
        
        if let inputs = AudioKit.inputDevices {
            do {
                try AudioKit.setInputDevice(inputs[0])
                try mic.setDevice(inputs[0])
            } catch {
                print("Failed to set up input device")
            }
        }
        
        /* Tuner Setup */
        threshold = 0.0
        smoothing = 0.25
        
        let booster = AKBooster(mic, gain: 4)
        tracker = AKFrequencyTracker(booster, hopSize: 512, peakCount: 20)
//        micTracker = AKMicrophoneTracker(hopSize: 512, peakCount: 20)
        tunerSilence = AKBooster(tracker, gain: 0)
        
        /* Recorder Setup */
        AKAudioFile.cleanTempDirectory()
        recorderMicMixer = AKMixer(mic)
        recorderMicBooster = AKBooster(recorderMicMixer, gain: 0)
        recorder = try! AKNodeRecorder(node: recorderMicMixer)
        
        /* Player Setup */
        let file = try! recorder.audioFile ?? AKAudioFile(forReading: URL(fileURLWithPath: Bundle.main.path(forResource: "Intro", ofType: "m4a") ?? ""))
        player = AKPlayer(audioFile: file)
        player.isLooping = true
        playerMoogLadder = AKMoogLadder(player)
        playerMainMixer = AKMixer(playerMoogLadder)// , recorderMicBooster)
        
        AudioKit.output = AKMixer(tunerSilence, playerMoogLadder, recorderMicBooster)
        
        state = .ready
    }
    
    // MARK: - Switch Mode
    
    fileprivate func switchState(to state: AKState) {
        self.state = state
        
//        switch state {
//        case .readyToTune, .tuning:
//            AudioKit.output = tunerSilence
//        case .readyToRecord, .recording:
//            AudioKit.output = recorderMicBooster
//        case .readyToPlay, .playing:
//            AudioKit.output = playerMainMixer
//        default:
//            return
//        }
    }
    
    // MARK: - Noise Detection
    
    public func startMeasuringNoiseLevel(during seconds: TimeInterval) {
        state = .detectingNoise
        tunerDelegate?.tunerWillMeasureNoiseLevel(duration: seconds)
        
        noiseDetectionTimer = Timer.scheduledTimer(timeInterval: seconds / 15,
                                    target: self,
                                    selector: #selector(measureNoiseLevel),
                                    userInfo: nil,
                                    repeats: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [unowned self] in
            /* Stop Measuring Amplitude */
            self.noiseDetectionTimer?.invalidate()
            
            /* Calculate Average Value */
            self.threshold = self.noiseLevels.reduce(0, +) / self.noiseLevels.count
            self.threshold *= 1.4
            self.noiseLevels.removeAll()
            
            /* Call Delegate's Method */
            self.tunerDelegate?.tunerDidMeasureNoiseLevel(noise: self.threshold)
        }
    }
    
    @objc fileprivate func measureNoiseLevel() {
        let amplitude = tracker.amplitude
        noiseLevels.append(amplitude)
    }
    
    // MARK: - Tuner
    
    public func startTuning() {
        switchState(to: .tuning)
        
        tunerTimer = Timer.scheduledTimer(timeInterval: self.tuningTimeInterval,
                           target: self,
                           selector: #selector(collectFFTData),
                           userInfo: nil,
                           repeats: true)
        state = .tuning
    }
    
    public func stopTuning() {
        tunerTimer?.invalidate()
        state = .ready
    }
    
    @objc fileprivate func collectFFTData() {
        /* Read frequency and amplitude from the analyzer. */
        let frequency = smooth(tracker.frequency)
        let amplitude = tracker.amplitude
        
        /* Find nearest pitch. */
        let pitch = Pitch.nearest(frequency)
        
        /* Calculate the distance. */
        let distance = frequency - pitch.frequency
        
        /* Call the delegate. */
        tunerDelegate?.tunerDidMeasure(pitch: pitch, distance: distance, amplitude: amplitude)
    }
    
    /**
     Exponential smoothing:
     https://en.wikipedia.org/wiki/Exponential_smoothing
     */
    fileprivate func smooth(_ value: Double) -> Double {
        var frequency = value
        if smoothingBuffer.count > 0 {
            let last = smoothingBuffer.last!
            frequency = (smoothing * value) + (1.0 - smoothing) * last
            if smoothingBuffer.count > smoothingBufferCount {
                smoothingBuffer.removeFirst()
            }
        }
        smoothingBuffer.append(frequency)
        return frequency
    }
    
    // MARK: - Recorder
    
    func startRecording() {
        guard state == .ready else {
            return
        }
        
        switchState(to: .readyToRecord)
        
        if AKSettings.headPhonesPlugged {
            recorderMicBooster.gain = 1
        }
        
        recorderDelegate?.recorderWillStartRecording()
        
        do {
            try recorder.reset()
            try recorder.record()
            switchState(to: .recording)
        } catch {
            AKLog("\(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        guard state == .recording else {
            return
        }
        
        recorderMicBooster.gain = 0
        if let audioFile = recorder.audioFile {
            recorderDelegate?.recorderDidFinishRecording(successfully: true, tape: audioFile)
        } else {
            recorderDelegate?.recorderDidFinishRecording(successfully: false, tape: nil)
        }
        recorder.stop()
        
        switchState(to: .ready)
    }
    
    // MARK: - Player
    
    func play(tape: AKAudioFile) {
//        player.completionHandler = playerDelegate?.playerDidFinishPlaying
        ezPlayer = EZAudioPlayer(audioFile: EZAudioFile(url: tape.url), delegate: self.playerDelegate)
        switchState(to: .readyToPlay)

        ezPlayer.play()
//        player.load(audioFile: tape)
//        player.play()
        
        state = .playing
    }
    
    func pausePlaying() {
        switchState(to: .readyToPlay)
//        player.pause()
        ezPlayer.pause()
    }
    
    func resumePlaying() {
        switchState(to: .playing)
//        player.resume()
        ezPlayer.play()
    }
    
    func stopPlaying() {
        switchState(to: .ready)
//        player.stop()
        ezPlayer.pause()
        mic.start()
    }
    
    fileprivate func playerCompletionHandler() {
        playerDelegate?.playerDidFinishPlaying()
    }
    
    public func start() {
        dispatch {
            do {
                try AudioKit.start()
//                self.micTracker.start()
            } catch {
                fatalError("Failed to start AudioKit - \(error.localizedDescription)")
            }
        }
    }
    
    public func stop() {
        dispatch {
            do {
                try AudioKit.stop()
            } catch {
                fatalError("Failed to stop AudioKit - \(error.localizedDescription)")
            }
        }
    }
}
