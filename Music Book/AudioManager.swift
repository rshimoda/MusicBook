//
//  AudioManager.swift
//  Music Book
//
//  Created by Sergio on 25/5/18.
//  Copyright © 2018 Sergio. All rights reserved.
//

import AudioKit
import AudioKitUI

class AudioManager {
    static let shared = AudioManager()
    
    private var microphone: AKMicrophone!
    
    private init() {
        AKSettings.playbackWhileMuted = true
        AKSettings.defaultToSpeaker = true
        AKSettings.audioInputEnabled = true
        AKSettings.bufferLength = .medium
        
        microphone = AKMicrophone()
        
        if let inputs = AudioKit.inputDevices {
            try! AudioKit.setInputDevice(inputs[0])
            try! microphone.setDevice(inputs[0])
        }
    }
    
    public static func start() {
        do {
            try AudioKit.start()
        } catch {
            fatalError("Failed to start AudioKit - \(error.localizedDescription)")
        }
    }
    
    public func resume() {
        microphone.start()
    }
    
    public func pause() {
        microphone.stop()
    }
    
    public static func stop() {
        do {
            try AudioKit.stop()
        } catch {
            fatalError("Failed to stop AudioKit - \(error.localizedDescription)")
        }
    }
}
