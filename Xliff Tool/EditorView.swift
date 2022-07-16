//
//  EditorView.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2022/6/8.
//  Copyright © 2022 zhaoxin. All rights reserved.
//

import SwiftUI
import RealmSwift

struct EditorView: View {
    static let transUnitDidChanged = Notification.Name("transUnitDidChanged")
    static let editChanged = Notification.Name("editChanged")
    
    @ObservedResults(RLMXTTransUnit.self) var transUnits
    @ObservedResults(RLMXTFile.self) var files
    
    /// transUnit should treat in Swift way
    @State var transUnit = RLMXTTransUnit()
    @State var isEdited = false
    @State var finished = false
    
    private let selectionDidChangePublisher = NotificationCenter.default.publisher(for: NSOutlineView.selectionDidChangeNotification)
    
    private var total:Int {
        transUnits.count
    }
    private var translated:Int {
        transUnits
            .filter("(target != nil AND target != '') OR (allowEmptyTarget == true)")
            .count
    }
    private var verified:Int {
        transUnits
            .filter("isVerified = true")
            .count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(transUnit.id.isEmpty ? "ID" : transUnit.id)
                    .font(.title2)
                
                Spacer()
                
                HStack {
                    Text(String.localizedStringWithFormat(NSLocalizedString("Translated: %d/%d", comment: ""), translated, total))
                    Text(String.localizedStringWithFormat(NSLocalizedString("Verified: %d/%d", comment: ""), verified, total))
                    
                    if total != 0 {
                        Text(String(format: NSLocalizedString("Progress: %.2f%%", comment: ""), Double(verified) / Double(total) * 100.0))
                    } else {
                        Text("Progress: 0.00%")
                    }
                }
            }
            
            Text(transUnit.source.isEmpty ? "Source" : transUnit.source)
                .foregroundColor(.init("sourceColor"))
                .font(.title2)
            
            HStack(alignment: .bottom) {
                Text("Target")
                    .foregroundColor(.init("targetColor"))
                    .font(.title2)
                
                Spacer()
                
                Button("Open Bing Translator") {
                    openBingTranslatorButtonClicked()
                }
                
                Button("Open Google Translate") {
                    openGoolgeTranslateButtonClicked()
                }
            }
            
            TextEditor(text: Binding(get: {
                return transUnit.target ?? ""
            }, set: { newValue in
                transUnit.target = getXliffAllowedString(from: newValue)
                isEdited = true
                transUnit.isVerified = false
                NotificationCenter.default.post(name: EditorView.editChanged, object: self)
            }))
            .font(.title2)
            .foregroundColor(.init("targetColor"))
            .disabled(transUnit.id.isEmpty)
            
            
            Toggle("Allow Empty Target", isOn: $transUnit.allowEmptyTarget)
                .toggleStyle(.checkbox)
            
            HStack {
                Text(transUnit.note ?? "Note")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Button("Copy Note ObjectID") {
                    copyNoteObjectIDButtonClicked()
                }
                .disabled(!hasObjectID())
                
                Spacer()
            }
            
            HStack {
                Spacer()
   
                Button("Verify") {
                    verifyButtonClicked()
                }
                .keyboardShortcut(KeyEquivalent.return, modifiers: .command)
                .disabled(!enableVerifyButton())
                
                Text("⌘ + ⏎")
                    .font(.callout)
            }
        }
        .padding()
        .frame(minWidth: 750, minHeight: 520)
        .onAppear(perform: {
            updateUI()
        })
        .onReceive(selectionDidChangePublisher) { notification in
            if let outlineView = notification.object as? NSOutlineView {
                let row = outlineView.selectedRow
                let item = outlineView.item(atRow: row)
                
                if let file = item as? RLMXTFile {
                    debugPrint(file.original)
                } else if let transUnit = item as? RLMXTTransUnit {
                    self.transUnit = transUnit.unManagedInstance()
                } else {
                   debugPrint("")
                }
            }
        }
        .sheet(isPresented: $finished) {
            FinishedView()
        }
    }
    
//    MARK: - open translations
    private func openBingTranslatorButtonClicked() {
        let webString = "https://cn.bing.com/translator/?text="
        openTranslationWebSite(webString)
    }
    
    private func openGoolgeTranslateButtonClicked() {
        let webString = "https://translate.google.com/?client=tw-ob#auto/auto/"
        openTranslationWebSite(webString)
    }
    
    private func openTranslationWebSite(_ webString:String) {
        let source = transUnit.source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        NSWorkspace.shared.open(URL(string: webString + source)!)
    }
    
//    MARK: -
    private func copyNoteObjectIDButtonClicked() {
        let pb = NSPasteboard.general
        let note = transUnit.note!
        let objectIdString = "ObjectID"
        let range = note.range(of: objectIdString, options: .backwards, range: note.startIndex..<note.endIndex)
        let components = note[range!.lowerBound...].components(separatedBy: "\"")
        pb.clearContents()
        pb.setString(components[1], forType: .string)
    }
    
    private func hasObjectID() -> Bool {
        let objectIdString = "ObjectID"
        return transUnit.note?.contains(objectIdString) ?? false
    }
    
    private func enableVerifyButton() -> Bool {
        guard !transUnit.isVerified else {
            return false
        }
        
        guard !transUnit.id.isEmpty else {
            return false
        }
        
        if transUnit.allowEmptyTarget {
            return true
        }
        
        return transUnit.target?.isEmpty == false
    }
    
    private func verifyButtonClicked() {
        transUnit.isVerified = true
        $transUnits.append(transUnit)
        isEdited = false
        updateUI()
    }
    
    private func nextTransUnit() -> RLMXTTransUnit? {
        var results = transUnits.filter("isVerified = false")
        let defaults = UserDefaults.standard
        let verifyTranslatedResultsFirst = (defaults.integer(forKey: UserDefaults.Key.verifyTranslatedResultsFirst.rawValue) == NSControl.StateValue.on.rawValue)

        if verifyTranslatedResultsFirst {
            let translatedResults = results.filter("(target != nil AND target != '') OR (allowEmptyTarget == true)")

            if !translatedResults.isEmpty {
                results = translatedResults
            }
        }
        
        let result = results.first

        return result?.unManagedInstance()
    }
    
    func updateUI() {
        var uid:String? = nil
        if let transUnit = nextTransUnit() {
            self.transUnit = transUnit
            uid = transUnit.uid
        } else {
            self.transUnit = RLMXTTransUnit()
            self.finished = true
            NSSound.beep()
        }
        
        let userInfo:[AnyHashable:Any] = ["transUnit.uid" : uid as Any]
        NotificationCenter.default.post(name: EditorViewController.transUnitDidChanged,
                                        object: nil,
                                        userInfo: userInfo)
    }
    
    func getXliffAllowedString(from s:String?) -> String? {
        guard var result = s else {
            return nil
        }
        
        XliffEscapeCharacters.allCases.forEach {
            result = result.replacingOccurrences(of: $0.rawValue, with: $0.escapedString)
        }
        
        return result
    }
    
    func saveOnWindowClose() {
        if isEdited && !transUnit.id.isEmpty {
            $transUnits.append(transUnit)
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView()
    }
}
