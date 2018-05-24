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
    
    // MARK: - Outlets
    
    @IBOutlet weak var gradientView:            MKGradientView!
    @IBOutlet weak var recordingGradientView:   MKGradientView!
    @IBOutlet weak var autoButtonContainer:     UIView!
    @IBOutlet weak var autoButton:              UIButton!
    @IBOutlet weak var recordButton:            UIButton!
    @IBOutlet weak var stopButton:              UIButton!
    @IBOutlet weak var tunnerButton:            UIButton!
    @IBOutlet weak var libraryButton:           UIButton!
    
    // MARK: - AudioKit Variables
    
    let mic =                                   AudioManager.shared.microphone
    var micMixer:                               AKMixer!
    var recorder:                               AKNodeRecorder!
    var player:                                 AKPlayer!
    var tape:                                   AKAudioFile!
    var micBooster:                             AKBooster!
    var moogLadder:                             AKMoogLadder!
    var delay:                                  AKDelay!
    var mainMixer:                              AKMixer!
    
    // MARK: - Internal Variables
    
    private var state =                         AKState.readyToRecord
    
    var fileURL: URL {
        return getDocumentsDirectory().appendingPathComponent("recording\(DataStorage.audios.count).m4a")
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRecorder()
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI
    
    func setupUI() {
        gradientView.type = .radial
        recordingGradientView.type = .radial
        
        UIView.animate(withDuration: 0.2,
                       delay: 0.25,
                       options: [],
                       animations: {
                        self.recordButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        },
                       completion: { finished in
        })
    }
    
    // MARK: - Recording
    
    func setupRecorder() {
        AKAudioFile.cleanTempDirectory()
        
        micMixer = AKMixer(mic)
        
        micBooster = AKBooster(micMixer)
        micBooster.gain = 0
        
        recorder = try? AKNodeRecorder(node: micMixer)
        
//        if let audioFile = recorder.audioFile {
//            player = AKPlayer(audioFile: audioFile)
//        }
        
//        player.isLooping = true
        
//        moogLadder = AKMoogLadder(player)
//        mainMixer = AKMixer(moogLadder, micBooster)
        
        AudioKit.output = micBooster // mainMixer
        AudioManager.start()
        
//        do {
//            try AudioKit.start()
//            recorderWasSetUp = true
//        } catch {
//            AKLog("Failed to start AudioKit.")
//        }
    }

    @IBAction func toggleAuto() {
        if state == .automaticRecognition {
            autoButtonContainer.backgroundColor = UIColor.clear
            recordButton.isEnabled = true
            state = .readyToRecord
        } else {
            autoButtonContainer.backgroundColor = UIColor.flatRed
            recordButton.isEnabled = false
            state = .automaticRecognition
        }
    }
    
    @IBAction func startRecording() {
        recordButton.isEnabled = false
        UIView.animate(withDuration: 0.1) { [unowned self] in
            self.recordingGradientView.isHidden = false
            self.autoButton.isEnabled = false
            self.stopButton.isHidden = false
            self.recordButton.isEnabled = false
            self.recordButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        
        guard state == .readyToRecord else {
            debugPrint("Recording cannot be started.")
            return
        }
        
        state = .recording
        
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
        /* Update UI */
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.recordingGradientView.isHidden = true
            self.autoButton.isEnabled = true
            self.stopButton.isHidden = true
            self.recordButton.isEnabled = true
            self.recordButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        
        /* Stop the recording and get the audio file */
        state = .readyToRecord
        
        micBooster.gain = 0
        tape = recorder.audioFile!
        recorder.stop()
        
        /* Save to the Data Storage */
        DataStorage.audios.append(tape)
        
        /* Segue to the library */
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
        if state == .automaticRecognition {
            toggleAuto()
        }
        
        if state == .recording {
            stopRecording()
        }
        
        /* Transition Animation */
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
        recordButton.isEnabled = true
        try! recorder.reset()
        try! AudioKit.start()
    }
}

