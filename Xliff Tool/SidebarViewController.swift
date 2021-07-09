//
//  SidebarViewController.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2021/3/19.
//  Copyright © 2021 zhaoxin. All rights reserved.
//

import Cocoa
import RealmSwift

class SidebarViewController: NSViewController {
    static let userSelectItemDidChanged = Notification.Name("userSelectItemDidChanged")
    private let defaults = UserDefaults.standard
    
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    private var expandedItem:RLMXTFile?
    private var searchPredicate:NSPredicate? = nil {
        didSet {
            outlineView.reloadData()
            
            if searchPredicate != nil {
                outlineView.expandItem(nil, expandChildren: true)
            }
        }
    }
    
    private var notificationToken: NotificationToken? = nil
    var files:Results<RLMXTFile>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(transUnitDidChanged(_:)), name: EditorViewController.transUnitDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChangeNotification(_:)), name: NSControl.textDidChangeNotification, object: searchField)
        
        let url = (NSApp.delegate as? AppDelegate)?.databaseURL
        let realm = try! Realm(fileURL: url!)
        let transUnits = realm.objects(RLMXTTransUnit.self)
        
        // Observe Results Notifications
        notificationToken = transUnits.observe { [weak self] (changes: RealmCollectionChange) in
            guard let outlineView = self?.outlineView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                outlineView.reloadData()
            case .update(_, _, _, let modifications):
                outlineView.beginUpdates()

                modifications.forEach {
                    let item = transUnits[$0]
                    outlineView.reloadItem(item)
                }
                
                outlineView.endUpdates()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    @objc private func transUnitDidChanged(_ notification: Notification) {
        guard let realm = files?.first?.realm else {
            return
        }
        
        if let uid = notification.userInfo?["transUnit.uid"] as? String, uid != "nil",
           let transUnit = realm.object(ofType: RLMXTTransUnit.self, forPrimaryKey: uid) {
            
            let toExpandItem = transUnit.bodies.first?.files.first
            
            if expandedItem != toExpandItem {
                outlineView.collapseItem(expandedItem)
                outlineView.expandItem(toExpandItem)
                expandedItem = toExpandItem
            }

            let row = outlineView.row(forItem: transUnit)
            outlineView.selectRowIndexes(IndexSet([row]), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
        }
    }
    
    @IBOutlet weak var searchSourceCheckButton: NSButton! {
        didSet {
            searchSourceCheckButton.state = NSControl.StateValue(defaults.integer(forKey: UserDefaults.Key.searchSource.rawValue))
        }
    }
    @IBOutlet weak var searchTargetCheckButton: NSButton! {
        didSet {
            searchTargetCheckButton.state = NSControl.StateValue(defaults.integer(forKey: UserDefaults.Key.searchTarget.rawValue))
        }
    }
    @IBOutlet weak var searchNoteCheckButton: NSButton! {
        didSet {
            searchNoteCheckButton.state = NSControl.StateValue(defaults.integer(forKey: UserDefaults.Key.searchNote.rawValue))
        }
    }
    @IBOutlet weak var searchOptionCaseSensitiveCheckButton: NSButton! {
        didSet {
            searchOptionCaseSensitiveCheckButton.state = NSControl.StateValue(defaults.integer(forKey: UserDefaults.Key.searchOptionCaseSensitive.rawValue))
            searchOptionCaseSensitiveCheckButton.attributedAlternateTitle = NSAttributedString(string: "Aa", attributes: [.font : NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)])
        }
    }
    
    @IBAction func searchSourceCheckButtonClicked(_ sender: Any) {
        let checkButton = sender as! NSButton
        defaults.setValue(checkButton.state.rawValue, forKey: UserDefaults.Key.searchSource.rawValue)
        search(text: searchField.stringValue)
    }
    
    @IBAction func searchTargetCheckButtonClicked(_ sender: Any) {
        let checkButton = sender as! NSButton
        defaults.setValue(checkButton.state.rawValue, forKey: UserDefaults.Key.searchTarget.rawValue)
        search(text: searchField.stringValue)
    }
    
    @IBAction func searchNoteCheckButtonClicked(_ sender: Any) {
        let checkButton = sender as! NSButton
        defaults.setValue(checkButton.state.rawValue, forKey: UserDefaults.Key.searchNote.rawValue)
        search(text: searchField.stringValue)
    }
    
    @IBAction func searchOptionCaseSensitiveCheckButtonClicked(_ sender: Any) {
        let checkButton = sender as! NSButton
        defaults.setValue(checkButton.state.rawValue, forKey: UserDefaults.Key.searchOptionCaseSensitive.rawValue)
        search(text: searchField.stringValue)
    }
    
}

