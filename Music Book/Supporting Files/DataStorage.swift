//
//  DataStorage.swift
//  Music Book
//
//  Created by Sergio on 03.05.2018.
//  Copyright © 2018 Sergi Popov. All rights reserved.
//

import Foundation
import AudioKit

class DataStorage {
    static var applicationHasMicrophoneAccess = false
    static var audios: [AKAudioFile] = []
    static var notes: [[(Pitch, Double)]] = []
}
