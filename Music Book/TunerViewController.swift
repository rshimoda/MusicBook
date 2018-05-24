//
//  TunerViewController.swift
//  Music Book
//
//  Created by Sergio on 01.05.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import AudioKit

class TunerViewController: UIViewController, TunerDelegate {

    @IBOutlet weak var noteSign:        UILabel!
    @IBOutlet weak var accuracyScale:   UIView!
    @IBOutlet weak var accuracyView:    UIView!
  
    @IBOutlet weak var leading:         NSLayoutConstraint! // +
    @IBOutlet weak var trailing:        NSLayoutConstraint! // -
    @IBOutlet weak var rightPane:       UIView!
    @IBOutlet weak var leftPane:        UIView!
    
    let tuner = Tuner()
    
    var width: Float {
        return Float(accuracyScale.bounds.width)
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tuner.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tuner.startMonitoring()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        tuner.stopMonitoring()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Tuner Delegate
    
    func tunerDidMeasure(pitch: Pitch, distance: Double, amplitude: Double) {
        // Too Quiet
        if amplitude < 0.1 && (noteSign.text ?? "") != pitch.note.description {
            UIView.animate(withDuration: 0.1, animations: { [unowned self] in
                self.accuracyView.frame.size.width = CGFloat(self.width / 2) + 1
                self.leftPane.frame.size.width = CGFloat(self.width / 2)
            }, completion: { [unowned self] isCompleted  in
                self.noteSign.isHidden = true
                self.accuracyView.isHidden = true
            })
            return
        }
        
        accuracyView.isHidden = false
        noteSign.isHidden = false
        noteSign.text = "\(pitch.note.description)"
        
        if distance > 0 {
            if accuracyView.frame.size.width > CGFloat(width / 2) {
                UIView.animate(withDuration: 0.3) { [unowned self] in
                    self.accuracyView.frame.size.width = CGFloat(self.width / 2) + CGFloat(min(abs(distance) * Double(self.width) / 4.0, Double(self.width / 2)))
                }
            } else {
                UIView.animate(withDuration: 0.15, animations: { [unowned self] in
                    self.leftPane.frame.size.width = CGFloat(self.width / 2)
                }, completion: { [unowned self] (isFinished) in
                    UIView.animate(withDuration: 0.15) { [unowned self] in
                        self.accuracyView.frame.size.width = CGFloat(self.width / 2) + CGFloat(min(abs(distance) * Double(self.width) / 4.0, Double(self.width / 2)))
                    }
                })
            }
        } else {
            if accuracyView.frame.size.width > CGFloat(width / 2) {
                UIView.animate(withDuration: 0.15, animations: { [unowned self] in
                    self.accuracyView.frame.size.width = CGFloat(self.width / 2)
                    }, completion: { [unowned self] (isFinished) in
                        UIView.animate(withDuration: 0.15) { [unowned self] in
                            self.leftPane.frame.size.width = CGFloat(self.width / 2) - CGFloat(min(abs(distance) * Double(self.width) / 4, Double(self.width / 2)))
                        }
                })
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.leftPane.frame.size.width = CGFloat(self.width / 2) - CGFloat(min(abs(distance) * Double(self.width) / 4, Double(self.width / 2)))
                }
            }
        }

        if abs(distance) >= 1 {
            self.noteSign.textColor = UIColor.flatRedDark
            self.accuracyView.backgroundColor = UIColor.flatRedDark
        } else {
            self.noteSign.textColor = UIColor.flatMintDark
            self.accuracyView.backgroundColor = UIColor.flatMintDark
        }
    }
}
