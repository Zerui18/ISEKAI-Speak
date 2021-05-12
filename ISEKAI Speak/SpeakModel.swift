//
//  SpeakModel.swift
//  ISEKAI Speak
//
//  Created by Zerui Chen on 9/4/21.
//

import Foundation
import AVFoundation
import Book_Keeper

enum SpeakVoice: NSInteger {
    case megumin=0, raphtalia=1
}

enum SpeakLanguage: NSInteger {
    case japanese=0
}

fileprivate let audioFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("generated.wav")
fileprivate let resourcesPath = Bundle.main.bundlePath

class SpeakModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    static let shared = SpeakModel()
    
    private let engine: BookKeeper
    private var player: AVAudioPlayer?
    
    @Published var isSpeaking = false
    
    override init() {
        engine = .init(resourcesPath: resourcesPath)
        super.init()
    }
    
    func speak(text: String) {
        player?.stop()
        _ = engine.generateWav(withText: text, atPath: audioFileURL.path)
        player = try? AVAudioPlayer(contentsOf: audioFileURL)
        player?.delegate = self
        player?.play()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == self.player {
            isSpeaking = false
        }
        self.player = nil
    }
    
    func set(voice: SpeakVoice) {
        engine.voice = voice.rawValue
    }
    
    func set(language: SpeakLanguage) {
        engine.language = language.rawValue
    }
    
}
