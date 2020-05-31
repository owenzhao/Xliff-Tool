//
//  EditorViewController.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/25.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Cocoa
import XMLCoder
import Unrealm

class EditorViewController: NSViewController {
    var transUnits:Results<XTTransUnit>!
    var transUnit:XTTransUnit? {
        var results:Results<XTTransUnit> = transUnits
        
        let defaults = UserDefaults.standard
        let skipVerifiedResults = defaults.bool(forKey: UserDefaults.Key.skipVerifiedResults.rawValue)
        
        if skipVerifiedResults {
            results = results.filter("isVerified = false")
        }
        
        let skipTranslatedResults = defaults.bool(forKey: UserDefaults.Key.skipTranslatedResults.rawValue)
        
        if skipTranslatedResults {
            results = results.filter("target != nil AND target != ''")
        }
        
        return results.first
    }
    
    var files:Results<XTFile>!
    var file:XTFile? {
        guard let transUnit = self.transUnit else {
            return nil
        }
        
        return files.filter { $0.body!.transUnits.contains(transUnit)}.first
    }
    
    lazy private var total = self.transUnits.count
    lazy private var translated = self.transUnits.filter("target != nil AND target != ''")
    lazy private var verified = self.transUnits.filter("isVerified = true")
    
    var isEdited = false
    
    @IBOutlet weak var translatedLabel: NSTextField!
    @IBOutlet weak var verifiedLabel: NSTextField!
    @IBOutlet weak var progressLabel: NSTextField!
    
    @IBOutlet weak var sourceLabel: NSTextField!
    @IBOutlet var targetTextView: NSTextView!
    @IBOutlet weak var noteLabel: NSTextField!
    @IBOutlet weak var copyNoteObjectIDButton: NSButton!
    
    @IBOutlet weak var verifyButton: NSButton!
    
    @IBAction func openBingTranslatorButtonClicked(_ sender: Any) {
        let webString = "https://cn.bing.com/translator/?text="
        openTranslationWebSite(webString)
    }
    
    @IBAction func openGoolgeTranslateButtonClicked(_ sender: Any) {
        let webString = "https://translate.google.com/?client=tw-ob#auto/auto/"
        openTranslationWebSite(webString)
    }
    
    private func openTranslationWebSite(_ webString:String) {
        guard let source = transUnit?.source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        NSWorkspace.shared.open(URL(string: webString + source)!)
    }
    
    
    // "Class =\"NSButtonCell\"; title =\"Cancel\"; ObjectID =\"0uT-sC-hK8\";"
    // or "Class = \"NSButtonCell\"; title = \"Cancel\"; ObjectID = \"0uT-sC-hK8\";"
    @IBAction func copyNoteObjectIDButtonClicked(_ sender: Any) {
        let pb = NSPasteboard.general
        let note = transUnit!.note!
        let objectIdString = "ObjectID"
        let range = note.range(of: objectIdString, options: .backwards, range: note.startIndex..<note.endIndex)
        let components = note[range!.lowerBound...].components(separatedBy: "\"")
        pb.clearContents()
        pb.setString(components[1], forType: .string)
    }
    
    private func hasObjectID() -> Bool {
        let objectIdString = "ObjectID"
        return transUnit?.note?.contains(objectIdString) ?? false
    }
    
