//
//  ViewController.swift
//  Music Book
//
//  Created by Sergio on 24.04.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import Hero
import AudioKit
import ChameleonFramework

class ViewController: UIViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var gradientView:            MKGradientView!
    @IBOutlet weak var recordingGradientView:   MKGradientView!
    @IBOutlet weak var autoButtonContainer:     UIView!
    @IBOutlet weak var autoButton:              UIButton!
    @IBOutlet weak var recordButton:            UIButton!
    @IBOutlet weak var stopButton:              UIButton!
    @IBOutlet weak var tunnerButton:            UIButton!
    @IBOutlet weak var libraryButton:           UIButton!
    
    let mic =       AKMicrophone()
    var micMixer:   AKMixer!
    var recorder:   AKNodeRecorder!
    var player:     AKPlayer!
    var tape:       AKAudioFile!
    var micBooster: AKBooster!
    var moogLadder: AKMoogLadder!
    var delay:      AKDelay!
    var mainMixer:  AKMixer!
    
    private var autoModeEnabled =   false
    private var state =             AKState.readyToRecord
    
    var fileURL: URL {
        return getDocumentsDirectory().appendingPathComponent("recording\(DataStorage.audios.count).m4a")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRecorder()
        
        gradientView.type = .radial
        recordingGradientView.type = .radial
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.2,
                                   delay: 0.25,
                                   options: [],
                                   animations: {
                                    self.recordButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        },
                                   completion: { finished in
//                                    UIView.animate(withDuration: 0.3,
//                                                               delay: 0.0,
//                                                               options: [.curveEaseInOut],
//                                                               animations: {
//                                                                self.view.transform = .identity
//                                    },
//                                                               completion: nil
//                                    )
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Recording
    
    func setupRecorder() {
        AKAudioFile.cleanTempDirectory()
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("ERROR: Couldn't set session category (\(error.localizedDescription))")
        }
        
        AKSettings.defaultToSpeaker = true
        
        micMixer = AKMixer(mic)
        
        micBooster = AKBooster(micMixer)
        micBooster.gain = 0
        
        recorder = try? AKNodeRecorder(node: micMixer)
        if let audioFile = recorder.audioFile {
            player = AKPlayer(audioFile: audioFile)
        }
        player.isLooping = true
        
        moogLadder = AKMoogLadder(player)
        mainMixer = AKMixer(moogLadder, micBooster)
        
        AudioKit.output = mainMixer
        do {
            try AudioKit.start()
        } catch {
            AKLog("Failed to start AudioKit.")
        }
    }

    @IBAction func toggleAuto() {
        if autoModeEnabled {
            autoButtonContainer.backgroundColor = UIColor.clear
            recordButton.isEnabled = true
        } else {
            autoButtonContainer.backgroundColor = UIColor.flatRed
            recordButton.isEnabled = false
        }
        
        autoModeEnabled = !autoModeEnabled
    }
    
    @IBAction func startRecording() {
        guard state == .readyToRecord else {
            debugPrint("Recording cannot be started.")
            return
        }
        
        state = .recording
        
        UIView.animate(withDuration: 0.1) { [unowned self] in
            self.recordingGradientView.isHidden = false
            self.autoButton.isEnabled = false
            self.stopButton.isHidden = false
            self.recordButton.isEnabled = false
            self.recordButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        if AKSettings.headPhonesPlugged {
            micBooster.gain = 1
        }
        
        do {
            try recorder.record()
        } catch {
            AKLog("Failed to start recording.")
        }
    }
    
    @IBAction func stopRecording() {
        state = .readyToRecord
        
        micBooster.gain = 0
        tape = recorder.audioFile!
        player.load(audioFile: tape)
        
        recorder.stop()
        
        DataStorage.audios.append(tape)
        
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.recordingGradientView.isHidden = true
            self.autoButton.isEnabled = true
            self.stopButton.isHidden = true
            self.recordButton.isEnabled = true
            self.recordButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        performSegue(withIdentifier: "Open Library", sender: self)
    }
    
    // MARK: - Helpers
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!
    }
    
    func getURLforMemo() -> URL {
        let tempDir = NSTemporaryDirectory()
        let filePath = "\(tempDir)/TempMemo\(DataStorage.audios.count).caf"
        
        return URL.init(fileURLWithPath: filePath) //.fileURLWithPath(filePath)
    }
    
    func formattedCurrentTime(time: UInt) -> String {
        let hours = time / 3600
        let minutes = (time / 60) % 60
        let seconds = time % 60
        
        return String(format: "%02i:%02i:%02i", arguments: [hours, minutes, seconds])
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if autoModeEnabled {
            toggleAuto()
        }
        
        if state == .recording {
            stopRecording()
        }
        
        try! AudioKit.stop()
        
        guard let identifier = segue.identifier else {
            return
        }
        
        segue.destination.hero.isEnabled = true
        
        switch identifier {
        case "Open Tuner":
            segue.destination.hero.modalAnimationType = .selectBy(presenting: .slide(direction: .down), dismissing: .slide(direction: .up))
        case "Open Library":
            segue.destination.hero.modalAnimationType = .selectBy(presenting: .slide(direction: .up), dismissing: .slide(direction: .down))
        default:
            break
        }
        
    }
    
    @IBAction func rewindToRecordViewController(sender: UIStoryboardSegue) {
        try! recorder.reset()
        try! AudioKit.start()
    }
}

