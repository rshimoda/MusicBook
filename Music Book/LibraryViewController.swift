//
//  LibraryViewController.swift
//  Music Book
//
//  Created by Sergio on 03.05.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import AudioKit
import DZNEmptyDataSet
import Sugar
import ChameleonFramework

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UITextFieldDelegate, PlayerDelegate {
    
    @IBOutlet weak var tableView:   UITableView!
    
    var progressTimer: Timer?
    
    let audioManager =              AudioManager.shared
    var selectedRow:                IndexPath? {
        didSet {
            /* Collapse previously choosen cell */
            if let _ = oldValue {
                (tableView.cellForRow(at: oldValue!) as! RecordingTableViewCell).isExpanded = false
            }
        }
    }
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Table View */
        tableView.tableFooterView = UIView(frame: .zero)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        
        self.hideKeyboardWhenTappedAround()
//        self.deselectAllWhenTappedAround()
        
        guard DataStorage.audios.count > 0 else {
            return
        }
        
        audioManager.player.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if DataStorage.audios.count != tableView.numberOfRows(inSection: 0) {
            tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if audioManager.state == .playing || audioManager.state == .paused {
            audioManager.player.stopPlaying()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - EZAudioPlayer Delegate
    
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, reachedEndOf audioFile: EZAudioFile!) {
        dispatch {
            let cell = (self.tableView.cellForRow(at: self.selectedRow!) as! RecordingTableViewCell)
            cell.playButton.setImage(UIImage(named: "Play"), for: .normal)
            cell.playButton.setImage(UIImage(named: "Play-Highlighted"), for: .highlighted)
            cell.playButton.setImage(UIImage(named: "Play-Disabled"), for: .disabled)
        }
    }
    
    // MARK: - AVFoundation Player Delegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        (tableView.cellForRow(at: selectedRow!) as! RecordingTableViewCell).playButton.setImage(UIImage(named: "Play"), for: .normal)
        audioManager.state = .ready
    }
    
    // MARK: - Actions
    
    @IBAction func play(_ sender: UIButton) {
        switch audioManager.state {
        case .ready, .paused:
            if let selectedIndex = selectedRow?.row {
                sender.setImage(UIImage(named: "Pause"), for: .normal)
                
                if audioManager.state == .ready {
                    let tape = DataStorage.audios[selectedIndex].audioFile
                    audioManager.player.play(tape: tape)
                    
                    let cell = self.tableView.cellForRow(at: self.selectedRow!) as! RecordingTableViewCell
                    UIView.animate(withDuration: 0.1, animations: {
                        cell.playbackProgressView.transform = CGAffineTransform(translationX: -cell.sonogram.frame.size.width, y: 0)
                    })
                } else {
                    audioManager.player.resumePlaying()
                }
            }
        case .playing:
            sender.setImage(UIImage(named: "Play"), for: .normal)
//            sender.setImage(UIImage(named: "Play-Highlighted"), for: .highlighted)
//            sender.setImage(UIImage(named: "Play-Disabled"), for: .disabled)
            
            audioManager.player.pausePlaying()
        default:
            return
        }
    }
    
    // MARK: - Player Delegate
    
    func playerDidCompleteTrack(for percent: Double) {
        let cell = tableView.cellForRow(at: selectedRow!) as! RecordingTableViewCell
        UIView.animate(withDuration: 0.1, animations: {
            cell.playbackProgressView.transform = CGAffineTransform(translationX: (cell.sonogram.frame.size.width * CGFloat(percent) / 100) - cell.sonogram.frame.size.width, y: 0)
        })
    }
    
    func playerDidFinishPlaying() {
        audioManager.player.stopPlaying()
        let cell = tableView.cellForRow(at: selectedRow!) as! RecordingTableViewCell
        cell.playbackProgressView.isHidden = true
    }
    
    // MARK: - Text Fiel Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text {
            DataStorage.audios[selectedRow!.row].name = text
        }
        return true
    }
    
    // MARK: - DZEmptyDataSet
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No Recordings Yet")
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selected = self.selectedRow {
            if selected == indexPath {
                return 120.0
            }
        }
        
        return 64.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataStorage.audios.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Record Cell", for: indexPath) as! RecordingTableViewCell
        
        cell.title.text = DataStorage.audios[indexPath.row].name
        cell.title.delegate = self
        
        let duration = Int(DataStorage.audios[indexPath.row].audioFile.duration)
        cell.duration.text = String(format: "%d:%.02d", duration / 60, duration % 60)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        cell.date.text = dateFormatter.string(from: DataStorage.audios[indexPath.row].creationDate)
        

        cell.sonogram.backgroundColor = .clear
        cell.sonogram.color = .flatWhite
        cell.sonogram.gain = 1.5
        cell.sonogram.shouldOptimizeForRealtimePlot = false
        cell.sonogram.plotType = .buffer // addDurationOfFileWith(url: DataStorage.audios[indexPath.row].url)
        cell.sonogram.shouldFill = true
        cell.sonogram.shouldMirror = true
        
        if let audioFile = EZAudioFile(url: DataStorage.audios[indexPath.row].audioFile.url), let waweFormData = audioFile.getWaveformData() {
            cell.sonogram.updateBuffer(waweFormData.buffers[0], withBufferSize: waweFormData.bufferSize)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if selectedRow == indexPath {
            performSegue(withIdentifier: "Open Track", sender: self)
        } else {
            selectedRow = indexPath
            
            (tableView.cellForRow(at: indexPath) as! RecordingTableViewCell).isExpanded = true
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            DataStorage.audios.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueName = segue.identifier {
            if segueName == "Open Track" {
                if let destination = (segue.destination as! UINavigationController).viewControllers.first as? TrackViewController {
                    destination.trackTitle = (tableView.cellForRow(at: selectedRow!) as! RecordingTableViewCell).title.text ?? " "
                    destination.recording = DataStorage.audios[selectedRow!.row]
                    destination.audioFileIndex = selectedRow!.row
                    
                    destination.navigationController?.navigationBar.backgroundColor = UIColor.flatNavyBlueDark
                    
                    destination.hero.isEnabled = true
//                    destination.hero.modalAnimationType = .selectBy(presenting: .zoomSlide(direction: .left), dismissing: .auto)
                }
            }
        }
    }
}
