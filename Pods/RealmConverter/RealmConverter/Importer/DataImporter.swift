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

/**
 An abstract class manages the common logic for
 setting up objects that can take a group of files,
 and convert them into a new Realm file.
 */
@objc (RLMDataImporter)
public class DataImporter: NSObject {
    public let files: [String]
    public let encoding: Encoding
    
    /**
     Creates a new instance of `DataImporter`, taking a single
     file that will be converted into a Realm file.
     
     - parameter file: An absolute path to the file that will be imported
     - paramter encoding: The text encoding of the file being imported
     */
    @objc(initWithFile:encoding:)
    convenience public init(file: String, encoding: Encoding = .UTF8) {
        self.init(files: [file], encoding: encoding)
    }
    
    /**
     Creates a new instance of `DataImporter`, taking an array of files
     that will be converted into a Realm file.
     
     - parameter files: An array of absolute paths to the files to import
     - paramter encoding: The text encoding of the file being imported
     */
    @objc(initWithFiles:encoding:)
    public init(files: [String], encoding: Encoding = .UTF8) {
        self.files = files
        self.encoding = encoding
    }
    
    /**
     Creates a new, empty Realm file, formatted with the schema properties
     provided with the provided `ImportSchema` object.
     
     - parameter output: An absolute path to the folder that will hold the new Realm file
     - parameter schema: The import schema with which this file will be created
     */
    @objc(createNewRealmFileAtPath:withSchema:error:)
    public func createNewRealmFile(output: String, schema: ImportSchema) throws -> RLMRealm {
        var generatedClasses: [AnyObject] = []
        
        for schema in schema.schemas {
            let superclassName = "RLMObject"
            
            let className = schema.objectClassName
            
            if let cls = objc_getClass(className) as? AnyClass {
                objc_disposeClassPair(cls)
            }
            let cls = objc_allocateClassPair(NSClassFromString(superclassName), className, 0) as! RLMObject.Type

            schema.properties.reverse().forEach { (property) -> () in
                let type: objc_property_attribute_t
                let size: Int
                let alignment: UInt8
                let encode: String
                
                switch property.type {
                case .Int:
                    type = objc_property_attribute_t(name: "T".cStringUsingEncoding(NSUTF8StringEncoding), value: "i".cStringUsingEncoding(NSUTF8StringEncoding))
                    size = sizeof(Int64)
                    alignment = UInt8(log2(Double(size)))
                    encode = "q"
                case .Double:
                    type = objc_property_attribute_t(name: "T".cStringUsingEncoding(NSUTF8StringEncoding), value: "d".cStringUsingEncoding(NSUTF8StringEncoding))
                    size = sizeof(Double)
                    alignment = UInt8(log2(Double(size)))
                    encode = "d"
                default:
                    type = objc_property_attribute_t(name: "T".cStringUsingEncoding(NSUTF8StringEncoding), value: "@\"NSString\"".cStringUsingEncoding(NSUTF8StringEncoding))
                    size = sizeof(NSObject)
                    alignment = UInt8(log2(Double(size)))
                    encode = "@"
                }
                
                class_addIvar(cls, property.originalName, size, alignment, encode)
                
                let ivar = objc_property_attribute_t(name: "V".cStringUsingEncoding(NSUTF8StringEncoding), value: property.name.cStringUsingEncoding(NSUTF8StringEncoding)!)
                let attrs = [type, ivar]
                class_addProperty(cls, property.originalName, attrs, 2)
                
                let imp = imp_implementationWithBlock(unsafeBitCast({ () -> Bool in
                    return true
                    } as @convention(block) () -> (Bool), AnyObject.self))
                class_addMethod(cls, #selector(NSObjectProtocol.respondsToSelector(_:)), imp, "b@::")
            }
            
            objc_registerClassPair(cls);
            
            let imp = imp_implementationWithBlock(unsafeBitCast({ () -> NSArray in
                return schema.properties.filter { !$0.optional }.map { $0.originalName }
                } as @convention(block) () -> (NSArray), AnyObject.self))
            class_addMethod(objc_getMetaClass(className) as! AnyClass, #selector(RLMObject.requiredProperties), imp, "@16@0:8")
            
            generatedClasses.append(cls)
        }
        
        let configuration = RLMRealmConfiguration()
        configuration.fileURL = NSURL(fileURLWithPath: (output as NSString).stringByAppendingPathComponent("default.realm"))
        configuration.objectClasses = generatedClasses
        let realm = try RLMRealm(configuration: configuration)
        
        print("Exported \(generatedClasses.count) classes")
        
        return realm
    }
    
    /**
     An abstract method, overidden in subclasses that performs the data import
     into the Realm file.
     
     -parameter schema: The import schema with which this file will be created
     */
    @objc(importToPath:withSchema:error:)
    func importToPath(path: String, schema: ImportSchema) throws -> RLMRealm {
        fatalError("import() can not be called on the base data importer class")
    }
}