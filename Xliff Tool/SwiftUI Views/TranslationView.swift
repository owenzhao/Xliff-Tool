//
//  TranslationView.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2023/4/3.
//  Copyright © 2023 zhaoxin. All rights reserved.
//

import SwiftUI
import Defaults

struct TranslationView: View {
    @Environment(\.openURL) private var openURL
    
    @Default(.alwaysShowAppleTranslateHelperAlert) private var alwaysShowAppleTranslateHelperAlert
    
    @State private var showAppleTranslateHelperAlert = false
    
    @State var source:String = ""
    @State var target:String = ""
    
    @State private var stopTimer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if #available(macOS 12, *) {
                Text(source)
                    .foregroundColor(.blue)
                    .textSelection(.enabled)
            } else {
                Text(source)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(NSLocalizedString("Target", comment: ""))
                    .foregroundColor(.green)
                TextEditor(text: $target)
                    .foregroundColor(.green)
            }
            
            HStack {
                Button(NSLocalizedString("Use Translation", comment: "")) {
                    NotificationCenter.default.post(name: .useTranslation, object: self, userInfo: ["target": target])
                }
                .padding(10)
                .frame(width: 200, height: 30)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(12)
                
                
                Button("Cancel") {
                    NotificationCenter.default.post(name: .cancelTranslation, object: self)
                }
                .padding(10)
                .frame(width: 200, height: 30)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(12)
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button {
                    let url = URL(string: "https://github.com/owenzhao/Xliff-Tool/blob/newMaster/Translate.zh-cn.md")!
                    openURL(url)
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue.opacity(0.5))
                }
            }
            .buttonStyle(.borderless)
        }
        .font(.title2)
        .padding()
        .onAppear(perform: prepareShortCut)
        .onAppear {
            if alwaysShowAppleTranslateHelperAlert {
                showAppleTranslateHelperAlert = true
            } else {
                prepareShortCut()
            }
        }
        .onDisappear {
            stopTimer = true
        }
        .onChange(of: showAppleTranslateHelperAlert) { newValue in
            if newValue == false {
                prepareShortCut()
            }
        }
        .sheet(isPresented: $showAppleTranslateHelperAlert) {
            AppleTranslateHelperView(alwaysShowAppleTranslateHelperAlert: $alwaysShowAppleTranslateHelperAlert)
        }
    }
    
    private func prepareShortCut() {
        let pb = NSPasteboard.general
        pb.clearContents()
        print(pb.setString(source, forType: .string))
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if stopTimer {
                timer.invalidate()
                print("Timer stopped by stopTimer.")
                return
            }
            
            if let target = pb.string(forType: .string), !target.isEmpty && target != source {
                self.target = target
                timer.invalidate()
                print("Timer stopped as transation finished.")
            }
        }
    }
}

struct TranslationView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationView(source: "I am a test.", target: "I am a test.")
    }
}
