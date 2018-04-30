//
//  ViewController.swift
//  Music Book
//
//  Created by Sergio on 24.04.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import ChameleonFramework

class ViewController: UIViewController {
    
    @IBOutlet weak var autoButtonContainer: UIView!
    @IBOutlet weak var autoButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    private var autoModeEnabled = false
    private var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func toggleAuto() {
        if autoModeEnabled {
            autoButtonContainer.backgroundColor = UIColor.flatNavyBlue
            recordButton.isEnabled = true
        } else {
            autoButtonContainer.backgroundColor = UIColor.flatRed
            recordButton.isEnabled = false
        }
        
        autoModeEnabled = !autoModeEnabled
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if autoModeEnabled {
            toggleAuto()
        }
    }
    
    @IBAction func rewindToRecordViewController(sender: UIStoryboardSegue) {
    
    }

}

