//
//  FinishedView.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2022/6/10.
//  Copyright © 2022 zhaoxin. All rights reserved.
//

import SwiftUI

struct FinishedView: View {
    @Environment(\.presentationMode) private var presentationMode
    var body: some View {
        VStack {
            Text("Translation Complete!")
                .font(.title)
            Button("OK") {
                dismiss()
            }
        }
        .padding()
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct FinishedView_Previews: PreviewProvider {
    static var previews: some View {
        FinishedView()
    }
}
