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
import CSwiftV
import PathKit
import TGSpreadsheetWriter

@objc
public enum ImportSchemaFormat : Int {
    case CSV
    case XLSX
}

/**
 `ImportSchemaGenerator` will analyze the contents of files provided
 to it, and intelligently generate a schema definition object
 with which the structure of a Realm file can be created.
 
 This is then used to map the raw data to the appropriate properties
 when performing the import to Realm.
 */
@objc(RLMImportSchemaGenerator)
public class ImportSchemaGenerator : NSObject {
    let files: [String]
    let encoding: Encoding
    let format: ImportSchemaFormat
    
    /**
     Creates a new instance of `ImportSchemaGenerator`, specifying a single
     file with which to import
     
     - parameter file: The absolute file path to the file that will be used to create the schema.
     - parameter encoding: The text encoding used by the file.
     */
    @objc(initWithFile:encoding:)
    public convenience init(file: String, encoding: Encoding = .UTF8) {
        self.init(files: [file], encoding: encoding)
    }
    
    /**
     Creates a new instance of `ImportSchemaGenerator`, specifying a list
     of files to analyze.
     
     - parameter files: An array of absolute file paths to each file that will be used for the schema.
     - parameter encoding: The text encoding used by the file.
     */
    @objc(initWithFiles:encoding:)
    public init(files: [String], encoding: Encoding = .UTF8) {
        self.files = files
        self.encoding = encoding
        self.format = ImportSchemaGenerator.importSchemaFormat(files.first!)
    }
    
    /**
    Processes the contents of each file provided and returns a single `ImportSchema` object
    representing all of those files.
    */
    @objc(generatedSchemaWithError:)
    public func generate() throws -> ImportSchema {
        switch self.format {
        case .CSV:
            return try! generateForCSV()
        case .XLSX:
            return try! generateForXLSX()
        }
    }
    
    private func generateForCSV() throws -> ImportSchema {
        let schemas = files.map { (file) -> ImportObjectSchema in
            let inputString = try! NSString(contentsOfFile: file, encoding: encoding.rawValue) as String
            let csv = CSwiftV(String: inputString)
            
            let schema = ImportObjectSchema(objectClassName: Path(file).lastComponentWithoutExtension)
            
            schema.properties = csv.headers.enumerate().map { (index, field) -> ImportObjectSchema.Property in
                return ImportObjectSchema.Property(column: UInt(index), originalName: field, name: field.camelcaseString)
            }
            
            csv.rows.forEach { (row) -> () in
                row.enumerate().forEach { (index, field) -> () in
                    var property = schema.properties[index]
                    
                    if field.isEmpty {
                        //property.optional = true
                        return
                    }
                    guard property.type == .String else {
                        return
                    }
                    
                    let numberFormatter = NSNumberFormatter()
                    if let number = numberFormatter.numberFromString(field) {
                        let numberType = CFNumberGetType(number)
                        switch (numberType) {
                        case .SInt8Type: fallthrough
                        case .SInt16Type: fallthrough
                        case .SInt32Type: fallthrough
                        case .SInt64Type: fallthrough
                        case .CharType: fallthrough
                        case .ShortType: fallthrough
                        case .IntType: fallthrough
                        case .LongType: fallthrough
                        case .LongLongType: fallthrough
                        case .CFIndexType: fallthrough
                        case .NSIntegerType:
                            if (property.type != .Double) {
                                property.type = .Int;
                            }
                            break;
                        case .Float32Type: fallthrough
                        case .Float64Type: fallthrough
                        case .FloatType: fallthrough
                        case .DoubleType: fallthrough
                        case .CGFloatType:
                            property.type = .Double;
                            break;
                        }
                    } else {
                        property.type = .String
                    }
                }
            }
            
            return schema
        }
        
        return ImportSchema(schemas: schemas)
    }
    
    private func generateForXLSX() throws -> ImportSchema {
        let workbook = TGSpreadsheetWriter.readWorkbook(NSURL(fileURLWithPath: "\(Path(files[0]).absolute())")) as! [String: [[String]]]
        let schemas = workbook.keys.enumerate().map { (index, key) -> ImportObjectSchema in
            let schema = ImportObjectSchema(objectClassName: key.capitalizedString)
            
            if let sheet = workbook[key] {
                if let headers = sheet.first {
                    schema.properties = headers.enumerate().map({ (index, field) -> ImportObjectSchema.Property in
                        return ImportObjectSchema.Property(column: UInt(index), originalName: field, name: field.camelcaseString)
                    })
                }
                
                let rows = sheet.dropFirst()
                rows.forEach { (row) -> () in
                    row.enumerate().forEach { (index, field) -> () in
                        var property = schema.properties[index]
                        
                        if field.isEmpty {
                            //property.optional = true
                            return
                        }
                        guard property.type == .String else {
                            return
                        }
                        
                        let numberFormatter = NSNumberFormatter()
                        if let number = numberFormatter.numberFromString(field) {
                            let numberType = CFNumberGetType(number)
                            switch (numberType) {
                            case .SInt8Type: fallthrough
                            case .SInt16Type: fallthrough
                            case .SInt32Type: fallthrough
                            case .SInt64Type: fallthrough
                            case .CharType: fallthrough
                            case .ShortType: fallthrough
                            case .IntType: fallthrough
                            case .LongType: fallthrough
                            case .LongLongType: fallthrough
                            case .CFIndexType: fallthrough
                            case .NSIntegerType:
                                if (property.type != .Double) {
                                    property.type = .Int;
                                }
                                break;
                            case .Float32Type: fallthrough
                            case .Float64Type: fallthrough
                            case .FloatType: fallthrough
                            case .DoubleType: fallthrough
                            case .CGFloatType:
                                property.type = .Double;
                                break;
                            }
                        } else {
                            property.type = .String
                        }
                    }
                }
            }
            
            return schema
        }
        
        return ImportSchema(schemas: schemas)
    }
    
    private class func importSchemaFormat(file: String) -> ImportSchemaFormat {
        let fileExtension = Path(file).`extension`!.lowercaseString
        if fileExtension == "xlsx" {
            return .XLSX
        }
        
        return .CSV
    }
}
