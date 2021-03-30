//
//  AppDelegate.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/25.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Cocoa
import XMLCoder
import RealmSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var fileOpened = false
    var xliffURL:URL!
    var databaseURL:URL!

    @IBOutlet weak var openRecentMenu: NSMenu!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.register()
        
        // create folder
        _ = URL.rootURL
        _ = URL.backupRootURL
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !fileOpened {
            openDocument(nil)
        }
        
        openRecentMenu.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(openEditor(_:)), name: DetailViewController.openEditor, object: nil)
    }
    
    @objc private func openEditor(_ noti:Notification) {
        if let windowController = NSStoryboard.main?.instantiateController(withIdentifier: "editorWindowController") as? NSWindowController,
           let splitViewController = windowController.contentViewController as? NSSplitViewController,
           let sidebarSplitViewItem = splitViewController.splitViewItems.last,
           let editorViewController = splitViewController.splitViewItems.first?.viewController as? EditorViewController,
           let sidebarViewController = sidebarSplitViewItem.viewController as? SidebarViewController {
            
            
            
            let realm = try! Realm(fileURL: databaseURL)
            editorViewController.transUnits = realm.objects(RLMXTTransUnit.self)
            editorViewController.files = realm.objects(RLMXTFile.self)
            editorViewController.updateUI()
            
//            sidebarSplitViewItem.isCollapsed = true // MARK: - TODO add a new preference here.
            sidebarViewController.files = editorViewController.files
            sidebarViewController.outlineView.headerView = nil
            sidebarViewController.outlineView.reloadData()
            
            windowController.showWindow(nil)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let xliffExtension = ".xliff"
        
        guard filename.lowercased().hasSuffix(xliffExtension) else {
            return false
        }
        
        fileOpened = true
        openFile(with: URL(fileURLWithPath: filename))
        
        return true
    }
    
    
    
    private func closeSplitWindow() {
        NSApp.windows.forEach {
            if $0.contentViewController is NSSplitViewController {
                $0.close()
            }
        }
    }
    
    private func setupUI() {
        let xliff = self.getXliff()
        
        // initiate windows controller and show window
        let windowController = NSStoryboard.main?.instantiateController(withIdentifier: "actionWindowController") as? NSWindowController
        windowController?.window?.center()
        windowController?.showWindow(self)
        
        setupIndexViewController(windowController, xliff: xliff)
        setupDetailViewController(windowController, xliff: xliff)
    }
    
    private func getXliff() -> RLMXTXliff {
        let data = try! Data(contentsOf: xliffURL)
        let decoder = XMLDecoder()
        decoder.trimValueWhitespaces = false
        
        return try! decoder.decode(RLMXTXliff.self, from: data)
    }
    
    private func setupIndexViewController(_ windowController:NSWindowController?, xliff:RLMXTXliff) {
        var indexViewController:IndexViewController? = nil
        for vc in ((windowController?.window?.contentViewController as? NSSplitViewController)?.children)! {
            if vc is IndexViewController {
                indexViewController = vc as? IndexViewController
                break
            }
        }
        indexViewController?.array = getIndices(with: xliff)
        indexViewController?.tableView.reloadData()
        indexViewController?.tableView.selectRowIndexes(IndexSet(arrayLiteral: 0), byExtendingSelection: false)
        let userInfo = ["projectFilename":indexViewController?.array[0].0 ?? ""]
        NotificationCenter.default.post(name: IndexViewController.selectedProjectChanged, object: nil, userInfo: userInfo)
    }
    
    private func setupDetailViewController(_ windowController:NSWindowController?, xliff:RLMXTXliff) {
        var detailViewController:DetailViewController? = nil
        for vc in ((windowController?.window?.contentViewController as? NSSplitViewController)?.children)! {
            if vc is DetailViewController {
                detailViewController = vc as? DetailViewController
                break
            }
        }
        detailViewController?.xliff = xliff
        detailViewController?.xliffFilePath.stringValue = xliffURL.path
        let lastModifiedDate = try! xliffURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
        detailViewController?.lastModifiedDateLabel.stringValue = DateFormatter.localizedString(from: lastModifiedDate, dateStyle: .short, timeStyle: .short)
    }
    
    private func getIndices(with xliff:RLMXTXliff) -> [(String, Date)] {
        let fm = FileManager.default
        let openURL = URL.rootURL
        
        if !fm.fileExists(atPath: openURL.path) {
            try! fm.createDirectory(at: openURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        let urls = try! fm.contentsOfDirectory(at: openURL, includingPropertiesForKeys: [.nameKey, .contentModificationDateKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        
        let xliffFileIds:[String] = xliff.files.map { $0.id }
        var array:[(String, Date)] = urls.filter({ $0.path.hasSuffix(".realm") })
            .filter({
                        !self.fileIdsInterSection(from: $0, to: xliffFileIds).isEmpty
            })
            .sorted(by: {
                let filesInCommonLeftCount = self.fileIdsInterSection(from: $0, to: xliffFileIds).count
                let filesInCommonRightCount = self.fileIdsInterSection(from: $1, to: xliffFileIds).count
                
                return filesInCommonLeftCount > filesInCommonRightCount
            })
            .compactMap {
                if let name = try? $0.resourceValues(forKeys: [.nameKey]).name,
                    let modifiedDate = try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                    
                    return (name, modifiedDate)
                }
                
                return nil
            }
        
        array.append((NSLocalizedString("New Project", comment: ""), Date()))
        
        return array
    }
    
    private func fileIdsInterSection(from url:URL, to fileIds:[String]) -> Set<String> {
        let configuration = Realm.Configuration(fileURL: url,
                                                schemaVersion: 1)
        { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                migration.enumerateObjects(ofType: RLMXTFile.className()) { (oldObject, newObject) in
                    newObject!["id"] = oldObject!["id"]
                }
                
                migration.enumerateObjects(ofType: RLMXTTransUnit.className()) { (oldObject, newObject) in
                    newObject!["uid"] = oldObject!["uid"]
                }
            }
        }
        
        Realm.Configuration.defaultConfiguration.schemaVersion = 1
        
        let realm = try! Realm(configuration: configuration)
        let originalFileIdSet = Set(realm.objects(RLMXTFile.self).map { $0.id })
        
        return originalFileIdSet.intersection(fileIds)
    }
}

extension AppDelegate {
    @objc func openDocument(_ sender: Any?) {
        closeSplitWindow()
        
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["xliff"]
        panel.message = NSLocalizedString("Open Xliff", comment: "")

        let response = panel.runModal()
        if response == .OK {
            openFile(with:panel.url!)
        }
    }
    
    private func openFile(with url:URL) {
        xliffURL = url
        addToOpenRecent()
        setupUI()
    }
    
    @objc private func openFile(_ menuItem:NSMenuItem) {
        let url = URL(fileURLWithPath: menuItem.title)
        openFile(with: url)
    }
    
    private func addToOpenRecent() {
        NSDocumentController.shared.noteNewRecentDocumentURL(xliffURL)
    }
    
    @IBAction func openDatabaseDirectory(_ sender: Any?) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = NSLocalizedString("Make sure to backup before you delete anything.", comment: "")
        alert.informativeText = NSLocalizedString("The operations you do next may get your data lost.", comment: "")
        alert.addButton(withTitle: "Proceed")
        alert.addButton(withTitle: "Cancel")
        
        NSSound.beep()
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL.rootURL)
        }
    }
}

extension AppDelegate:NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let clearMenuMenuItem = menu.items.last!
        let urls = NSDocumentController.shared.recentDocumentURLs
        let menuItems = urls.map {
            NSMenuItem(title: $0.path, action: #selector(openFile(_:)), keyEquivalent: "")
        }
        
        menu.items = [
            menuItems,
            [NSMenuItem.separator(), clearMenuMenuItem]
        ].flatMap({$0})
    }
}
