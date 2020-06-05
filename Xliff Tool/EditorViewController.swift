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
        var results = transUnits.filter("isVerified = false")
        let defaults = UserDefaults.standard
        let verifyTranslatedResultsFirst = (defaults.integer(forKey: UserDefaults.Key.verifyTranslatedResultsFirst.rawValue) == NSControl.StateValue.on.rawValue)
        
        if verifyTranslatedResultsFirst {
            let translatedResults = results.filter("target != nil AND target != ''")
            
            if !translatedResults.isEmpty {
                results = translatedResults
            }
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
    @IBOutlet var targetTextView: NSTextView!{
        didSet {
            let attributes:[NSAttributedString.Key:Any] = [
                .font:NSFont.userFont(ofSize: 16.0) ?? NSFont.systemFont(ofSize: 16.0),
                .foregroundColor:NSColor(named: "targetColor")!
            ]
            targetTextView.typingAttributes = attributes
        }
    }
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
        
        addViewMenuDelegate()
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(self.willCloseNotification(_:)), name: NSWindow.willCloseNotification, object: self.view.window!)
        }
    }
    
    private func addViewMenuDelegate() {
        let menu = NSApp.mainMenu!
        for menuItem in menu.items {
            if menuItem.submenu?.identifier == NSUserInterfaceItemIdentifier("viewMenu") {
                menuItem.submenu?.delegate = self
                break
            }
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
        updateWindowTitle()
        
        guard let transUnit = self.transUnit else {
            updateUIAllComplete()

            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("Translation Complete!", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
            
            return
        }
        
        updateProgress()
        
        sourceLabel.stringValue = transUnit.source
        targetTextView.string = transUnit.target ?? ""
        noteLabel.stringValue = transUnit.note ?? ""
        copyNoteObjectIDButton.isEnabled = hasObjectID()
        verifyButton.isEnabled = !(transUnit.target?.isEmpty ?? true)
    }
    
    private func updateUIAllComplete() {
        updateProgress()
        
        sourceLabel.stringValue = NSLocalizedString("Source", comment: "")
        targetTextView.string = ""
        noteLabel.stringValue = NSLocalizedString("Note", comment: "")
        copyNoteObjectIDButton.isEnabled = false
        verifyButton.isEnabled = false
    }
    
    private func updateWindowTitle() {
        let isModifiedString = isEdited ? NSLocalizedString(" - Edited", comment: "") : ""
        
        guard self.transUnit != nil else {
            view.window?.title = (NSApp.delegate as! AppDelegate).xliffURL.lastPathComponent + isModifiedString
            return
        }
        
        view.window?.title = (file?.original ?? "") + isModifiedString
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
        if !isEdited {
            isEdited = true
            self.updateWindowTitle()
        }
        
        if transUnit?.isVerified == true {
            transUnit?.isVerified = false
        }
        
        verifyButton.isEnabled = !targetTextView.string.isEmpty
    }
}

// MARK: - Menu
extension EditorViewController {
    @IBAction func openInXcode(_ sender: Any?) {
        do {
            let xliffURL = (NSApp.delegate as! AppDelegate).xliffURL!
            let xcodeURL = URL(fileURLWithPath: "/Applications/Xcode.app")
            try NSWorkspace.shared.open([xliffURL], withApplicationAt: xcodeURL, options: .default, configuration: .init())
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("No Xcode Found", comment: "")
            alert.informativeText = NSLocalizedString("There is no Xcode.app in /Applications directory.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            NSSound.beep()
            alert.runModal()
        }
    }
    
    @objc func saveDocument(_ sender: Any?) {
        saveCurrentTransUnit()
        let url = (NSApp.delegate as! AppDelegate).xliffURL!
        save(to: url)
        updateWindowTitle()
    }
    
    private func saveCurrentTransUnit() {
        if let transUnit = self.transUnit {
            transUnit.target = targetTextView.string
            
            let realm = transUnit.realm!
            try! realm.write {
                realm.add(transUnit, update: .all)
            }
        }
    }
    
    private func save(to url:URL) {
        defer {
            isEdited = false
        }
        
        let xmlString = """
<?xml version="1.0" encoding="UTF-8"?>\n
"""
        var xmlData = xmlString.data(using: .utf8)!
        
        let realm = (transUnits.first?.realm)!
        let xliff = realm.objects(XTXliff.self).first!
        
        let encoder = XMLEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.prettyPrintIndentation = .spaces(2)
        // stop escaping " as  &quot; in Element value by reset other escaping
        encoder.charactersEscapedInElements = [
            ("&", "&amp;"),
            ("<", "&lt;"),
            (">", "&gt;"),
            ("'", "&apos;"),
        ]
        // escping \n as "&#10;" in attribute value
        encoder.charactersEscapedInAttributes += [("\n", "&#10;")]
        xmlData += try! encoder.encode(xliff, withRootKey: "xliff")
        
        try! xmlData.write(to: url, options: .atomic)
    }
    
    @IBAction func exportXliffFile(_ sender: Any?) {
        let exportPanel = NSSavePanel()
        exportPanel.prompt = NSLocalizedString("Export", comment: "")
        exportPanel.allowedFileTypes = ["xliff"]
        let xliffURL = (NSApp.delegate as? AppDelegate)?.xliffURL
        exportPanel.directoryURL = xliffURL
        exportPanel.nameFieldStringValue = xliffURL!.lastPathComponent
        exportPanel.beginSheetModal(for: view.window!) { [unowned self] (response) in
            if response == .OK {
                self.save(to: exportPanel.url!)
            }
        }
    }
    
    @IBAction func verifyTranslatedResultsFirst(_ sender: Any?) {
        let menuItem = (sender as! NSMenuItem)
        let stateValue:NSControl.StateValue = (menuItem.state == .on) ? .off : .on
        menuItem.state = stateValue
        UserDefaults.standard.set(stateValue, forKey: UserDefaults.Key.verifyTranslatedResultsFirst.rawValue)
        updateUI()
    }
}

extension EditorViewController:NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let defaults = UserDefaults.standard
        let verifyTranslatedResultsFirst = defaults.integer(forKey: UserDefaults.Key.verifyTranslatedResultsFirst.rawValue)
        
        for menuItem in menu.items {
            if menuItem.identifier == NSUserInterfaceItemIdentifier("verifyTranslatedResultsFirst") {
                menuItem.state = (verifyTranslatedResultsFirst == NSControl.StateValue.on.rawValue) ? .on : .off
            }
        }
    }
}
