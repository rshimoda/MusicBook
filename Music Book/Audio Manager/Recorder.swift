//
//  Recorder.swift
//  Music Book
//
//  Created by Sergio on 12.06.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import Foundation
import AVFoundation
import AudioKit
import Log

protocol RecorderDelegate: AVAudioRecorderDelegate {
    func recorderWillStartRecording()
    func recorderDidFinishRecording(tape: AKAudioFile?)
}

class Recorder {
    fileprivate let Log =                   Logger()

    var delegate:                           RecorderDelegate?
    var type:                               AudioFrameworkType
    
    // Audio Kit
    fileprivate var akTape:                   AKAudioFile!
    fileprivate var akRecorder:               AKNodeRecorder!
    fileprivate var akRecorderMicMixer:       AKMixer!
    var output:                               AKBooster! // output for recorder
    
    // AVFoundation
    fileprivate var avRecorder:             AVAudioRecorder!
    
    // MARK: - Init
    
    init(type: AudioFrameworkType = .av) {
        self.type = type
        
        switch type {
        case .ak:
            Log.info("Using AudioKit Recorder")
            akTape = try! AKAudioFile()
            akRecorder = try! AKNodeRecorder(node: AudioManager.shared.mic, file: akTape)
        case .ez:
            Log.info("Using EZAudio Recorder")
        case .av:
            let fileURL = getURLForAudio()
            
            let recordSettings = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ] as [String : Any]
            
            do {
                avRecorder = try AVAudioRecorder(url: fileURL, settings: recordSettings)
                avRecorder.delegate = self.delegate
                avRecorder.prepareToRecord()
            } catch {
                Log.error("Error creating audioRecorder")
            }
        }
    }
    
    // MARK: - Public API
    
    func startRecording() {
        Log.info("Starting Recorder")
        AudioManager.shared.state = .readyToRecord
        
        delegate?.recorderWillStartRecording()
        
        switch self.type {
        case .ak:
            Log.info("Using AudioKit Recorder")
            if AKSettings.headPhonesPlugged {
                Log.info("Headphones detected - Gaining microphone")
                output.gain = 1
            }
            
            do {
                Log.info("Deleting leftovers")
                try akRecorder.reset()
                Log.info("Recording...")
                try akRecorder.record()
            } catch {
                Log.error(error.localizedDescription)
            }
        case .ez:
            Log.info("Using EZAudio Recorder")
        case .av:
            Log.info("Using AVFoundation Recorder")
            avRecorder.record()
        }
        
        AudioManager.shared.state = .recording
    }
    
    func stopRecording() {
        Log.info("Stopping Recorder")
        
        switch self.type {
        case .ak:
            stopAKRecorder()
        case .ez:
            stopEZRecorder()
        case .av:
            stopAVRecorder()
        }
        
        AudioManager.shared.state = .ready
    }
    
    // MARK: - Private API
    
    fileprivate func getURLForAudio() -> URL {
        let tempDir = NSTemporaryDirectory()
        let filePath = tempDir + "/TempMemo\(DataStorage.audios.count + 1).caf"
        return URL(fileURLWithPath: filePath)
    }
    
    private func stopAKRecorder() {
        output.gain = 0
        
        Log.info("Obtaining audio file from Recorder")
        if let audioFile = akRecorder.audioFile {
            akRecorder.stop()
            
            Log.info("Exporting audio file")
            audioFile.exportAsynchronously(name: "Recording\(DataStorage.audios.count + 1).m4a", baseDir: .documents, exportFormat: .m4a, callback: { savedAudioFile, exportError in
                
                guard let file = savedAudioFile else {
                    self.Log.error("Failed to get the Audio File after exporting. Error: \(exportError?.localizedDescription ?? "-")")
                    
                    self.Log.info("Trying to get file via URL...")
                    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                    let audioFilePath = String(format: "%s/%s", paths.first!, "/Recording\(DataStorage.audios.count + 1).m4a")
                    let audioURL = URL(fileURLWithPath: audioFilePath)
                    let audioFile = try? AKAudioFile(forReading: audioURL)
                    self.Log.info(audioFile == nil ? "Fail" : "Success")
                    
                    self.delegate?.recorderDidFinishRecording(tape: audioFile)
                    
                    return
                }
                
                self.Log.info("Export finished successfully.")
                self.delegate?.recorderDidFinishRecording(tape: file)
            })
        } else {
            Log.error("Failed to get the audio file from Recorder")
            delegate?.recorderDidFinishRecording(tape: nil)
        }
    }
    
    private func stopEZRecorder() {
        
    }
    
    private func stopAVRecorder() {
        avRecorder.stop()
        
        let audioFile = try! AKAudioFile(forReading: getURLForAudio())
        delegate?.recorderDidFinishRecording(tape: audioFile)
    }
}
