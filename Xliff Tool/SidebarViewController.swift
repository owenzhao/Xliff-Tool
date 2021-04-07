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
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var notificationToken: NotificationToken? = nil
    
    var files:Results<RLMXTFile>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(transUnitDidChanged(_:)), name: EditorViewController.transUnitDidChanged, object: nil)
        
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
        let realm = files.first?.realm
        if let uid = notification.userInfo?["transUnit.uid"] as? String, uid != "nil",
           let transUnit = realm?.object(ofType: RLMXTTransUnit.self, forPrimaryKey: uid) {
            outlineView.expandItem(transUnit.bodies.first?.files.first)
//            outlineView.expandItem(files.first)
            let row = outlineView.row(forItem: transUnit)
            outlineView.selectRowIndexes(IndexSet([row]), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
        }
    }
}

extension SidebarViewController:NSSearchFieldDelegate {
    func searchFieldDidStartSearching(_ sender: NSSearchField) {
        
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        
    }
}

extension SidebarViewController:NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return files[index]
        }
        
        let transUnits = (item as? RLMXTFile)?.body?.transUnits
        return transUnits![index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is RLMXTFile
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard files != nil else {
            return 0
        }
        
        if item == nil {
            return files.count
        }
        
        if let file = item as? RLMXTFile, let transUnits = file.body?.transUnits {
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
