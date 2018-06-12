//
//  Analyzer.swift
//  Music Book
//
//  Created by Sergio on 12.06.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import Foundation
import AVFoundation
import AudioKit
import Log

protocol AnalyzerDelegate {
    func analyzerDidFinishAnalyzing(track: AKAudioFile, result: [(Pitch, Double)], discreteFactor: Double)
}

class Analyzer {
    fileprivate let Log =                   Logger()
    
    var delegate:                           AnalyzerDelegate?

    fileprivate var analyzerTimer:          Timer?
    fileprivate var audioFile:              AKAudioFile!
    fileprivate var detectedNotes:          [(Pitch, Double)] = []
    
    fileprivate let player:                 AKPlayer
    fileprivate var tracker:                AKFrequencyTracker!
    
    var output:                             AKNode!
    
    init() {
        let audioFile = try! AKAudioFile()
        player = AKPlayer(audioFile: audioFile) // AKAudioFile(readFileName: "Intro.m4a"))
        player.buffering = .always
        player.completionHandler = playerDidReachEnd
        
        tracker = AKFrequencyTracker(player, hopSize: 512, peakCount: 20)
        output = AKBooster(tracker, gain: 0)
    }
    
    // MARK: - Public API
    
    public func analyze(audio file: AKAudioFile) {
        self.audioFile = file

        AudioManager.shared.stop()
        player.load(audioFile: file)
        AudioManager.shared.start(shouldInitProperties: false)
        
        player.play()
        
        analyzerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(accumulateFFTData), userInfo: nil, repeats: true)
    }
    
    public func stop() {
        analyzerTimer?.invalidate()
        player.stop()
        detectedNotes.removeAll()
    }
    
    // MARK: - Private API
    
    @objc private func accumulateFFTData() {
        let pitch = Pitch.nearest(self.tracker.frequency)
        let amplitude = self.tracker.amplitude
        self.detectedNotes.append((pitch, amplitude))
    }
    
    private func playerDidReachEnd() {
        analyzerTimer?.invalidate()
        delegate?.analyzerDidFinishAnalyzing(track: self.audioFile, result: detectedNotes, discreteFactor: 0.1)
    }
}
