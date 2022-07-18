//
//  XliffEscapeCharacters.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2022/4/23.
//  Copyright © 2022 zhaoxin. All rights reserved.
//

import Foundation

enum XliffEscapeCharacters:String, CaseIterable {
    case lessThan = "<"
    case greaterThan = ">"
    case ampersand = "&"
    
    var escapedString:String {
        switch self {
        case .lessThan:
            return "&lt;"
        case .greaterThan:
            return "&gt;"
        case .ampersand:
            return "&amp;"
        }
    }
}