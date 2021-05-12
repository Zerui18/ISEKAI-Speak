//
//  ISEKAI_SpeakApp.swift
//  ISEKAI Speak
//
//  Created by Zerui Chen on 9/4/21.
//

import SwiftUI
import AVFoundation

@main
struct ISEKAI_SpeakApp: App {
    
    init() {
        try! AVAudioSession.sharedInstance().setCategory(.playback)
        try! AVAudioSession.sharedInstance().setActive(true, options: [])
    }
    
    @State var model = SpeakModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
