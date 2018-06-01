//
//  ViewController.swift
//  Music Book
//
//  Created by Sergio on 24.04.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import Hero
import AudioKitUI
import ChameleonFramework

class ViewController: UIViewController, RecorderDelegate {
    
    var isAutoModeEnabled =                     false
    
    // MARK: - Outlets
    
    @IBOutlet weak var gradientView:            MKGradientView!
    @IBOutlet weak var recordingGradientView:   MKGradientView!
    @IBOutlet weak var audioPlot:               EZAudioPlot!
    @IBOutlet weak var autoButtonContainer:     UIView!
    @IBOutlet weak var autoButton:              UIButton!
    @IBOutlet weak var recordButton:            UIButton!
    @IBOutlet weak var stopButton:              UIButton!
    @IBOutlet weak var tunnerButton:            UIButton!
    @IBOutlet weak var libraryButton:           UIButton!
    
    var stopButtonCornerRadiusIdentity:         CGFloat!
    
    // MARK: - Audio Manager
    
    let audioManager =                          AudioManager.shared
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager.recorderDelegate = self
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioManager.stopRecording()
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
        })
        
        stopButton.layer.masksToBounds = true
        stopButton.layer.cornerRadius = stopButton.frame.size.width / 2
        stopButtonCornerRadiusIdentity = stopButton.layer.cornerRadius
        
        let plot = AKNodeOutputPlot(audioManager.mic, frame: audioPlot.bounds)
        plot.plotType = .rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = .flatWhite
        plot.backgroundColor = .clear
        audioPlot.addSubview(plot)
    }
    
    // MARK: - Actions
    
    @IBAction func toggleAuto() {
        if isAutoModeEnabled {
            autoButtonContainer.backgroundColor = UIColor.clear
            recordButton.isEnabled = true
            audioPlot.isHidden = true
        } else {
            autoButtonContainer.backgroundColor = UIColor.flatRed
            recordButton.isEnabled = false
            audioPlot.isHidden = false
        }
        isAutoModeEnabled = !isAutoModeEnabled
    }
    
    @IBAction func toggleRecord() {
        if audioManager.state == .recording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        /* Update UI */
        self.audioPlot.isHidden = false
        self.audioPlot.resetHistoryBuffers()
        
        self.recordingGradientView.isHidden = false
        
        self.autoButton.isEnabled = false
        
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.recordButton.isEnabled = false
            self.recordButton.transform = .identity

            self.stopButton.backgroundColor = UIColor(hexString: "FF2242") // .flatRed
            self.stopButton.layer.cornerRadius = 5
            self.stopButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }
        
        audioManager.startRecording()
    }
    
    func stopRecording() {
        /* Update UI */
        UIView.animate(withDuration: 0.3,
                       animations: { [unowned self] in
                        self.audioPlot.isHidden = true
                        
                        self.recordingGradientView.isHidden = true
                        
                        self.autoButton.isEnabled = true
                        
//                        self.recordButton.isEnabled = false
                        self.recordButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                        
                        self.stopButton.backgroundColor = UIColor(red: 0.17, green: 0.3, blue: 0.46, alpha: 1)
                        self.stopButton.layer.cornerRadius = self.stopButtonCornerRadiusIdentity
                        self.stopButton.transform = .identity
                        
            },
                       completion: { [unowned self] _ in
                        self.stopButton.isEnabled = false
                        self.audioManager.stopRecording()
        })
    }
    
    // MARK: - Recorder Delegate
    
    func recorderWillStartRecording() {
        
    }
    
    func recorderDidFinishRecording(successfully: Bool, tape: AKAudioFile?) {
        guard successfully else {
            return
        }
        
        /* Save to the Data Storage */
        DataStorage.audios.append(tape!)
        
        /* Segue to the library */
        performSegue(withIdentifier: "Open Library", sender: self)
    }
    
    // MARK: - Helpers
    
    func formattedCurrentTime(time: UInt) -> String {
        let hours = time / 3600
        let minutes = (time / 60) % 60
        let seconds = time % 60
        
        return String(format: "%02i:%02i:%02i", arguments: [hours, minutes, seconds])
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
        stopButton.isEnabled = true
        autoButton.isEnabled = true

    }
}

