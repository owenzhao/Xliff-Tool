//
//  FeeSurveyView.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2022/12/9.
//  Copyright © 2022 zhaoxin. All rights reserved.
//

import SwiftUI

struct FeeSurveyView: View {
    @State private var toggleOne = false
    @State private var toggleTwo = false
    @State private var toggleThree = false
    @State private var toggleFour = false
    
    @State private var anotherPlan = ""
    @State private var suggestions = ""
    
    @State private var showPreview = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Section {
                Text("Which plan(s) will you choose if Xliff Tool charges?")
                    .font(.title)
                Toggle("1. One time fee with higher price, say USD14.99.", isOn: $toggleOne)
                Toggle("2. Yearly subscript with lower price, say USD2.99.", isOn: $toggleTwo)
                Toggle("3. The same as 1., but with 3 projects free.", isOn: $toggleThree)
                Toggle("4. The same as 2., but with 3 projects free.", isOn: $toggleFour)
                
                TextField("Another Plan (Optional)", text: $anotherPlan)
                
                Divider()
                
                Text("Suggestions for Xliff Tool")
                    .font(.title2)
                TextEditor(text: $suggestions)
            }
            
            Divider()
            
            Button("Submin") {
                showPreview = true
            }
            .disabled(!(toggleOne||toggleTwo||toggleThree||toggleFour||(!anotherPlan.isEmpty)))
            .sheet(isPresented: $showPreview) {
                SubmitPreviewView(toggleValues: [toggleOne, toggleTwo, toggleThree, toggleFour],
                                  anotherPlan: anotherPlan, suggestions: suggestions)
            }
        }
        .padding()
        .font(.title3)
    }
}

struct FeeSurveyView_Previews: PreviewProvider {
    static var previews: some View {
        FeeSurveyView()
    }
}
