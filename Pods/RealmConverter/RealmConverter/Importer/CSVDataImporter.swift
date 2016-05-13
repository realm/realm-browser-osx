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
import CSwiftV
import Realm

/**
 Provided a Realm file and an output destination folder,
 `CSVDataExporter` can export the contents of a Realm file
 to a series of CSV files.
 
 A single CSV file is created for each table in the Realm file,
 with strings being escaped in the default CSV standard.
 
 - warning: Presently, relationships between Realm objects are
 not captured in the CSV files.
 */
@objc(RLMCSVDataImporter)
public class CSVDataImporter: DataImporter {

    public override func importToPath(path: String, schema: ImportSchema) throws -> RLMRealm {
        let realm = try! self.createNewRealmFile(path, schema: schema)
        
        for (index, file) in files.enumerate() {
            let schema = schema.schemas[index]

            let inputString = try! NSString(contentsOfFile: file, encoding: encoding.rawValue) as String
            let csv = CSwiftV(string: inputString)

            var generator = csv.rows.generate()
            transactionLoop: while true {
                realm.beginWriteTransaction()
                for _ in 0..<10000 {
                    let cls = NSClassFromString(schema.objectClassName) as! RLMObject.Type
                    let object = cls.init()

                    guard let row = generator.next() else {
                        break transactionLoop
                    }
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
                    
                    realm.addObject(object)
                }
                try realm.commitWriteTransaction()
            }
            try realm.commitWriteTransaction()
        }
    
        return realm
    }
}
