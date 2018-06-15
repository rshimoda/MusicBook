//
//  Player.swift
//  Music Book
//
//  Created by Sergio on 12.06.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import Foundation
import AVFoundation
import AudioKit
import Log

protocol PlayerDelegate: EZAudioPlayerDelegate, AVAudioPlayerDelegate {
    func playerDidFinishPlaying()
    func playerDidCompleteTrack(for percent: Double)
}

class Player {
    fileprivate let Log =                   Logger()

    var delegate:                           PlayerDelegate?
    var type:                               AudioFrameworkType
    
    fileprivate var audioFile:              AKAudioFile!
    
    // AudioKit
    fileprivate var akPlayer:               AKPlayer!
    fileprivate var akPlayerMoogLadder:     AKMoogLadder!
    var output:                             AKNode // AKMixer! // output for player
    
    // EZAudio - Buggy
    fileprivate var ezPlayer:               EZAudioPlayer!
    
    // AVFoundation
    fileprivate var avPlayer:               AVAudioPlayer!
    
    init(type: AudioFrameworkType = .av) {
        self.type = type
        
        let audioFile = try! AKAudioFile(readFileName: "Intro.m4a")
        akPlayer = AKPlayer(audioFile: audioFile)
        akPlayer.buffering = .always
        
        output = akPlayer
    }
    
    // MARK: - Public API
    
    func play(tape: AKAudioFile) {
        Log.info("Starting Player")
        AudioManager.shared.mic.stop()
        
        AudioManager.shared.state = .readyToPlay
        
        self.audioFile = tape
        
        switch self.type {
        case .ak:
            prepareAKPlayer()
            akPlayer.play()
        case .ez:
            prepareEZPlayer()
            ezPlayer.play()
        case .av:
            prepareAVPlayer()
            avPlayer.play()
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
                if AudioManager.shared.state == .paused {
                    return
                }
                
                guard self.avPlayer.isPlaying else {
                    timer.invalidate()
                    return
                }
                
                self.delegate?.playerDidCompleteTrack(for: self.avPlayer.currentTime * 100 / self.avPlayer.duration)
            }
        }
        AudioManager.shared.state = .playing
    }
    
    func pausePlaying() {
        Log.info("Pausing Player")
        
        switch self.type {
        case .ak:
            akPlayer.pause()
        case .ez:
            ezPlayer.pause()
        case .av:
            avPlayer.pause()
        }
        
        AudioManager.shared.state = .paused
    }
    
    func resumePlaying() {
        Log.info("Resuming Player")
        
        switch self.type {
        case .ak:
            akPlayer.resume()
        case .ez:
            ezPlayer.play()
        case .av:
            avPlayer.play()
        }
        
        AudioManager.shared.state = .playing
    }
    
    func stopPlaying() {
        Log.info("Stopping Player")
        
        switch self.type {
        case .ak:
            akPlayer.stop()
        case .ez:
            ezPlayer.pause()
            ezPlayer.seek(toFrame: 0)
        case .av:
            avPlayer.stop()
        }
        
        AudioManager.shared.mic.start()
        AudioManager.shared.state = .ready
    }
    
    // MARK: - Private API
    
    private func prepareAKPlayer() {
        AudioManager.shared.stop()
        akPlayer.completionHandler = delegate?.playerDidFinishPlaying
        akPlayer.load(audioFile: self.audioFile)
        AudioKit.output = self.output
        AudioManager.shared.start()
    }
    
    private func prepareEZPlayer() {
        ezPlayer = EZAudioPlayer(audioFile: EZAudioFile(url: self.audioFile.url), delegate: self.delegate)
    }
    
    private func prepareAVPlayer() {
        do {
            avPlayer = try AVAudioPlayer(contentsOf: self.audioFile.url)
            avPlayer.delegate = self.delegate
        } catch {
            Log.error("Failed to create AVPlayer instance. Error: \(error.localizedDescription)")
        }
    }
}
