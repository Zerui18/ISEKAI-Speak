//
//  ContentView.swift
//  ISEKAI Speak
//
//  Created by Zerui Chen on 9/4/21.
//

import SwiftUI

struct ContentView: View {
    
    @State var text = ""
    @EnvironmentObject var model: SpeakModel
    
    @State var selectedVoice: Int = 0
    @State var selectedLanguage: Int = 0
    
    let voiceNames = ["megumin", "raphtalia"]
    let languageNames = ["japanese"]
    
    init() {
        UITextView.appearance().backgroundColor = .clear
        UITextView.appearance().textContainerInset = .init(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    var body: some View {
        VStack {
            
            HStack {
                Picker(selection: $selectedVoice, label: Text("Voice")) {
                    ForEach(0...1, id: \.self) { i in
                        Text(voiceNames[i])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedVoice) { value in
                    model.set(voice: SpeakVoice(rawValue: value)!)
                }
                
                Spacer()
                
                Picker(selection: $selectedLanguage, label: Text("Language")) {
                    ForEach(0...0, id: \.self) { i in
                        Text(languageNames[i])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedLanguage) { value in
                    model.set(language: SpeakLanguage(rawValue: value)!)
                }
            }
            .padding(.bottom)
            
            TextEditor(text: $text)
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(
                    Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.bottom, 30)
            
            Button("Speak") {
                model.speak(text: text)
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color(.label))
            .padding([.leading, .trailing], 20)
            .padding([.top, .bottom], 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
