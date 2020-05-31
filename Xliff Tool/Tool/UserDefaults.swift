//
//  UserDefaults.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/27.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum Key:String {
        case skipVerifiedResults
        case skipTranslatedResults
    }
    
    static func register() {
        let defaults:[String:Any] = [
            UserDefaults.Key.skipVerifiedResults.rawValue : true,
            UserDefaults.Key.skipTranslatedResults.rawValue: false
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
}
