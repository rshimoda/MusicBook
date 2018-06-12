//
//  RecordingTableViewCell.swift
//  Music Book
//
//  Created by Sergio on 03.05.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import AudioKitUI

class RecordingTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UITextField!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var sonogram: EZAudioPlot!
    
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    var isExpanded = false {
        didSet {
            title.isEnabled = !oldValue
            bottomView.isHidden = oldValue
        }
    }
    
    var audioFile: AKAudioFile!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
