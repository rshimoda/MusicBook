//
//  NoiseEvaluator.swift
//  Music Book
//
//  Created by Sergio on 12.06.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import Foundation
import AudioKit
import Log

protocol NoiseEvaluatorUIDelegate {
    func noiseEvaluatorWillStartMeasuring(duration: TimeInterval)
    func noiseEvaluatorDidFinishMeasuring()
}

class NoiseEvaluator {
    fileprivate let Log =                   Logger()

    static let shared =                     NoiseEvaluator()
    var delegate:                           NoiseEvaluatorUIDelegate?
    var threshold:                          Double
    
    fileprivate var noiseDetectionTimer:    Timer?
    fileprivate var noiseLevels:            [Double] = []
    
    fileprivate let tracker:                AKMicrophoneTracker
    
    private init(threshold: Double = 0.1) {
        self.threshold = threshold
        tracker = AKMicrophoneTracker(hopSize: 512, peakCount: 20)
    }
    
    public func startMeasuringNoiseLevel(for measuringTime: TimeInterval) {
        Log.info("Starting noise measuring for \(measuringTime) seconds")
        delegate?.noiseEvaluatorWillStartMeasuring(duration: measuringTime)
        
        tracker.start()
        
        AudioManager.shared.state = .detectingNoise
        
        noiseDetectionTimer = Timer.scheduledTimer(timeInterval: measuringTime / 15,
                                                   target: self,
                                                   selector: #selector(scanCurrentAmplitude),
                                                   userInfo: nil,
                                                   repeats: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(measuringTime))) { [unowned self] in
            self.Log.info("Finishing noise detection")
            
            self.tracker.stop()
            
            /* Stop Measuring Amplitude */
            self.noiseDetectionTimer?.invalidate()
            
            /* Calculate Average Value */
//            self.threshold = self.noiseLevels.reduce(0, +) / self.noiseLevels.count
//            self.threshold *= 1.4
//            self.noiseLevels.removeAll()
            self.evaluateNoiseLevels()
            
            /* Call Delegate's Method */
            self.delegate?.noiseEvaluatorDidFinishMeasuring()
            AudioManager.shared.state = .ready
        }
    }
    
    @objc fileprivate func scanCurrentAmplitude() {
        let amplitude = tracker.amplitude
        noiseLevels.append(amplitude)
    }
    
    fileprivate func evaluateNoiseLevels() {
        let condensated = noiseLevels.map({sqrt(pow($0 * 100, 2) / 100)})
        let average = condensated.reduce(0, +) / noiseLevels.count
        self.threshold = average
        
        noiseLevels.removeAll()
    }
}
