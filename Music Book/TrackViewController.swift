//
//  TrackViewController.swift
//  Music Book
//
//  Created by Sergio on 28/05/18.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI

class TrackViewController: UIViewController, UITextFieldDelegate, PlayerDelegate, AnalyzerDelegate {

    // MARK: - Outlets
    
    @IBOutlet weak var titleLabel: UITextField!
//    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var sonogram: EZAudioPlot!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    
    // MARK: - Interanl Variables
        
    let audioManager = AudioManager.shared
    var audioFile: AKAudioFile!
    var audioFileIndex: Int!
    var trackTitle: String?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        titleLabel.text = trackTitle
        
//        durationLabel.text = String(format: "%d:%.02d", audioFile.duration / 60, audioFile.duration.truncatingRemainder(dividingBy: 60))
        
        sonogram.backgroundColor = .clear
        sonogram.color = .flatWhite
        sonogram.shouldOptimizeForRealtimePlot = false
        sonogram.plotType = .buffer // addDurationOfFileWith(url: DataStorage.audios[indexPath.row].url)
        sonogram.shouldFill = true
        sonogram.shouldMirror = true
        
        if let audioFile = EZAudioFile(url: audioFile.url), let waweFormData = audioFile.getWaveformData() {
            sonogram.updateBuffer(waweFormData.buffers[0], withBufferSize: waweFormData.bufferSize)
        }
        
//        notesTextView.text = String(describing: DataStorage.notes[audioFileIndex])
        
        titleLabel.delegate = self
        
        audioManager.player.delegate = self
        audioManager.analyzer.delegate = self
        
        audioManager.analyzer.analyze(audio: audioFile)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Analyzer Delegate
    
    func analyzerDidFinishAnalyzing(track: AKAudioFile, result: [(Pitch, Double)], discreteFactor: Double) {
        loadingView.isHidden = true
        for tick in result {
            notesTextView.text.append("\(tick.0.description) \n")
        }
    }
    
    // MARK: - Player Delegate
    
    func playerDidFinishPlaying() {
        
    }
    
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, reachedEndOf audioFile: EZAudioFile!) {
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.image = UIImage(named: "Play")
        audioManager.state = .ready
    }
    
    // MARK: - Text Fied Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func togglePlayButton(_ sender: Any) {
        if audioManager.state == .playing {
            playButton.image = UIImage(named: "Play")
            audioManager.player.stopPlaying()
        } else {
            playButton.image = UIImage(named: "Pause")
            audioManager.player.play(tape: audioFile)
        }
    }
    
    @IBAction func removeTrack(_ sender: Any) {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Delete \(titleLabel.text ?? "Track")", style: .destructive, handler: { _ in
            self.dismiss(animated: true, completion: {
                DataStorage.audios.remove(at: self.audioFileIndex)
            })
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }
    
    @IBAction func exportTrack(_ sender: Any) {
    }
    
    // MARK: - Navigation
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
