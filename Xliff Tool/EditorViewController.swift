//
//  EditorViewController.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/25.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Cocoa
import XMLCoder
import RealmSwift

class EditorViewController: NSViewController {
    static let transUnitDidChanged = Notification.Name("transUnitDidChanged")
    
    var transUnits:Results<RLMXTTransUnit>!
    var transUnit:RLMXTTransUnit?
    var xliff:RLMXTXliff!
    
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
        
        DispatchQueue.main.async {
            let userInfo:[AnyHashable:Any] = ["transUnit.uid":result?.uid ?? "nil"]
            NotificationCenter.default.post(name: EditorViewController.transUnitDidChanged,
                                            object: nil,
                                            userInfo: userInfo)
        }

        return result
    }
    
    var files:Results<RLMXTFile>!
    
    lazy private var total = self.transUnits.count
    lazy private var translated = self.transUnits.filter("(target != nil AND target != '') OR (allowEmptyTarget == true)")
    lazy private var verified = self.transUnits.filter("isVerified = true")
    
    var isEdited = false
    
    @IBOutlet weak var translatedLabel: NSTextField!
    @IBOutlet weak var verifiedLabel: NSTextField!
    @IBOutlet weak var progressLabel: NSTextField!
    
    @IBOutlet weak var idLabel: NSTextField!
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
    @IBOutlet weak var allowEmptyTargetButton: NSButton! {
        didSet {
            let attributes:[NSAttributedString.Key:Any] = [
                .foregroundColor:NSColor(named: "targetColor")!
            ]
            let attributedString = NSAttributedString(string: allowEmptyTargetButton.title, attributes: attributes)
            allowEmptyTargetButton.attributedTitle = attributedString
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
    
    
    @IBAction func allowEmptyTargetButtonClicked(_ sender: Any) {
        if let button = sender as? NSButton {
            if button.state == .on {
                verifyButton.isEnabled = true
            }
            
            saveChanges()
        }
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
        if !isEdited {
            isEdited = true
        }
        
        // save current
        let transUnit = self.transUnit!
        let realm = transUnit.realm!
        
        try! realm.write {
            transUnit.isVerified = true
        }
        
        // tried to translate other translations
        let transUnits = self.transUnits.filter({
            !$0.isVerified &&
                $0.source == transUnit.source &&
                ($0.target == nil || $0.target!.isEmpty || $0.target == $0.source)
        })
        
        try! realm.write {
            transUnits.forEach {
                $0.target = transUnit.target
            }
        }

        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addViewMenuDelegate()
        
        DispatchQueue.main.async { [self] in
            NotificationCenter.default.addObserver(self, selector: #selector(willCloseNotification(_:)), name: NSWindow.willCloseNotification, object: self.view.window!)
            NotificationCenter.default.addObserver(self, selector: #selector(selectionDidChangeNotification(_:)), name: NSOutlineView.selectionDidChangeNotification, object: nil)
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
            try! transUnit.realm!.write {
                transUnit.isVerified = false
                transUnit.target = getXliffAllowedString(from: targetTextView.string)
            }
        }
    }
    
    @objc private func selectionDidChangeNotification(_ notification:Notification) {
        if let outlineView = notification.object as? NSOutlineView {
            let row = outlineView.selectedRow
            let item = outlineView.item(atRow: row)
            
            if let file = item as? RLMXTFile {
                debugPrint(file.original)
            } else if let transUnit = item as? RLMXTTransUnit {
                updateUI(with: transUnit)
            } else {
               debugPrint("")
            }
        }
    }
    
    func updateUI() {
        transUnit = nextTransUnit()
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
        
        idLabel.stringValue = transUnit.id
        sourceLabel.stringValue = transUnit.source
        targetTextView.string = transUnit.target ?? ""
        allowEmptyTargetButton.state = transUnit.allowEmptyTarget ? .on : .off
        noteLabel.stringValue = transUnit.note ?? ""
        copyNoteObjectIDButton.isEnabled = hasObjectID()
        verifyButton.isEnabled = !(transUnit.target?.isEmpty ?? true)
    }
    
    func updateUI(with transUnit:RLMXTTransUnit) {
        self.transUnit = transUnit
        updateWindowTitle()
        
        idLabel.stringValue = transUnit.id
        sourceLabel.stringValue = transUnit.source
        targetTextView.string = transUnit.target ?? ""
        allowEmptyTargetButton.state = transUnit.allowEmptyTarget ? .on : .off
        noteLabel.stringValue = transUnit.note ?? ""
        copyNoteObjectIDButton.isEnabled = hasObjectID()
        verifyButton.isEnabled = {
            if allowEmptyTargetButton.state == .on {
                return true
            }
            
            return !(transUnit.target?.isEmpty ?? true)
        }()
    }
    
    private func updateUIAllComplete() {
        updateProgress()
        
        idLabel.stringValue = NSLocalizedString("ID", comment: "")
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
        
        let file = transUnit?.bodies.first?.files.first
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
        // title
        if !isEdited {
            isEdited = true
            updateWindowTitle()
        }
        
        updateProgress()
        saveChanges()
    }
    
    func saveChanges() {
        // save changes
        let transUnit = self.transUnit!
        let realm = transUnit.realm!
        
        try! realm.write {
            if transUnit.isVerified == true {
                transUnit.isVerified = false
            }
            
            transUnit.allowEmptyTarget = (allowEmptyTargetButton.state == .on)
            
            transUnit.target = {
                if allowEmptyTargetButton.state == .on {
                    let result = targetTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if result.isEmpty {
                        return nil
                    }
                }
                
                return getXliffAllowedString(from: targetTextView.string)
            }()
        }
        
        // verify button
        verifyButton.isEnabled = {
            if allowEmptyTargetButton.state == .on {
                return true
            }
            
            return !targetTextView.string.isEmpty
        }()
    }
    
    func getXliffAllowedString(from s:String) -> String {
        var result = s
        
        XliffEscapeCharacters.allCases.forEach {
            result = result.replacingOccurrences(of: $0.rawValue, with: $0.escapedString)
        }
        
        return result
    }
}

// MARK: - Menu
extension EditorViewController {
    @IBAction func openInXcode(_ sender: Any?) {
        let xliffURL = (NSApp.delegate as! AppDelegate).xliffURL!
        let xcodeURL = URL(fileURLWithPath: "/Applications/Xcode.app")
        NSWorkspace.shared.open([xliffURL], withApplicationAt: xcodeURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: { app, error in
            if error != nil {
                print(error!.localizedDescription)
            }
        })
    }
    
    @objc func saveDocument(_ sender: Any?) {
        saveCurrentTransUnit()
        let url = (NSApp.delegate as! AppDelegate).xliffURL!
        save(to: url)
        updateWindowTitle()
    }
    
    private func saveCurrentTransUnit() {
        if let transUnit = self.transUnit {
            try! transUnit.realm!.write {
                transUnit.target = targetTextView.string
            }
        }
    }
    
    private func save(to url:URL) {
        let xmlString = """
<?xml version="1.0" encoding="UTF-8"?>\n
"""
        var xmlData = xmlString.data(using: .utf8)!
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
        xmlData += try! encoder.encode(xliff!, withRootKey: "xliff")
        
        try! xmlData.write(to: url, options: .atomic)
        isEdited = false
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