extension SidebarViewController {
    @objc func textDidChangeNotification(_ noti:Notification) {
        if let tf = noti.userInfo?["NSFieldEditor"] as? NSTextView {
            search(text: tf.string)
        } else {
            fatalError()
        }
    }
    
    private func search(text:String) {
        if text.isEmpty {
            searchPredicate = nil
        } else {
            // get options
            let searchSource = (defaults.integer(forKey: UserDefaults.Key.searchSource.rawValue) == NSControl.StateValue.on.rawValue)
            let searchTarget = (defaults.integer(forKey: UserDefaults.Key.searchTarget.rawValue) == NSControl.StateValue.on.rawValue)
            let searchNote = (defaults.integer(forKey: UserDefaults.Key.searchNote.rawValue) == NSControl.StateValue.on.rawValue)
            let searchOptionCaseSensitive = (defaults.integer(forKey: UserDefaults.Key.searchOptionCaseSensitive.rawValue) == NSControl.StateValue.on.rawValue)
            
            let searchOptionCaseSensitiveAction = searchOptionCaseSensitive ? "CONTAINS" : "CONTAINS[c]"
            let searchSourcePart = searchSource ? String(format: "source \(searchOptionCaseSensitiveAction) '%@'", text) : nil
            let searchTargetPart = searchTarget ? String(format: "target \(searchOptionCaseSensitiveAction) '%@'", text) : nil
            let searchNotePart = searchNote ? String(format: "note \(searchOptionCaseSensitiveAction) '%@'", text) : nil
            let searchStr = [searchSourcePart, searchTargetPart, searchNotePart].compactMap {$0}
                .joined(separator: " OR ")
            
            searchPredicate = NSPredicate(format: searchStr, argumentArray: nil)
        }
    }
}

extension SidebarViewController:NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return files?[index] ?? 0
        }
        
        let transUnits = (item as? RLMXTFile)?.body?.transUnits.filter(searchPredicate ?? NSPredicate(value: true))
        return transUnits![index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let file = item as? RLMXTFile,
           let transUnits = file.body?.transUnits.filter(searchPredicate ?? NSPredicate(value: true)) {
            return !transUnits.isEmpty
        }
        
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard files != nil else {
            return 0
        }
        
        if item == nil {
            return files?.count ?? 0
        }
        
        if let file = item as? RLMXTFile, let transUnits = file.body?.transUnits.filter(searchPredicate ?? NSPredicate(value: true)) {
            return transUnits.count
        }
        
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cellView:NSTableCellView?
        
        if let file = item as? RLMXTFile {
            cellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("HeaderCell"), owner: self) as? NSTableCellView
            cellView?.textField?.stringValue = file.original
        } else if let transUnit = item as? RLMXTTransUnit {
            cellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) as? NSTableCellView
            
            let color:NSColor? = {
                if transUnit.target?.isEmpty ?? true {
                    return NSColor(named: "sourceColor")
                } else if transUnit.isVerified {
                    return NSColor(named: "targetColor")
                }
                
                return NSColor(named: "mixedColor")
            }()
            
            let attributedString = NSAttributedString(string: transUnit.source, attributes: [NSAttributedString.Key.foregroundColor : color!])
            cellView?.textField?.attributedStringValue = attributedString
        } else {
            cellView = nil
        }
        
        return cellView
    }
}
