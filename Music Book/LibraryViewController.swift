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

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    @IBOutlet weak var tableView:   UITableView!
    
    var player:                     AKPlayer!
    var moogLadder:                 AKMoogLadder!
    var delay:                      AKDelay!
    var mainMixer:                  AKMixer!
    
    var indexPathForPlayingRow:     IndexPath?
    var state =                     AKState.noAccess
    
    func audioPlayerDidFinishPlaying() {
        tableView.deselectRow(at: indexPathForPlayingRow!, animated: true)
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
        
        guard DataStorage.audios.count > 0 else {
            return
        }
        
        /* Animate new added recording */
        self.tableView.selectRow(at: IndexPath(row: DataStorage.audios.count - 1, section: 0), animated: true, scrollPosition: UITableViewScrollPosition(rawValue: 0)!)
//        sleep(100)
        self.tableView.deselectRow(at: IndexPath(row: DataStorage.audios.count - 1, section: 0), animated: true)
        self.state = .readyToPlay
        
        if DataStorage.audios.count > 0 {
            player = AKPlayer(audioFile: DataStorage.audios.first!)
        }
        
        player.completionHandler = audioPlayerDidFinishPlaying
        moogLadder = AKMoogLadder(player)
        mainMixer = AKMixer(moogLadder)
        AudioKit.output = mainMixer
        
//        do {
//            try AudioKit.start()
//        } catch {
//            AKLog("Failed to start AudioKit")
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - DZEmptyDataSet
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No Recordings Yet")
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataStorage.audios.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Record Cell", for: indexPath) as! RecordingTableViewCell
        
        cell.title.text = "La meva idea \(indexPath.row + 1)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        indexPathForPlayingRow = indexPath
        
        switch state {
        case .playing:
            player.stop()
        case .readyToPlay:
            player.load(audioFile: DataStorage.audios[indexPath.row])
            player.play()
        default:
            return
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if state == .playing {
            player.stop()
        }
        
//        try! AudioKit.stop()
    }
}
