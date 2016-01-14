////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014-2015 Realm Inc.
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

#import "RLMModelExporter.h"
@import Realm;
#import <AppSandboxFileAccess/AppSandboxFileAccess.h>

@implementation RLMModelExporter

#pragma mark - Public methods

+ (void)saveModelsForSchemas:(NSArray *)objectSchemas inLanguage:(RLMModelExporterLanguage)language
{
    void(^saveMultipleFiles)(NSSavePanel *, void(^)()) = ^void(NSSavePanel *panel, void(^completionBlock)()) {
        panel.canCreateDirectories = YES;
        panel.title = [NSString stringWithFormat:@"Save %@ model definitions", [RLMModelExporter stringForLanguage:language]];
        [panel beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton) {
                [panel orderOut:self];
                completionBlock(panel);
            }
        }];
    };

    void(^saveSingleFile)(NSArray *(^)(NSString *)) = ^void(NSArray *(^modelsWithFileName)(NSString *fileName)) {
        NSSavePanel *panel = [NSSavePanel savePanel];
        panel.prompt = @"Save as filename";
        panel.nameFieldStringValue = @"RealmModels";
        saveMultipleFiles(panel, ^{
            NSString *fileName = [[panel.URL lastPathComponent] stringByDeletingPathExtension];
            [self saveModels:modelsWithFileName(fileName) toFolder:[panel.URL URLByDeletingLastPathComponent]];
        });
    };

    switch (language) {
        case RLMModelExporterLanguageJava:
        {
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            panel.prompt = @"Select folder";
            panel.canChooseDirectories = YES;
            panel.canChooseFiles = NO;
            saveMultipleFiles(panel, ^{
                [self saveModels:[self javaModelsOfSchemas:objectSchemas] toFolder:panel.URL];
            });
            break;
        }
        case RLMModelExporterLanguageObjectiveC:
        {
            saveSingleFile(^(NSString *fileName){
                return [self objcModelsOfSchemas:objectSchemas withFileName:fileName];
            });
            break;
        }
        case RLMModelExporterLanguageSwift:
        {
            saveSingleFile(^(NSString *fileName){
                return [self swiftModelsOfSchemas:objectSchemas withFileName:fileName];
            });
            break;
        }
    }
}

#pragma mark - Private methods - Helpers

+(void)saveModels:(NSArray *)models toFolder:(NSURL *)url
{
    AppSandboxFileAccess *fileAccess = [AppSandboxFileAccess fileAccess];
    [fileAccess requestAccessPermissionsForFileURL:url persistPermission:YES withBlock:^(NSURL *securityScopedURL, NSData *bookmarkData) {
        [securityScopedURL startAccessingSecurityScopedResource];
        
        // A 'model' is an array with two strings, a filename plus the contents of that file
        for (NSArray *model in models) {
            NSURL *fileURL = [url URLByAppendingPathComponent:model[0]];
            NSString *fileContents = model[1];
            
            NSError *error;
            BOOL success = [fileContents writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if (!success) {
                NSLog(@"Error writing file at %@\n%@", url, [error localizedFailureReason]);
                [[NSApplication sharedApplication] presentError:error];
            }
        }
        
        [securityScopedURL stopAccessingSecurityScopedResource];
    }];
}

+ (NSString *)stringForLanguage:(RLMModelExporterLanguage)language
{
    switch (language) {
        case RLMModelExporterLanguageJava: return @"Java";
        case RLMModelExporterLanguageObjectiveC: return @"Objective-C";
        case RLMModelExporterLanguageSwift: return @"Swift";
    }
}


#pragma mark - Private methods - Java helpers

+ (NSArray *)javaModelsOfSchemas:(NSArray *)schemas
{
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:schemas.count];

    for (RLMObjectSchema *schema in schemas) {
        NSMutableString *model = [NSMutableString stringWithString:@"package your.package.name.here;\n\nimport io.realm.RealmObject;\n"];

        BOOL importedRealmList = YES;
        NSMutableArray *importedRealmObjects = [[NSMutableArray alloc] init];
        for (RLMProperty *property in schema.properties) {
            if (property.type == RLMPropertyTypeArray) {
                if (!importedRealmList) {
                    [model appendFormat:@"import io.realm.RealmList;\n"];
                    importedRealmList = YES;
                }
                if (![importedRealmObjects containsObject:property.objectClassName]) {
                    [model appendFormat:@"import %@;\n", property.objectClassName];
                    [importedRealmObjects addObject:property.objectClassName];
                }
            } else if (property.type == RLMPropertyTypeObject && ![importedRealmObjects containsObject:property.objectClassName]) {
                [model appendFormat:@"import %@;\n", property.objectClassName];
                [importedRealmObjects addObject:property.objectClassName];
            }
        }

        [model appendFormat:@"\npublic class %@ extends RealmObject {\n", schema.className];

        // fields
        for (RLMProperty *property in schema.properties) {
            if (property.isPrimary) {
                [model appendString:@"    @PrimaryKey\n"];
            } else if (property.indexed) {
                [model appendString:@"    @Index\n"];
            }
            if (!property.optional && [self javaPropertyTypeCanBeMarkedRequired:property.type]) {
                [model appendString:@"    @Required\n"];
            }
            [model appendFormat:@"    private %@ %@;\n", [self javaNameForProperty:property], property.name];
        }
        [model appendFormat:@"\n"];

        // setters and getters
        for (RLMProperty *property in schema.properties) {
            NSString *javaNameForProperty = [self javaNameForProperty:property];
            [model appendFormat:@"    public %@ %@%@() { return %@; }\n\n",
             javaNameForProperty, (property.type == RLMPropertyTypeBool) ? @"is" : @"get",
             [property.name capitalizedString], property.name];
            [model appendFormat:@"    public void set%@(%@ %@) { this.%@ = %@; } \n\n",
             [property.name capitalizedString], javaNameForProperty, property.name, property.name,
             property.name
             ];
        }

        [model appendFormat:@"}\n"];

        [models addObject:@[[schema.className stringByAppendingPathExtension:@"java"], model]];
    }
    
    return models;
}

