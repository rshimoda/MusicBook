/*
 * Copyright (c) 2016 Tim van Elsloo
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

protocol TunerDelegate {
    /**
     * The tuner calls this delegate function when it detects a new pitch. The
     * Pitch object is the nearest note (A-G) in the nearest octave. The
     * distance is between the actual tracked frequency and the nearest note.
     * Finally, the amplitude is the volume (note: of all frequencies).
     */
    func tunerDidMeasure(pitch: Pitch, distance: Double, amplitude: Double)
}

class Tuner: NSObject {
    var delegate: TunerDelegate?

    /* Private instance variables. */
    fileprivate var timer:      Timer?
    fileprivate let microphone: AKMicrophone
    fileprivate let filter:     AKHighPassFilter
    fileprivate let tracker:    AKFrequencyTracker
    fileprivate let silence:    AKBooster

    override init() {
        /* Add the built-in microphone. */
        microphone = AKMicrophone()

        /**
         * Add a filter, tracker, silence and store it in an instance variable.
         * NOTE: filter insatnce is required to prevent app crash
         **/
        filter  = AKHighPassFilter(microphone, cutoffFrequency: 200, resonance: 0)
        tracker = AKFrequencyTracker(filter)
        silence = AKBooster(tracker, gain: 0)
    }

    func startMonitoring() {
        do {
            AKSettings.audioInputEnabled = true
            AudioKit.output = silence
            try AudioKit.start()
        } catch {
            debugPrint("ERROR: Tuner.startMonitoring(): \(error.localizedDescription)")
        }

        /* Initialize and schedule a new run loop timer. */
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self,
                                                       selector: #selector(Tuner.tick),
                                                       userInfo: nil,
                                                       repeats: true)
    }

    func stopMonitoring() {
        do {
            try AudioKit.stop()
        } catch {
            debugPrint("ERROR: Tuner.stopMonitoring(): \(error.localizedDescription)")
        }
        timer?.invalidate()
    }

    @objc func tick() {
        /* Read frequency and amplitude from the analyzer. */
        let frequency = tracker.frequency
        let amplitude = tracker.amplitude

        /* Find nearest pitch. */
        let pitch = Pitch.nearest(frequency)

        /* Calculate the distance. */
        let distance = frequency - pitch.frequency

        /* Call the delegate. */
        self.delegate?.tunerDidMeasure(pitch: pitch, distance: distance,
                                            amplitude: amplitude)
    }
}
