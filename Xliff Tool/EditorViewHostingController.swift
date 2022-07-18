//
//  EditorViewHostingController.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2022/6/8.
//  Copyright © 2022 zhaoxin. All rights reserved.
//

import Cocoa
import SwiftUI
import XMLCoder
import RealmSwift

class EditorViewHostingController: NSHostingController<EditorView> {
    var xliff:RLMXTXliff!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: EditorView())
    }
    
    override init?(coder: NSCoder, rootView: EditorView) {
        super.init(coder: coder, rootView: EditorView())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addViewMenuDelegate()
        
        DispatchQueue.main.async { [unowned self] in
            NotificationCenter.default.addObserver(self, selector: #selector(willCloseNotification(_:)), name: NSWindow.willCloseNotification, object: view.window!)
            NotificationCenter.default.addObserver(self, selector: #selector(updateWindowTitle(_:)), name: EditorView.editChanged, object: nil)
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
        if rootView.isEdited {
            rootView.saveOnWindowClose()
            saveDocument(nil)
        }
    }
    
    @objc private func updateWindowTitle(_ noti:Notification) {
        let isModifiedString = rootView.isEdited ? NSLocalizedString(" - Edited", comment: "") : ""
        let file = xliff.files.first
        view.window?.title = (file?.original ?? "") + isModifiedString
    }
}

// MARK: - Menu
extension EditorViewHostingController {
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
        let url = (NSApp.delegate as! AppDelegate).xliffURL!
        save(to: url)
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
        rootView.isEdited = false
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
        rootView.updateUI()
    }
}

extension EditorViewHostingController:NSMenuDelegate {
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


class RealmHelper {
    private init() {}
    static let share  = RealmHelper()
    
    var config : Realm.Configuration!
}