+ (NSString *)javaNameForProperty:(RLMProperty *)property
{
    switch (property.type) {
        case RLMPropertyTypeBool:
            return @"boolean";
        case RLMPropertyTypeInt:
            return @"int";
        case RLMPropertyTypeFloat:
            return @"float";
        case RLMPropertyTypeDouble:
            return @"double";
        case RLMPropertyTypeString:
            return @"String";
        case RLMPropertyTypeData:
            return @"byte[]";
        case RLMPropertyTypeAny:
            return @"Any";
        case RLMPropertyTypeDate:
            return @"Date";
        case RLMPropertyTypeArray:
            return [NSString stringWithFormat:@"RealmList<%@>", property.objectClassName];
        case RLMPropertyTypeObject:
            return property.objectClassName;
    }
}

+ (BOOL)javaPropertyTypeCanBeMarkedRequired:(RLMPropertyType)type
{
    switch (type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeObject:
            return NO;
        case RLMPropertyTypeString:
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeDate:
            return YES;
    }
}

#pragma mark - Private methods - Objective C helpers

+(NSArray *)objcModelsOfSchemas:(NSArray *)schemas withFileName:(NSString *)fileName
{
    // Filename for h-file
    NSString *hFilename = [fileName stringByAppendingPathExtension:@"h"];
    
    // Contents of h-file
    NSMutableString *hContents= [NSMutableString string];
    [hContents appendFormat:@"#import <Foundation/Foundation.h>\n#import <Realm/Realm.h>\n\n"];
    
    for (RLMObjectSchema *schema in schemas) {
        [hContents appendFormat:@"@class %@;\n", schema.className];
    }
    [hContents appendString: @"\n"];
    
    for (RLMObjectSchema *schema in schemas) {
        [hContents appendFormat:@"RLM_ARRAY_TYPE(%@)\n", schema.className];
    }
    [hContents appendString: @"\n\n"];
    
    for (RLMObjectSchema *schema in schemas) {
        [hContents appendFormat:@"@interface %@ : RLMObject\n\n", schema.className];
        for (RLMProperty *property in schema.properties) {
            [hContents appendFormat:@"@property %@%@;\n", [self objcNameForProperty:property], property.name];
        }
        [hContents appendString:@"\n@end\n\n\n"];
    }
    // An array with filename and contents, i.e. the h-file model
    NSArray *hModel = @[hFilename, hContents];
    
    // Filename for m-file
    NSString *mFilename = [fileName stringByAppendingPathExtension:@"m"];
    
    // Contents of m-file
    NSMutableString *mContents= [NSMutableString string];
    [mContents appendFormat:@"#import \"%@\"\n\n", hFilename];
    for (RLMObjectSchema *schema in schemas) {
        [mContents appendFormat:@"@implementation %@\n\n@end\n\n\n", schema.className];
    }

    // An array with filename and contents, i.e. the m-file model
    NSArray *mModel = @[mFilename, mContents];

    // An aray with models for both files
    return @[hModel, mModel];
}

