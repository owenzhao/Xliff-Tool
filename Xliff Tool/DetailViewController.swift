//
//  DetailViewController.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/26.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Cocoa
import XMLCoder
import RealmSwift

class DetailViewController: NSViewController {
    static let openEditor = Notification.Name("openEditor")
    
    var xliff:XTXliff? {
        didSet {
            if xliff != nil {
                tableView.reloadData()
            }
        }
    }
    
    var projectFilename:String!
    
    @IBOutlet weak var xliffFilePath: NSTextField!
    @IBOutlet weak var lastModifiedDateLabel: NSTextField!
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var actionButton: NSButton!
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        view.window?.close()
    }
    
    @IBAction func actionButtonClicked(_ sender: Any) {
        let button = sender as! NSButton
        
        if button.title == NSLocalizedString("Create New Project", comment: "") {
            showProjectNamingAlert()
        } else {
            updateProject()
        }
    }
    
    private func showProjectNamingAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Name Your Project", comment: "")
        var array:NSArray?
        Bundle.main.loadNibNamed("NSTextFiledWithIndicator", owner: self, topLevelObjects: &array)
        
        var tfView:NSTextFiledWithIndicator? = nil
        
        for object in array! {
            if object is NSTextFiledWithIndicator {
                tfView = object as? NSTextFiledWithIndicator
                break
            }
        }
        
        tfView?.frame = NSRect(x: 0, y: 0, width: alert.window.frame.width, height: 40)
        tfView?.textField.placeholderString = NSLocalizedString("Project Name", comment: "")
        
        alert.accessoryView = tfView
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        let okButton = alert.buttons.first!
        okButton.isEnabled = false
        
        let observer = NotificationCenter.default.addObserver(forName: NSControl.textDidChangeNotification, object: tfView!.textField, queue: nil) { (noti) in
            
            DispatchQueue.main.async {
                let tv = noti.userInfo?["NSFieldEditor"] as! NSTextView
                okButton.isEnabled = !tv.string.isEmpty && self.canUseNameAsNewProject(tv.string)
                
                tfView?.imageView.image = {
                    if tv.string.isEmpty {
                        return NSImage(named: NSImage.statusNoneName)
                    }
                    
                    if self.canUseNameAsNewProject(tv.string) {
                        return NSImage(named: NSImage.statusAvailableName)
                    } else {
                        return NSImage(named: NSImage.statusUnavailableName)
                    }
                }()
                
                okButton.isEnabled = (tfView?.imageView.image?.name() == NSImage.statusAvailableName)
            }
        }
        
        alert.beginSheetModal(for: view.window!) { [unowned self] (response) in
            defer {
                NotificationCenter.default.removeObserver(observer)
            }
            
            if response == .alertFirstButtonReturn {
                // save xliff to database with the project name
                let projectName = tfView!.textField.stringValue + ".realm"
                let url = URL(fileURLWithPath: projectName, relativeTo: URL.rootURL)
                (NSApp.delegate as? AppDelegate)?.databaseURL = url
                let realm = try! Realm(fileURL: url)
                try! realm.write {
                    realm.add(self.xliff!)
                }
                
                // open editor
                self.openEditor()
                
                // close self
                self.view.window?.close()
            } else if response == .alertSecondButtonReturn {
                print("Cancel")
            }
        }
    }
    
    private func updateProject() {
        let fm = FileManager.default
        
        // backup current realm file
        let originalURL = URL(fileURLWithPath: projectFilename, relativeTo: URL.rootURL)
        (NSApp.delegate as? AppDelegate)?.databaseURL = originalURL
        let backupFileURL = URL(fileURLWithPath: getBackupFilename(), relativeTo: URL.backupRootURL)
        try! fm.copyItem(at: originalURL, to: backupFileURL)
        
        // remove backups more than latest 5.
        let backupfileURLs = try! fm.contentsOfDirectory(at: URL.backupRootURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        let fileSuffix = "." + "yyyyMMddHHmmssSSS" + ".realm"
        var projectName = self.projectFilename!
        projectName.removeLast(".realm".count)
        
        let backupOfCurrentProjectURLs = backupfileURLs.filter({
            var filename = $0.lastPathComponent
            filename.removeLast(fileSuffix.count)
            
            return filename == projectName
        }).sorted(by: {
            let date1 = try! $0.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate!
            let date2 = try! $1.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate!
            
            return date1 < date2
        })
        
        if backupOfCurrentProjectURLs.count > 5 {
            backupOfCurrentProjectURLs[5...].forEach {
                try! fm.removeItem(at: $0)
            }
        }

        // merge old xliff to new xliff
        let originalXliff = getXliff(form: originalURL)
        let xliff = self.xliff!
        
        // update transunits from xliff with transunits from original xliff in the same file.
        for originalFile in originalXliff.files {
            if let file = xliff.files.filter({ $0.id == originalFile.id }).first {
                for originaltransUnit in originalFile.body!.transUnits {
                    if let transUnit = file.body?.transUnits.filter({
                        $0.id == originaltransUnit.id &&
                        $0.source == originaltransUnit.source &&
                        $0.target == originaltransUnit.target &&
                        $0.note == originaltransUnit.note
                    }).first {
                        if originaltransUnit.isVerified {
                            transUnit.isVerified = true
                        }
                    } else if let transUnit = file.body?.transUnits.filter({ $0.id == originaltransUnit.id }).first,
                        (originaltransUnit.target?.isEmpty == false) &&
                        (transUnit.target == nil || transUnit.target!.isEmpty || transUnit.target == transUnit.source) {
                        
                        transUnit.target = originaltransUnit.target
                    }
                }
            }
        }
        
        // update transunits from xliff in new files with transunits in the original xliff.
        let fileSet = Set(xliff.files)
        let newFileSet = fileSet.union(originalXliff.files).subtracting(fileSet)
        for transUnit in newFileSet.flatMap({ $0.body!.transUnits }) {
            if let originalTransUnit = xliff.realm?.objects(XTTransUnit.self)
                .filter("source = %@ AND note = %@", transUnit.source, transUnit.note ?? "")
                .sorted(byKeyPath: "isVerified").first {
                
                transUnit.target = originalTransUnit.target
            } else if let originalTransUnit = xliff.realm?.objects(XTTransUnit.self)
                .filter("source = %@", transUnit.source)
                .sorted(byKeyPath: "isVerified").first {
                
                transUnit.target = originalTransUnit.target
            }
        }
        
        // remove original xliff and save xliff
        let realm = originalXliff.realm!
        try! realm.write {
            realm.deleteAll()
            realm.add(xliff)
        }
        
        // open editor
        openEditor()
        
        // close self
        view.window?.close()
    }
    
    private func openEditor() {
        NotificationCenter.default.post(name: DetailViewController.openEditor, object: nil)
    }
    
    private func getXliff(form url:URL) -> XTXliff {
        let realm = try! Realm(fileURL: url)
        return realm.objects(XTXliff.self).first!
    }
    
    private func getBackupFilename() -> String {
        let realmExtesion = ".realm"
        var projectName = self.projectFilename!
        projectName.removeLast(realmExtesion.count)
        
        return [projectName, getTimeStamp()].joined(separator: ".") + realmExtesion
    }
    
    private func getTimeStamp() -> String {
        let now = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMddHHmmssSSS"
        
        return df.string(from: now)
    }
    
    private func canUseNameAsNewProject(_ name:String) -> Bool {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let folderName = "databases"
        let folderURL = URL(fileURLWithPath: folderName, relativeTo: baseURL)
        let urls = try! FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.nameKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        let names = urls.compactMap { try? $0.resourceValues(forKeys: [.nameKey]).name }
        
        return !names.map({ $0.lowercased() }).contains(name.lowercased())
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(selectedProjectChanged(_:)), name: IndexViewController.selectedProjectChanged, object: nil)
    }
    
    @objc private func selectedProjectChanged(_ noti:Notification) {
        projectFilename = noti.userInfo?["projectFilename"] as? String
        
        if projectFilename == NSLocalizedString("New Project", comment: "") {
            actionButton.title = NSLocalizedString("Create New Project", comment: "")
        } else {
            actionButton.title = NSLocalizedString("Update Project", comment: "")
        }
    }
}

extension DetailViewController:NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return xliff?.files.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("myView"), owner: self)
        
        if view == nil {
            view = NSTextField(labelWithString: "")
            view?.identifier = NSUserInterfaceItemIdentifier("myView")
        }
        
        let tf = view as! NSTextField
        
        switch tableColumn!.identifier.rawValue {
        case "original":
            tf.stringValue = xliff?.files[row].original ?? ""
        case "sourceLanguage":
            tf.stringValue = xliff?.files[row].sourceLanguage ?? ""
        case "targetLanguage":
            tf.stringValue = xliff?.files[row].targetLanguage ?? ""
        case "dataType":
            tf.stringValue = xliff?.files[row].dataType ?? ""
        default:
            fatalError()
        }
        
        return view
    }
    
    func selectionShouldChange(in tableView: NSTableView) -> Bool {
        return false
    }
}
