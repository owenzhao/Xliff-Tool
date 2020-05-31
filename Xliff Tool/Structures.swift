//
//  Structures.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/25.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Foundation
import XMLCoder
import Unrealm

class XTXliff:Codable, DynamicNodeEncoding, Realmable {
    required init() {
        
    }
    
    var xmlns:String = ""
    var xmlnsXsi:String = ""
    var version:String = ""
    var xsiSchemaLocation:String = ""
    var files:[XTFile] = []
    
    enum CodingKeys: String, CodingKey {
        case xmlns
        case xmlnsXsi = "xmlns:xsi"
        case version
        case xsiSchemaLocation = "xsi:schemaLocation"
        case files = "file"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        xmlns = try values.decode(String.self, forKey: .xmlns)
        xmlnsXsi = try values.decode(String.self, forKey: .xmlnsXsi)
        version = try values.decode(String.self, forKey: .version)
        xsiSchemaLocation = try values.decode(String.self, forKey: .xsiSchemaLocation)
        files = try values.decode([XTFile].self, forKey: .files)
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case XTXliff.CodingKeys.xmlns:
            return .attribute
        case XTXliff.CodingKeys.xmlnsXsi:
            return .attribute
        case XTXliff.CodingKeys.version:
            return .attribute
        case XTXliff.CodingKeys.xsiSchemaLocation:
            return .attribute
        default:
            return .element
        }
    }
}

class XTFile:Codable, DynamicNodeEncoding, Realmable, Equatable, Hashable {
    static func == (lhs: XTFile, rhs: XTFile) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    required init() {
        id = "\(original);\(sourceLanguage);\(targetLanguage);\(dataType)"
    }
    
    var original:String = ""
    var sourceLanguage:String = ""
    var targetLanguage:String = ""
    var dataType:String = ""
    var header:XTHeader? = nil
    var body:XTBody? = nil
    
    var id:String
    
    enum CodingKeys: String, CodingKey {
        case original
        case sourceLanguage = "source-language"
        case targetLanguage = "target-language"
        case dataType = "datatype"
        case header
        case body
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        original = try values.decode(String.self, forKey: .original)
        sourceLanguage = try values.decode(String.self, forKey: .sourceLanguage)
        targetLanguage = try values.decode(String.self, forKey: .targetLanguage)
        dataType = try values.decode(String.self, forKey: .dataType)
        header = try values.decode(XTHeader.self, forKey: .header)
        body = try values.decode(XTBody.self, forKey: .body)
        
        id = "\(original);\(sourceLanguage);\(targetLanguage);\(dataType)"
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case XTFile.CodingKeys.original:
            return .attribute
        case XTFile.CodingKeys.sourceLanguage:
            return .attribute
        case XTFile.CodingKeys.targetLanguage:
            return .attribute
        case XTFile.CodingKeys.dataType:
            return .attribute
        default:
            return .element
        }
    }
    
    static func primaryKey() -> String? {
        return "id"
    }
}

class XTHeader:Codable, Realmable {
    required init() {
        
    }
    
    var tool:XTTool? = nil
}

class XTTool:Codable, DynamicNodeEncoding, Realmable {
    required init() {
        
    }
    
    var toolId:String = ""
    var toolName:String = ""
    var toolVersion:String = ""
    var buildNumber:String = ""
    
    enum CodingKeys: String, CodingKey {
        case toolId = "tool-id"
        case toolName = "tool-name"
        case toolVersion = "tool-version"
        case buildNumber = "build-num"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        toolId = try values.decode(String.self, forKey: .toolId)
        toolName = try values.decode(String.self, forKey: .toolName)
        toolVersion = try values.decode(String.self, forKey: .toolVersion)
        buildNumber = try values.decode(String.self, forKey: .buildNumber)
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .attribute
    }
}

class XTBody:Codable, Realmable {
    required init() {
        
    }
    
    var transUnits:[XTTransUnit] = []
    
    enum CodingKeys: String, CodingKey {
        case transUnits = "trans-unit"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transUnits = try values.decode([XTTransUnit].self, forKey: .transUnits)
    }
}

class XTTransUnit:Codable, DynamicNodeEncoding, Realmable, Equatable {
    static func == (lhs: XTTransUnit, rhs: XTTransUnit) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    required init() {
        uid = UUID().uuidString
    }
    
    var id:String = ""
    var xmlSpace:String = ""
    var source:String = ""
    var target:String? = nil
    var note:String? = nil
    
    var uid:String
    var isVerified: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case xmlSpace = "xml:space"
        case source
        case target
        case note
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        xmlSpace = try values.decode(String.self, forKey: .xmlSpace)
        source = try values.decode(String.self, forKey: .source)
        target = try? values.decode(String.self, forKey: .target)
        note = try? values.decode(String.self, forKey: .note)
        
        uid = UUID().uuidString
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case XTTransUnit.CodingKeys.id:
            return .attribute
        case XTTransUnit.CodingKeys.xmlSpace:
            return .attribute
        default:
            return .element
        }
    }
    
    static func primaryKey() -> String? {
        return "uid"
    }
}
