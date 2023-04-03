//
//  SubmitPreviewView.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2022/12/9.
//  Copyright © 2022 zhaoxin. All rights reserved.
//

import SwiftUI

struct SubmitPreviewView: View {
    @State var toggleValues:[Bool]
    @State var anotherPlan:String
    @State var suggestions:String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(getSubmitString())
                .font(.title3)
                .foregroundColor(.blue)
            
            HStack {
                Button("Send by Email") {
                    
                }
                
                Button("Send by Twitter") {
                    
                }
            }
        }
        .padding()
    }
    
    private func getSubmitString() -> String {
        var result = ""
        result += toggleValues.reduce("Plans: ", { partialResult, toggleValue in
            partialResult + (toggleValue ? "1" : "0") + ","
        })
        result += "\n"
        result += "Another Plan: \(anotherPlan)\n"
        result += "Suggestions: \(suggestions)"
        
        return result
    }
}

struct SubmitPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        SubmitPreviewView(toggleValues: [true, false, false, false],
                          anotherPlan: "",
                          suggestions: "")
    }
}
