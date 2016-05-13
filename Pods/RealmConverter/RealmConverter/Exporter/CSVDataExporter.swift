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
import Realm.Private
import Realm.Dynamic
import PathKit

/**
 Provided a Realm file and an output destination folder,
 `CSVDataExporter` can export the contents of a Realm file
 to a series of CSV files.
 
 A single CSV file is created for each table in the Realm file,
 with strings being escaped in the default CSV standard.
*/
@objc(RLMCSVDataExporter)
public class CSVDataExporter: DataExporter {
    
    /**
     The delimiter symbol used to separate each property on each row.
     Defaults to the CSV standard ',' comma.
     */
    public var delimiter        = ","
    
    /**
     When it's necessary to escape a Realm property on a CSV row, this is the escape symbol
     Defaults to the CSV standard '"' double-quotes.
     */
    public var escapeQuotes     = "\""
    
    /**
     Takes the provided Realm file and exports each table to a CSV file in the provided
     output folder.
     
     - parameter outputFolderpath: An absolute path to a folder where the transformed files will be saved
     */
    public override func exportToFolderAtPath(outputFolderPath: String) throws {
        
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.fileURL = NSURL(fileURLWithPath: realmFilePath)
        realmConfiguration.dynamic = true
        
        let realm = try RLMRealm(configuration: realmConfiguration)
        
        // Write out a .csv file for each object in the Realm
        for objectSchema in realm.schema.objectSchema {
            let filePath = Path(outputFolderPath) + Path("\(objectSchema.className).csv")
            
            if filePath.exists {
                try filePath.delete()
            }
            
            // Build the initial row of property names and write to disk
            try filePath.write(
                objectSchema.properties.map({ $0.name }).joinWithSeparator(delimiter) + "\n"
            )
            
            // Write the remaining objects
            let fileHandle = NSFileHandle(forWritingAtPath: String(filePath))
            fileHandle?.seekToEndOfFile()
            
            let objects = realm.allObjects(objectSchema.className)
            
            // Loop through each object in the table
            for object in (0..<objects.count).map({ objects.objectAtIndex($0) as RLMObject }) {
                let rowString = objectSchema.properties.map({ property in
                    guard let value = object[property.name] else {
                        return ""
                    }
                    if let value = value as? RLMObject {
                        return serializedObject(value, realm: realm)!
                    } else if let value = value as? RLMArray {
                        return serializedObjectArray(value, realm: realm)!
                    }
                    return sanitizedValue(value.description!)
                }).joinWithSeparator(delimiter) + "\n"
                
                fileHandle?.writeData(rowString.dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            fileHandle?.closeFile()
        }
    }
    
    private func sanitizedValue(value: String) -> String {
        func valueByEscapingQuotes(string: String) -> String {
            return escapeQuotes + string + escapeQuotes
        }
        
        // Value already contains quotes, replace with 2 sets of quotes
        if value.rangeOfString(escapeQuotes) != nil {
            return valueByEscapingQuotes(
                value.stringByReplacingOccurrencesOfString(escapeQuotes, withString: escapeQuotes + escapeQuotes)
            )
        } else if value.rangeOfString(" ") != nil || value.rangeOfString(delimiter) != nil {
            return valueByEscapingQuotes(value)
        }
        return value
    }
    
    private func serializedObject(object: RLMObject, realm: RLMRealm) -> String? {
        let className = object.objectSchema.className
        let allObjects = realm.allObjects(className)
        let index = Int(allObjects.indexOfObject(object))
        if index == NSNotFound {
            return nil
        }
        
        return "<\(className)>{\(index)}"
    }
    
    private func serializedObjectArray(array: RLMArray, realm: RLMRealm) -> String? {
        if array.count == 0 {
            return nil
        }
        
        let className = array.objectClassName
        let allObjects = realm.allObjects(className)
        
        return "<\(className)>{" + (0..<array.count).map({ arrayIndex in
            let tableIndex = allObjects.indexOfObject(array.objectAtIndex(arrayIndex))
            
            if Int(tableIndex) != NSNotFound {
                return "\(tableIndex)"
            }
            return ""
        }).joinWithSeparator("") + "}"
    }
}
