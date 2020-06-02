//
//  AppDelegate.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/25.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Cocoa
import Unrealm
import XMLCoder

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
        
        Realm.registerRealmables([
            XTXliff.self,
            XTFile.self,
            XTHeader.self,
            XTTool.self,
            XTBody.self,
            XTTransUnit.self
        ])
        
        print()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !fileOpened {
            openDocument(nil)
        }
        
        openRecentMenu.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(openEditor(_:)), name: DetailViewController.openEditor, object: nil)
    }
    
    @objc private func openEditor(_ noti:Notification) {
        let windowController = NSStoryboard.main?.instantiateController(withIdentifier: "editorWindowController") as? NSWindowController
        let editorViewController = windowController?.contentViewController as? EditorViewController
        let realm = try! Realm(fileURL: databaseURL)
        editorViewController?.transUnits = realm.objects(XTTransUnit.self)
        editorViewController?.files = realm.objects(XTFile.self)
        editorViewController?.updateUI()
        windowController?.window?.center()
        windowController?.showWindow(nil)
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
    
    private func getXliff() -> XTXliff {
        let data = try! Data(contentsOf: xliffURL)
        let decoder = XMLDecoder()
        decoder.trimValueWhitespaces = false
        
        return try! decoder.decode(XTXliff.self, from: data)
    }
    
    private func setupIndexViewController(_ windowController:NSWindowController?, xliff:XTXliff) {
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
    
    private func setupDetailViewController(_ windowController:NSWindowController?, xliff:XTXliff) {
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
    
    private func getIndices(with xliff:XTXliff) -> [(String, Date)] {
        let fm = FileManager.default
        let openURL = URL.rootURL
        
        if !fm.fileExists(atPath: openURL.path) {
            try! fm.createDirectory(at: openURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        let urls = try! fm.contentsOfDirectory(at: openURL, includingPropertiesForKeys: [.nameKey, .contentModificationDateKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        
        let xliffFileIds = xliff.files.map { $0.id }
        var array:[(String, Date)] = urls.filter({ $0.path.hasSuffix(".realm") })
            .filter({ !self.fileIdsInterSection(from: $0, to: xliffFileIds).isEmpty })
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
        let realm = try! Realm(fileURL: url)
        let originalFileIdSet = Set(realm.objects(XTFile.self).map { $0.id })
        
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
        xliffURL = URL(fileURLWithPath: menuItem.title)
        addToOpenRecent()
        setupUI()
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
