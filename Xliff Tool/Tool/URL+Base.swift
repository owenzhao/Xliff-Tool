//
//  URL+Base.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/27.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Foundation

extension URL {
    static let rootURL:URL = {
        let folderName = "databases"
        return createDirectory(for: folderName)
    }()
    
    static let backupRootURL:URL = {
        let folderName = "databases/backups"
        return createDirectory(for: folderName)
    }()
    
    static private func createDirectory(for folderName:String) -> URL {
        let fm = FileManager.default
        let baseURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = URL(fileURLWithPath: folderName, relativeTo: baseURL)
        
        if !fm.fileExists(atPath: folderURL.path) {
            try! fm.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return folderURL
    }
}