+(NSString *)objcNameForProperty:(RLMProperty *)property
{
    switch (property.type) {
        case RLMPropertyTypeBool:
            return @"BOOL ";
        case RLMPropertyTypeInt:
            return @"NSInteger ";
        case RLMPropertyTypeFloat:
            return @"float ";
        case RLMPropertyTypeDouble:
            return @"double ";
        case RLMPropertyTypeString:
            return @"NSString *";
        case RLMPropertyTypeData:
            return @"NSData *";
        case RLMPropertyTypeAny:
            return @"id ";
        case RLMPropertyTypeDate:
            return @"NSDate *";
        case RLMPropertyTypeArray:
            return [NSString stringWithFormat:@"RLMArray<%@> *", property.objectClassName];
        case RLMPropertyTypeObject:
            return [NSString stringWithFormat:@"%@ *", property.objectClassName];
    }
}

#pragma mark - Private methods - Swift helpers

+ (NSArray *)swiftModelsOfSchemas:(NSArray *)schemas withFileName:(NSString *)fileName
{
    NSMutableString *contents = [NSMutableString stringWithString:@"import RealmSwift\n\n"];

    for (RLMObjectSchema *schema in schemas) {
        [contents appendFormat:@"class %@: Object {\n", schema.className];
        NSMutableArray<NSString *> *indexedProperties = [NSMutableArray array];
        NSString *primaryKey = nil;

        for (RLMProperty *property in schema.properties) {
            [contents appendFormat:@"  %@\n", [self swiftDefinitionForProperty:property]];
            if (property.isPrimary) {
                primaryKey = property.name;
            } else if (property.indexed) {
                [indexedProperties addObject:property.name];
            }
        }

        if (primaryKey) {
            [contents appendString:@"\n  override static func primaryKey() -> String? {\n"];
            [contents appendFormat:@"    return \"%@\"\n", primaryKey];
            [contents appendString:@"  }\n"];
        }

        if (indexedProperties.count > 0) {
            [contents appendString:@"\n  override static func indexedProperties() -> [String] {\n    return [\n"];
            for (NSString *propertyName in indexedProperties) {
                [contents appendFormat:@"      \"%@\",\n", propertyName];
            }
            [contents appendString:@"    ]\n  }\n"];
        }

        [contents appendString:@"}\n\n"];
    }

    // An array of a single model array with filename and contents
    return @[@[[fileName stringByAppendingPathExtension:@"swift"], contents]];
}

+ (NSString *)swiftDefinitionForProperty:(RLMProperty *)property
{
    NSString *(^namedProperty)(NSString *) = ^NSString *(NSString *formatString) {
        return [NSString stringWithFormat:formatString, property.name];
    };
    NSString *(^objectClassProperty)(NSString *) = ^NSString *(NSString *formatString) {
        return [NSString stringWithFormat:formatString, property.name, property.objectClassName];
    };

    if (property.optional) {
        switch (property.type) {
            case RLMPropertyTypeBool:
                return namedProperty(@"let %@ = RealmOptional<Bool>())");
            case RLMPropertyTypeInt:
                return namedProperty(@"let %@ = RealmOptional<Int>())");
            case RLMPropertyTypeFloat:
                return namedProperty(@"let %@ = RealmOptional<Float>())");
            case RLMPropertyTypeDouble:
                return namedProperty(@"let %@ = RealmOptional<Double>())");
            case RLMPropertyTypeString:
                return namedProperty(@"dynamic var %@: String?");
            case RLMPropertyTypeData:
                return namedProperty(@"dynamic var %@: NSData?");
            case RLMPropertyTypeAny:
                return @"/* Error! 'Any' properties are unsupported in Swift. */";
            case RLMPropertyTypeDate:
                return namedProperty(@"dynamic var %@: NSDate?");
            case RLMPropertyTypeArray:
                return @"/* Error! 'List' properties should never be optional. Please report this by emailing help@realm.io. */";
            case RLMPropertyTypeObject:
                return objectClassProperty(@"dynamic var %@: %@?");
        }
    }

    switch (property.type) {
        case RLMPropertyTypeBool:
            return namedProperty(@"dynamic var %@ = false");
        case RLMPropertyTypeInt:
            return namedProperty(@"dynamic var %@ = 0");
        case RLMPropertyTypeFloat:
            return namedProperty(@"dynamic var %@: Float = 0");
        case RLMPropertyTypeDouble:
            return namedProperty(@"dynamic var %@: Double = 0");
        case RLMPropertyTypeString:
            return namedProperty(@"dynamic var %@ = \"\"");
        case RLMPropertyTypeData:
            return namedProperty(@"dynamic var %@ = NSData()");
        case RLMPropertyTypeAny:
            return @"/* Error! 'Any' properties are unsupported in Swift. */";
        case RLMPropertyTypeDate:
            return namedProperty(@"dynamic var %@ = NSDate()");
        case RLMPropertyTypeArray:
            return objectClassProperty(@"let %@ = List<%@>()");
        case RLMPropertyTypeObject:
            return @"/* Error! 'Object' properties should always be optional. Please report this by emailing help@realm.io. */";
    }
}

@end
