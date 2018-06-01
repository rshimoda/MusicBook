//
//  State.swift
//  Music Book
//
//  Created by Sergio on 21/5/18.
//  Copyright © 2018 Sergio. All rights reserved.
//

enum AKState {
    case ready
    case readyToTune
    case tuning
    case detectingNoise
    case readyToRecord
    case recording
    case readyToPlay
    case playing
    case paused
}
