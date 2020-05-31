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
        case skipTranslatedResults
    }
    
    static func register() {
        let defaults:[String:Any] = [
            UserDefaults.Key.skipTranslatedResults.rawValue: NSControl.StateValue.off.rawValue
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
}
