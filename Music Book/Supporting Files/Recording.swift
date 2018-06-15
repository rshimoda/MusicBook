//
//  Recording.swift
//  Music Book
//
//  Created by Sergio on 14.06.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import Foundation
import AudioKit

enum MusicalNote {
    case note(pitch: Pitch)
    case pause
}

class Recording {
    var name: String
    var creationDate: Date
    var audioFile: AKAudioFile
    var notes: [Pitch?]!
    var amplitudes: [Double]!
    
    init(name: String, created: Date = Date(), audioFile: AKAudioFile) {
        self.name = name
        self.creationDate = created
        self.audioFile = audioFile
    }
}
