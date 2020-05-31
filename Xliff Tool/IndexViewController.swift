//
//  IndexViewController.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/26.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Cocoa
import Unrealm

class IndexViewController: NSViewController {
    static let selectedProjectChanged = Notification.Name("selectedProjectChanged")
    
    var array = Array<(String, Date)>()

    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
}

extension IndexViewController:NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("myView"), owner: self)
        
        if result == nil {
            result = NSTextField(labelWithString: "")
            result?.identifier = NSUserInterfaceItemIdentifier("myView")
        }
        
        if tableColumn?.identifier.rawValue == "name" {
            var name = array[row].0
            if name.hasSuffix(".realm") {
                name.removeLast(".realm".count) // remove extension
            }
            (result as? NSTextField)?.stringValue = name
        } else {
            if row == array.count - 1 {
                (result as? NSTextField)?.stringValue = "-"
            } else {
                (result as? NSTextField)?.stringValue = DateFormatter.localizedString(from: array[row].1, dateStyle: .short, timeStyle: .short)
            }
        }
        
        return result
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let seletedRow = tableView.selectedRow
        let userInfo = ["projectFilename":array[seletedRow].0]
        NotificationCenter.default.post(name: IndexViewController.selectedProjectChanged, object: nil, userInfo: userInfo)
    }
    
}