    @IBAction func verifyButtonClicked(_ sender: Any) {
        // save current
        if !isEdited {
            isEdited = true
        }
        
        let transUnit = self.transUnit!
        transUnit.target = targetTextView.string
        transUnit.isVerified = true

        let realm = transUnit.realm!
        try! realm.write {
            realm.add(transUnit, update: .all)
        }
        
        // tried to translate other translations
        let transUnits = self.transUnits.filter({
            !$0.isVerified &&
                $0.source == transUnit.source &&
                ($0.target == nil || $0.target!.isEmpty || $0.target == $0.source)
        })
        
        transUnits.forEach {
            $0.target = transUnit.target
        }
        
        try! realm.write {
            realm.add(transUnits, update: true)
        }

        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(self.willCloseNotification(_:)), name: NSWindow.willCloseNotification, object: self.view.window!)
        }
    }
    
    @objc private func willCloseNotification(_ noti:Notification) {
        defer {
            if isEdited {
                saveDocument(nil)
            }
        }
        
        guard let transUnit = self.transUnit else {
            return
        }
        
        if transUnit.target != targetTextView.string {
            transUnit.isVerified = false
            transUnit.target = targetTextView.string
            
            let realm = try! Realm(fileURL: (NSApp.delegate as! AppDelegate).databaseURL)
            try! realm.write {
                realm.add(transUnit, update: .all)
            }
        }
    }
    
    func updateUI() {
        guard let transUnit = self.transUnit else {
            updateUIAllComplete()

            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("Translation Complete!", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
            
            return
        }
        
        let isModifiedString = isEdited ? NSLocalizedString(" - Edited", comment: "") : ""
        view.window?.title = (file?.original ?? "") + isModifiedString
        
        updateProgress()
        
        sourceLabel.stringValue = transUnit.source
        setAttributedString(transUnit.target ?? "")
        noteLabel.stringValue = transUnit.note ?? ""
        copyNoteObjectIDButton.isEnabled = hasObjectID()
        verifyButton.isEnabled = !(transUnit.target?.isEmpty ?? true)
    }
    
    private func updateUIAllComplete() {
        let isModifiedString = isEdited ? NSLocalizedString(" - Edited", comment: "") : ""
        view.window?.title = isModifiedString
        
        updateProgress()
        
        sourceLabel.stringValue = NSLocalizedString("Source", comment: "")
        setAttributedString("")
        noteLabel.stringValue = NSLocalizedString("Note", comment: "")
        copyNoteObjectIDButton.isEnabled = false
        verifyButton.isEnabled = false
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func updateProgress() {
        translatedLabel.stringValue = NSLocalizedString("Translated: ", comment: "") + "\(translated.count)/\(total)"
        verifiedLabel.stringValue = NSLocalizedString("Verified: ", comment: "") + "\(verified.count)/\(total)"
        progressLabel.stringValue = String(format: NSLocalizedString("Progress: %.2f%%", comment: ""), Double(verified.count) / Double(total) * 100.0)
    }
}

extension EditorViewController:NSTextDelegate {
    func textDidChange(_ notification: Notification) {
        setAttributedString(targetTextView.string)
        verifyButton.isEnabled = !targetTextView.string.isEmpty
    }
    
    private func setAttributedString(_ str:String) {
        let attributes:[NSAttributedString.Key:Any] = [
            .font:NSFont.systemFont(ofSize: 16.0),
            .foregroundColor:NSColor(named: "targetColor")!
        ]
        let attritubtedString = NSAttributedString(string: str, attributes: attributes)
        targetTextView.textStorage?.setAttributedString(attritubtedString)
    }
}

// MARK: - Menu
extension EditorViewController {
    @objc func saveDocument(_ sender: Any?) {
        defer {
            isEdited = false
        }
        
        let xmlString = """
<?xml version="1.0" encoding="UTF-8"?>\n
"""
        var xmlData = xmlString.data(using: .utf8)!
        
        let realm = (transUnits.first?.realm)!
        let xliff = realm.objects(XTXliff.self).first!
        
        // replace /n to &#10; // & is &amp;
        // replace /n to UUID().uuidString, then replacing UUID().uuidString to &#10;
        let uuid = UUID().uuidString
        xliff.files.flatMap({ $0.body!.transUnits })
            .forEach({
                if $0.id.contains("\n") {
                    $0.id = $0.id.replacingOccurrences(of: "\n", with: uuid)
                }
            })
        
        let encoder = XMLEncoder()
        encoder.outputFormatting = .prettyPrinted
        xmlData += try! encoder.encode(xliff, withRootKey: "xliff")
        let uuidData = uuid.data(using: .utf8)!
        let newLineData = "&#10;".data(using: .utf8)!
        
        var lowerBound = xmlData.startIndex
        while let range = xmlData.range(of: uuidData, in: lowerBound..<xmlData.endIndex) {
            xmlData.replaceSubrange(range, with: newLineData)
            lowerBound = range.lowerBound + newLineData.count
        }
        
//        var str = String(data: xmlData, encoding: .utf8)!
//        str = str.replacingOccurrences(of: uuid, with: "&#10;")
//        xmlData = str.data(using: .utf8)!
        
        let url = (NSApp.delegate as! AppDelegate).xliffURL!
        try! xmlData.write(to: url, options: .atomic)
    }
    
    @objc func skipVerifiedResults(_ sender: Any?) {
        let isOn = ((sender as! NSMenuItem).state == .on)
        UserDefaults.standard.set(isOn, forKey: UserDefaults.Key.skipVerifiedResults.rawValue)
        
        updateUI()
    }
    
    @objc func skipTranslatedResults(_ sender: Any?) {
        let isOn = ((sender as! NSMenuItem).state == .on)
        UserDefaults.standard.set(isOn, forKey: UserDefaults.Key.skipTranslatedResults.rawValue)
        
        updateUI()
    }
    
    
}
