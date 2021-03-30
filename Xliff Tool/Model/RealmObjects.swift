//
//  RealmObjects.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2020/5/25.
//  Copyright © 2020 zhaoxin. All rights reserved.
//

import Foundation
import RealmSwift
import XMLCoder


class RLMXTXliff:Object, Codable, DynamicNodeEncoding {
    @objc dynamic var xmlns:String = ""
    @objc dynamic var xmlnsXsi:String = ""
    @objc dynamic var version:String = ""
    @objc dynamic var xsiSchemaLocation:String = ""
    let files = List<RLMXTFile>()
    
    enum CodingKeys: String, CodingKey {
        case xmlns
        case xmlnsXsi = "xmlns:xsi"
        case version
        case xsiSchemaLocation = "xsi:schemaLocation"
        case files = "file"
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        xmlns = try values.decode(String.self, forKey: .xmlns)
        xmlnsXsi = try values.decode(String.self, forKey: .xmlnsXsi)
        version = try values.decode(String.self, forKey: .version)
        xsiSchemaLocation = try values.decode(String.self, forKey: .xsiSchemaLocation)
        let files = try values.decode([RLMXTFile].self, forKey: .files)
        self.files.append(objectsIn: files)
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case RLMXTXliff.CodingKeys.xmlns:
            return .attribute
        case RLMXTXliff.CodingKeys.xmlnsXsi:
            return .attribute
        case RLMXTXliff.CodingKeys.version:
            return .attribute
        case RLMXTXliff.CodingKeys.xsiSchemaLocation:
            return .attribute
        default:
            return .element
        }
    }
}

class RLMXTFile:Object, Codable, DynamicNodeEncoding {
    static func == (lhs: RLMXTFile, rhs: RLMXTFile) -> Bool {
        return lhs.id == rhs.id
    }
    
    required override init() {
        super.init()
        
        id = "\(original);\(sourceLanguage);\(targetLanguage);\(dataType)"
    }
    
    @objc dynamic var original:String = ""
    @objc dynamic var sourceLanguage:String = ""
    @objc dynamic var targetLanguage:String = ""
    @objc dynamic var dataType:String = ""
    @objc dynamic var header:RLMXTHeader? = nil
    @objc dynamic var body:RLMXTBody? = nil
    
    @objc dynamic var id:String = ""
    
    enum CodingKeys: String, CodingKey {
        case original
        case sourceLanguage = "source-language"
        case targetLanguage = "target-language"
        case dataType = "datatype"
        case header
        case body
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        original = try values.decode(String.self, forKey: .original)
        sourceLanguage = try values.decode(String.self, forKey: .sourceLanguage)
        targetLanguage = try values.decode(String.self, forKey: .targetLanguage)
        dataType = try values.decode(String.self, forKey: .dataType)
        header = try values.decode(RLMXTHeader.self, forKey: .header)
        body = try values.decode(RLMXTBody.self, forKey: .body)
        
        id = "\(original);\(sourceLanguage);\(targetLanguage);\(dataType)"
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case RLMXTFile.CodingKeys.original:
            return .attribute
        case RLMXTFile.CodingKeys.sourceLanguage:
            return .attribute
        case RLMXTFile.CodingKeys.targetLanguage:
            return .attribute
        case RLMXTFile.CodingKeys.dataType:
            return .attribute
        default:
            return .element
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class RLMXTHeader:Object, Codable {
    @objc dynamic var tool:RLMXTTool? = nil
}

class RLMXTTool:Object, Codable, DynamicNodeEncoding {
    @objc dynamic var toolId:String = ""
    @objc dynamic var toolName:String = ""
    @objc dynamic var toolVersion:String = ""
    @objc dynamic var buildNumber:String = ""
    
    enum CodingKeys: String, CodingKey {
        case toolId = "tool-id"
        case toolName = "tool-name"
        case toolVersion = "tool-version"
        case buildNumber = "build-num"
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
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

class RLMXTBody:Object, Codable {
    let transUnits = List<RLMXTTransUnit>()
    
    enum CodingKeys: String, CodingKey {
        case transUnits = "trans-unit"
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let transUnits = try values.decode([RLMXTTransUnit].self, forKey: .transUnits)
        self.transUnits.append(objectsIn: transUnits)
    }
    
    let files = LinkingObjects(fromType: RLMXTFile.self, property: "body")
}

class RLMXTTransUnit:Object, Codable, DynamicNodeEncoding {
    static func == (lhs: RLMXTTransUnit, rhs: RLMXTTransUnit) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    @objc dynamic var id:String = ""
    @objc dynamic var xmlSpace:String = ""
    @objc dynamic var source:String = ""
    @objc dynamic var target:String? = nil
    @objc dynamic var note:String? = nil
    
    @objc dynamic var uid:String = UUID().uuidString
    @objc dynamic var isVerified: Bool = false
    
    let bodies = LinkingObjects(fromType: RLMXTBody.self, property: "transUnits")
    
    enum CodingKeys: String, CodingKey {
        case id
        case xmlSpace = "xml:space"
        case source
        case target
        case note
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
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
        case RLMXTTransUnit.CodingKeys.id:
            return .attribute
        case RLMXTTransUnit.CodingKeys.xmlSpace:
            return .attribute
        default:
            return .element
        }
    }
    
    override static func primaryKey() -> String? {
        return "uid"
    }
}
