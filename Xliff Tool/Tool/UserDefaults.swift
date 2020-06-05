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
    }
    
    static func register() {
        let defaults:[String:Any] = [
            UserDefaults.Key.verifyTranslatedResultsFirst.rawValue: NSControl.StateValue.on.rawValue,
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
}
