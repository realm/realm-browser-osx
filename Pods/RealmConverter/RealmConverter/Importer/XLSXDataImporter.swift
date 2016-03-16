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
import PathKit
import Realm
import TGSpreadsheetWriter

@objc(RLMXLSXDataImporter)
public class XLSXDataImporter: DataImporter {

    public override func importToPath(path: String, schema: ImportSchema) throws -> RLMRealm {
        let realm = try! self.createNewRealmFile(path, schema: schema)
        
        let workbook = TGSpreadsheetWriter.readWorkbook(NSURL(fileURLWithPath: "\(Path(files[0]).absolute())")) as! [String: [[String]]]
        for (index, key) in workbook.keys.enumerate() {
            let schema = schema.schemas[index]
            
            if let sheet = workbook[key] {
                let rows = sheet.dropFirst()
                for row in rows {
                    let cls = NSClassFromString(schema.objectClassName) as! RLMObject.Type
                    let object = cls.init()
                    
                    row.enumerate().forEach { (index, field) -> () in
                        let property = schema.properties[index]
                        
                        switch property.type {
                        case .Int:
                            if let number = Int64(field) {
                                object.setValue(NSNumber(longLong: number), forKey: property.originalName)
                            }
                        case .Double:
                            if let number = Double(field) {
                                object.setValue(NSNumber(double: number), forKey: property.originalName)
                            }
                        default:
                            object.setValue(field, forKey: property.originalName)
                        }
                    }
                    
                    try realm.transactionWithBlock { () -> Void in
                        realm.addObject(object)
                    }
                }
            }
        }
        
        return realm
    }
}