////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import Realm

@objc(RLMImportObjectSchema)
public class ImportObjectSchema: NSObject {
    public var objectClassName: String
    var properties: [ImportObjectSchema.Property] = []
    
    init(objectClassName: String) {
        self.objectClassName = objectClassName
        super.init()
    }
    
    func toJSON() -> [String: AnyObject] {
        let fields = properties.map { (property) -> [String: AnyObject] in
            return property.toJSON()
        }
        return ["fields": fields, "primaryKey": NSNull()]
    }
    
    struct Property {
        let column: UInt
        let originalName: String
        let name: String
        var type: RLMPropertyType = .String
        var indexed: Bool = false
        var optional: Bool = false
        
        init(column: UInt, originalName: String, name: String) {
            self.column = column
            self.originalName = originalName
            self.name = name
        }
        
        func toJSON() -> [String: AnyObject] {
            var field = [String: AnyObject]()
            field["column"] = column
            field["originalName"] = originalName
            field["name"] = name
            field["type"] = "\(type)"
            field["indexed"] = indexed
            field["optional"] = optional
            
            return field
        }
    }
}

extension ImportObjectSchema {
    
    override public var description: String {
        let data = try! NSJSONSerialization.dataWithJSONObject(toJSON() as NSDictionary, options: .PrettyPrinted)
        return NSString(data: data, encoding: NSUTF8StringEncoding) as! String
    }
    
    override public var debugDescription: String {
        return description
    }
    
}

// MARK: - String Extension for Realm PropertyType -
extension RLMPropertyType : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: Swift.String {
        switch self {
        case .Int:
            return "integer"
        case .Bool:
            return "boolean"
        case .Float:
            return "float"
        case .Double:
            return "double"
        case .String:
            return "string"
        case .Data:
            return "data"
        case .Any:
            return "any"
        case .Date:
            return "date"
        case .Object:
            return "object"
        case .Array:
            return "array"
        }
    }
    
    public var debugDescription: Swift.String {
        return description
    }
    
}