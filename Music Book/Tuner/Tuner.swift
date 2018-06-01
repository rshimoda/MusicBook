/*
 * Copyright (c) 2018 Sergi Popov
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import Foundation
import AudioKit
import Sugar

class Tuner: NSObject {
    var delegate: TunerDelegate?

    /* AudioKit instance variables. */
    fileprivate var timer:                      Timer?
    
    fileprivate let microphone:                 AKMicrophone
    fileprivate let microphoneTracker:          AKMicrophoneTracker
    
    fileprivate let booster:                    AKBooster
    fileprivate let tracker:                    AKFrequencyTracker
    fileprivate let silence:                    AKBooster
    
    
    /* Private instanse variables */
    var threshold =                             DataStorage.threshold
    fileprivate let smoothing:                  Double
    fileprivate var smoothingBuffer: [Double] = []
    fileprivate let smoothingBufferCount =      30
    
    fileprivate var noiseLevels: [Double] =     []

    public init(threshold: Float = 0.0, smoothing: Float = 0.25) {
        self.threshold = Double(min(abs(threshold), 1.0))
        self.smoothing = Double(min(abs(smoothing), 1.0))
        
        /* Add the built-in microphone. */
        microphone = AKMicrophone() // AudioManager.shared.mic // AKMicrophone()
//        microphone.start()
        microphoneTracker = AKMicrophoneTracker() // hopSize: 200, peakCount: 2_000)
        microphoneTracker.start()

        /* Add a filter, tracker, silence and store it in an instance variable. */
        booster = AKBooster(microphone, gain: 5)
        tracker = AKFrequencyTracker(booster) // , hopSize: 200, peakCount: 2_000)
        tracker.start()
        silence = AKBooster(tracker, gain: 0)
        AudioKit.output = silence
    }
    
    func startMonitoring() {
        Me.start { [unowned self] (me) in
            if self.threshold == 0.0 {
                dispatch {
                    self.adjustNoiseLevel(duration: 3.0) {
                        me.runNext()
                    }
                }
            } else {
                me.runNext()
            }
            }.next { [unowned self] (caller, me) in
                debugPrint("Seting up tuner timer")
                dispatch {
                    self.timer = Timer.scheduledTimer(timeInterval:  0.05,
                                                      target:        self,
                                                      selector:      #selector(Tuner.tick),
                                                      userInfo:      nil,
                                                      repeats:       true)
                }
            }.run()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        microphoneTracker.stop()
    }
    
    func adjustNoiseLevel(duration: Double, completion: (() -> ())?) {
        delegate?.tunerWillMeasureNoiseLevel(duration: duration)
        
        let noiseDetectionTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(getAmplitude), userInfo: nil, repeats: true)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) { [unowned self] in
            noiseDetectionTimer.invalidate()
            
            debugPrint("Detected amplitudes: \(self.noiseLevels)")
            
            let sorted = self.noiseLevels.sorted(by: >)[0..<Int(sqrt(Double(self.noiseLevels.count)))]
            self.noiseLevels.removeAll()
            self.threshold = sorted.reduce(0.0, +) / sorted.count
            self.threshold *= 1.1
            
            debugPrint("Calculated threshold: \(self.threshold)")
        
            self.delegate?.tunerDidMeasureNoiseLevel(noise: self.threshold)
            
            completion?()
        }
    }
    
    @objc func getAmplitude() {
//        noiseLevels.append(tracker.amplitude)
        noiseLevels.append(microphoneTracker.amplitude)
    }

    @objc func tick() {
        /* Read frequency and amplitude from the analyzer. */
        let frequency = smooth(tracker.frequency)
        let amplitude = microphoneTracker.amplitude // tracker.amplitude

        /* Find nearest pitch. */
        let pitch = Pitch.nearest(frequency)

        /* Calculate the distance. */
        let distance = frequency - pitch.frequency

        /* Call the delegate. */
        self.delegate?.tunerDidMeasure(pitch: pitch, distance: distance,
                                            amplitude: amplitude)
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
