//
//  AppleTranslateHelperView.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2023/4/4.
//  Copyright © 2023 zhaoxin. All rights reserved.
//

import SwiftUI

struct AppleTranslateHelperView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.openURL) private var openURL
    
    @Binding var alwaysShowAppleTranslateHelperAlert:Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("You must have the Xliff Tool Shortcut installed before you continue.")
                .foregroundColor(.blue)
                .font(.title2)
            
            Toggle(NSLocalizedString("Always show this help.", comment: ""), isOn: $alwaysShowAppleTranslateHelperAlert)
            
            HStack {
                Button(NSLocalizedString("Show Me the Steps", comment: "")) {
                    let url = URL(string: "https://github.com/owenzhao/Xliff-Tool/blob/newMaster/Translate.zh-cn.md")!
                    openURL(url)
                }
                
                Button(NSLocalizedString("Close", comment: "")) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
    }
}

struct AppleTranslateHelperView_Previews: PreviewProvider {
    static var previews: some View {
        AppleTranslateHelperView(alwaysShowAppleTranslateHelperAlert: .constant(true))
            .environment(\.locale, Locale(identifier: "en_US"))
            .previewDisplayName("English")
        
        AppleTranslateHelperView(alwaysShowAppleTranslateHelperAlert: .constant(true))
            .environment(\.locale, Locale(identifier: "zh"))
            .previewDisplayName("中文")
    }
}
