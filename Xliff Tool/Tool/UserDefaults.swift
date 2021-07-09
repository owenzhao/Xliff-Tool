//
//  UserDefaults.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/27.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Foundation
import AppKit

extension UserDefaults {
    enum Key:String {
        case verifyTranslatedResultsFirst
        
        // sidebar
        case showSideBar
        
        // for advanced search options
        case searchSource
        case searchTarget
        case searchNote
        case searchOptionCaseSensitive
    }
    
    static func register() {
        let defaults:[String:Any] = [
            UserDefaults.Key.verifyTranslatedResultsFirst.rawValue: NSControl.StateValue.on.rawValue,
            UserDefaults.Key.showSideBar.rawValue: true,
            UserDefaults.Key.searchSource.rawValue: NSControl.StateValue.on.rawValue,
            UserDefaults.Key.searchTarget.rawValue: NSControl.StateValue.on.rawValue,
            UserDefaults.Key.searchNote.rawValue: NSControl.StateValue.off.rawValue,
            UserDefaults.Key.searchOptionCaseSensitive.rawValue: NSControl.StateValue.off.rawValue,
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
}
