//
//  TunerViewController.swift
//  Music Book
//
//  Created by Sergio on 01.05.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import Sugar

class TunerViewController: UIViewController, TunerDelegate {
    
    @IBOutlet weak var noteSign:                    UILabel!
    @IBOutlet weak var noiseLevelDetectionLabel:    UILabel!
    @IBOutlet weak var accuracyScale:               UIView!
    @IBOutlet weak var accuracyView:                UIView!
    
    @IBOutlet weak var leftPane: UIView!
    @IBOutlet weak var rightPane: UIView!
    
    /* When active accuracyView grows to RIGHT (POSITIVE) direction */
    /* Priority: 1000 */
    /* To change direction toggle .isInstalled property */
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    /* When active accuracyView grows to LEFT (NEGATIVE) direction */
    /* Priority: 999 */
    @IBOutlet var trailingConstraint: NSLayoutConstraint!
    
    
    var maxWidthForAccuracyView: Double {
        return Double(accuracyScale.frame.size.width)
    }
    
    var isInPositivePosition: Bool {
        return leftPane.isHidden
    }
    
    // MARK: - Audio Manager
    
    let audioManager = AudioManager.shared
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager.tunerDelegate = self
        audioManager.startTuning()
        
//        self.accuracyView.isHidden = false
//        UIView.animate(withDuration: 3, animations: {
//            self.accuracyView.transform = CGAffineTransform(scaleX: self.accuracyScale.frame.size.width, y: 1)
//        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioManager.startMeasuringNoiseLevel(during: 3.0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioManager.stopTuning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Tuner Delegate
    
    func tunerWillMeasureNoiseLevel(duration: TimeInterval) {
        accuracyView.isHidden = true
        noiseLevelDetectionLabel.isHidden = false
        audioManager.stopTuning()
    }
    
    func tunerDidMeasureNoiseLevel(noise: Double) {
        noiseLevelDetectionLabel.isHidden = true
        audioManager.startTuning()
    }
    
    func tunerDidMeasure(pitch: Pitch, distance: Double, amplitude: Double) {
        
        // Too Quiet
        let animationDuration = 0.3

        guard amplitude > audioManager.threshold && pitch.frequency > 90 else { // && (noteSign.text ?? "") != pitch.note.description {
            UIView.animate(withDuration: animationDuration, animations: { [unowned self] in
                self.accuracyView.frame.size.width = 1
                }, completion: { [unowned self] isCompleted  in
                    self.noteSign.isHidden = true
                    self.accuracyView.isHidden = true
            })
            return
        }
        
        self.accuracyView.isHidden = false
        
        /* Accuracy rate in percents */
        guard let currectPitchIndex = Pitch.all.index(where: {$0.frequency == pitch.frequency}) else {
            return
        }
        let closestPitchIndex = -distance > 0 ? min(currectPitchIndex + 1, Pitch.all.count - 1) : max(currectPitchIndex - 1, 0)
        let closestPitch = Pitch.all[closestPitchIndex]
        let accuracyRate = min(max(100 - (abs(distance) * 100 / abs(pitch.frequency - closestPitch.frequency)), 0), 100)
        let cgAffineTranslateX = maxWidthForAccuracyView * ((100 - accuracyRate) / 100)
        
        if accuracyRate > 90 {
            self.accuracyView.backgroundColor = .flatMintDark
            self.noteSign.textColor = .flatMintDark
        } else {
            self.accuracyView.backgroundColor = .flatRedDark
            self.noteSign.textColor = .flatRedDark
        }
        
        /* UI Change */
        
        /* Direction of accuracyView has changed - needs to be set to zero before further scaling */
        if self.isInPositivePosition != (distance > 0) {
            UIView.animate(withDuration: animationDuration / 2, animations: { [unowned self] in
                self.accuracyView.transform = .identity
                }, completion: { _ in
                    self.rightPane.isHidden = distance <= 0
                    self.leftPane.isHidden = distance >= 0
                    self.translateAccuracyView(animationDuration: animationDuration / 2, translateX: cgAffineTranslateX) {
                        self.accuracyView.layoutIfNeeded()
                        self.noteSign.isHidden = false
                        self.noteSign.text = "\(pitch.note.description)"
                    }
            })
            
        /* Direction is left the same */
        } else {
            translateAccuracyView(animationDuration: animationDuration, translateX: cgAffineTranslateX) {
                self.accuracyView.layoutIfNeeded()
                self.noteSign.isHidden = false
                self.noteSign.text = "\(pitch.note.description)"
            }
        }
    }
    
    func translateAccuracyView(animationDuration: Double, translateX: Double, completion: (() -> ())?) {
        UIView.animate(withDuration: animationDuration, animations: {
            /* Animate width */
            self.accuracyView.transform = CGAffineTransform(scaleX: CGFloat(translateX), y: 1)
        }, completion: { _ in
            completion?()
        })
    }
}
