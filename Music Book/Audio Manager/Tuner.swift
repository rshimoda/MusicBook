//
//  Tuner.swift
//  Music Book
//
//  Created by Sergio on 12.06.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import Foundation
import AVFoundation
import AudioKit
import Log

protocol TunerDelegate {
    /**
     * The tuner calls this delegate function when it detects a new pitch. The
     * Pitch object is the nearest note (A-G) in the nearest octave. The
     * distance is between the actual tracked frequency and the nearest note.
     * Finally, the amplitude is the volume (note: of all frequencies).
     */
    func tunerDidMeasure(pitch: Pitch, distance: Double, amplitude: Double)
}

class Tuner {
    fileprivate let Log =                   Logger()

    var delegate:                           TunerDelegate?
    
    public var tuningTimeInterval:          Double
    public var smoothing:                   Double
    
    fileprivate var timer:                  Timer?
    fileprivate let tracker:                AKFrequencyTracker
    fileprivate let micTracker:             AKMicrophoneTracker
    let output:                             AKBooster
    
    fileprivate var smoothingBuffer:        [Double] = []
    fileprivate let smoothingBufferCount =  30
    
    // MARK: - Init
    
    init(tuningInterval: Double = 0.05, smoothing: Double = 0.25) {
        self.tuningTimeInterval = tuningInterval
        self.smoothing = smoothing
        
        tracker = AKFrequencyTracker(AudioManager.shared.mic, hopSize: 512, peakCount: 20)
        micTracker = AKMicrophoneTracker(hopSize: 512, peakCount: 20)
        output = AKBooster(tracker, gain: 0)
    }
    
    // MARK: - Public API
    
    public func start() {
        Log.info("Starting Tunner")
        
        micTracker.start()
        AudioManager.shared.state = .readyToTune

        timer = Timer.scheduledTimer(timeInterval: self.tuningTimeInterval,
                                          target: self,
                                          selector: #selector(collectFFTData),
                                          userInfo: nil,
                                          repeats: true)
        
        AudioManager.shared.state = .tuning
    }
    
    public func stop() {
        Log.info("Stopping Tunner")
        timer?.invalidate()
        AudioManager.shared.state = .ready
    }
    
    // MARK: - Private API
    
    @objc fileprivate func collectFFTData() {
        /* Read frequency and amplitude from the analyzer. */
        let frequency = smooth(micTracker.frequency)
        let amplitude = micTracker.amplitude
        
        /* Find nearest pitch. */
        let pitch = Pitch.nearest(frequency)
        
        /* Calculate the distance. */
        let distance = frequency - pitch.frequency
        
        /* Call the delegate. */
        delegate?.tunerDidMeasure(pitch: pitch, distance: distance, amplitude: amplitude)
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
}
