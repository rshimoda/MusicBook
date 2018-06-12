//
//  TunerViewController.swift
//  Music Book
//
//  Created by Sergio on 01.05.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import Sugar

class TunerViewController: UIViewController, TunerDelegate, NoiseEvaluatorUIDelegate {
    @IBOutlet weak var noteSign:                    UILabel!
    @IBOutlet weak var noiseLevelDetectionLabel:    UILabel!
    @IBOutlet weak var accuracyScale:               UIView!
    @IBOutlet weak var accuracyView:                UIView!
    
    @IBOutlet weak var leftPane: UIView!
    @IBOutlet weak var rightPane: UIView!
    
    var maxWidthForAccuracyView: Double {
        return Double(accuracyScale.frame.size.width)
    }
    
    var isInPositivePosition: Bool {
        return leftPane.isHidden
    }
    
    var noiseDetectionLabelAnimationTimer: Timer?
    
    // MARK: - Audio Manager
    
    let audioManager = AudioManager.shared
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager.tuner.delegate = self
        audioManager.noiseEvaluator.delegate = self
        
        audioManager.noiseEvaluator.startMeasuringNoiseLevel(for: 3.0)
//        audioManager.tuner.start()
        
//        self.accuracyView.isHidden = false
//        UIView.animate(withDuration: 3, animations: {
//            self.accuracyView.transform = CGAffineTransform(scaleX: self.accuracyScale.frame.size.width, y: 1)
//        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioManager.tuner.stop()
    }
    
    // MARK: - Noise Evaluator Delegate
    
    func noiseEvaluatorWillStartMeasuring(duration: TimeInterval) {
        audioManager.tuner.stop()
        
        self.noiseLevelDetectionLabel.isHidden = false
        
        noiseDetectionLabelAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true, block: { _ in
            UIView.animate(withDuration: 0.6, animations: {
                self.noiseLevelDetectionLabel.alpha = self.noiseLevelDetectionLabel.alpha == 1.0 ? 0.3 : 1.0
            })
        })
//        translateAccuracyView(animationDuration: duration, translateX: maxWidthForAccuracyView)
    }
    
    func noiseEvaluatorDidFinishMeasuring() {
        noiseDetectionLabelAnimationTimer?.invalidate()
        
        self.noiseLevelDetectionLabel.isHidden = true

        audioManager.tuner.start()
    }
    
    // MARK: - Tuner Delegate
    
    func tunerDidMeasure(pitch: Pitch, distance: Double, amplitude: Double) {
        
        // Too Quiet
        let animationDuration = 0.3

        guard amplitude > audioManager.noiseEvaluator.threshold && pitch.frequency > 90 else { // && (noteSign.text ?? "") != pitch.note.description {
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
    
    func translateAccuracyView(animationDuration: Double, translateX: Double, completion: (() -> ())? = nil) {
        UIView.animate(withDuration: animationDuration, animations: {
            /* Animate width */
            self.accuracyView.transform = CGAffineTransform(scaleX: CGFloat(translateX), y: 1)
        }, completion: { _ in
            completion?()
        })
    }
}
