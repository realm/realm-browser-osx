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

@import AppSandboxFileAccess;
@import Realm;
@import Realm.Private;

@implementation NSString (Indentation)

- (NSString *)indentedBy:(NSInteger)indent {
    if (indent <= 0) {
        return self;
    }

    NSString *tmp = [self stringByReplacingOccurrencesOfString:@"\n" withString:@"\n "];

    return [[@" " stringByAppendingString:tmp] indentedBy:indent - 1];
}

@end

@implementation RLMModelExporter

#pragma mark - Public methods

+ (void)saveModelsForSchemas:(NSArray *)objectSchemas inLanguage:(RLMModelExporterLanguage)language window:(NSWindow *)window
{
    void(^saveMultipleFiles)(NSSavePanel *, void(^)()) = ^void(NSSavePanel *panel, void(^completionBlock)()) {
        [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton) {
                [panel orderOut:self];
                completionBlock(panel);
            }
        }];
    };

    void(^saveSingleFile)(NSArray *(^)(NSString *)) = ^void(NSArray *(^modelsWithFileName)(NSString *fileName)) {
        NSSavePanel *panel = [NSSavePanel savePanel];
        panel.prompt = @"Save";
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
            panel.canCreateDirectories = YES;
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
        case RLMModelExporterLanguageJavaScript:
        {
            saveSingleFile(^(NSString *fileName){
                return [self javaScriptModelsOfSchemas:objectSchemas withFileName:fileName];
            });
            break;
        }
        case RLMModelExporterLanguageCSharp:
        {
            saveSingleFile(^(NSString *fileName){
                return [self cSharpModelsOfSchemas:objectSchemas withFileName:fileName];
            });
            break;
        }
    }
}

#pragma mark - Private methods - Helpers

+ (void)saveModels:(NSArray *)models toFolder:(NSURL *)url
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

#pragma mark - Private methods - Java helpers

+ (NSArray *)javaModelsOfSchemas:(NSArray *)schemas
{
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:schemas.count];

    for (RLMObjectSchema *schema in schemas) {
        // imports
        NSMutableOrderedSet *realmImports = [NSMutableOrderedSet orderedSetWithArray:@[@"io.realm.RealmObject"]];
        NSMutableOrderedSet *objectImports = [NSMutableOrderedSet orderedSet];
        for (RLMProperty *property in schema.properties) {
            if (property.array) {
                [realmImports addObject:@"io.realm.RealmList"];
            }
            if (property.type == RLMPropertyTypeObject) {
                [objectImports addObject:property.objectClassName];
            }
            if (property.isPrimary) {
                [realmImports addObject:@"io.realm.annotations.PrimaryKey"];
            } else if (property.indexed) {
                [realmImports addObject:@"io.realm.annotations.Index"];
            }
            if (!property.optional && [self javaPropertyTypeCanBeMarkedRequired:property.type]) {
                [realmImports addObject:@"io.realm.annotations.Required"];
            }
        }

        NSMutableString *model = [NSMutableString stringWithString:@"package your.package.name.here;\n\n"];
        for (NSString *import in realmImports) {
            [model appendFormat:@"import %@;\n", import];
        }
        for (NSString *import in objectImports) {
            [model appendFormat:@"import %@;\n", import];
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
    if (property.array) {
        switch (property.type) {
            case RLMPropertyTypeBool:
                return @"RealmList<Boolean>";
            case RLMPropertyTypeInt:
                return @"RealmList<Long>";
            case RLMPropertyTypeFloat:
                return @"RealmList<Float>";
            case RLMPropertyTypeDouble:
                return @"RealmList<Double>";
            case RLMPropertyTypeString:
                return @"RealmList<String>";
            case RLMPropertyTypeData:
                return @"RealmList<byte[]>";
            case RLMPropertyTypeDate:
                return @"RealmList<Date>";
            case RLMPropertyTypeObject:
                return [NSString stringWithFormat:@"RealmList<%@>", property.objectClassName];
            default:
                return @"Unsupported Type";
        }
    }
    switch (property.type) {
        case RLMPropertyTypeBool:
            return property.optional ? @"Boolean" : @"boolean";
        case RLMPropertyTypeInt:
            return property.optional ? @"Long" : @"long";
        case RLMPropertyTypeFloat:
            return property.optional ? @"Float" : @"float";
        case RLMPropertyTypeDouble:
            return property.optional ? @"Double" : @"double";
        case RLMPropertyTypeString:
            return @"String";
        case RLMPropertyTypeData:
            return @"byte[]";
        case RLMPropertyTypeAny:
            return @"Any";  // FIXME: we don't support it
        case RLMPropertyTypeDate:
            return @"Date";
        case RLMPropertyTypeObject:
            return property.objectClassName;
        case RLMPropertyTypeLinkingObjects:
            return @"RealmList";
    }

    return nil;
}

+ (BOOL)javaPropertyTypeCanBeMarkedRequired:(RLMPropertyType)type
{
    switch (type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeObject:
            return NO;
        case RLMPropertyTypeString:
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeLinkingObjects:
            return YES;
    }

    return NO;
}

#pragma mark - Private methods - Objective-C helpers

+ (NSArray *)objcModelsOfSchemas:(NSArray *)schemas withFileName:(NSString *)fileName
{
    // Filename for h-file
    NSString *hFilename = [fileName stringByAppendingPathExtension:@"h"];

    // Contents of h-file
    NSMutableString *hContents= [NSMutableString stringWithFormat:@"#import <Foundation/Foundation.h>\n#import <Realm/Realm.h>\n\n"];
    for (RLMObjectSchema *schema in schemas) {
        [hContents appendFormat:@"@interface %@ : RLMObject\n@end\n\n", schema.className];
    }
    [hContents appendString:@"\n"];

    for (RLMObjectSchema *schema in schemas) {
        [hContents appendFormat:@"RLM_ARRAY_TYPE(%@)\n", schema.className];
    }
    [hContents appendString:@"\n\n"];

    [hContents appendString:@"NS_ASSUME_NONNULL_BEGIN\n\n"];

    for (RLMObjectSchema *schema in schemas) {
        [hContents appendFormat:@"@interface %@()\n\n", schema.className];
        for (RLMProperty *property in schema.properties) {
            [hContents appendFormat:@"@property %@%@%@;\n", property.optional ? @"(nullable) " : @"", [self objcNameForProperty:property], property.name];
        }
        [hContents appendString:@"\n@end\n\n"];
    }

    [hContents appendString:@"NS_ASSUME_NONNULL_END\n"];

    // An array with filename and contents for the h-file model
    NSArray *hModel = @[hFilename, hContents];

    // Contents of m-file
    NSMutableString *mContents = [NSMutableString stringWithFormat:@"#import \"%@\"\n\n", hFilename];
    for (RLMObjectSchema *schema in schemas) {
        [mContents appendFormat:@"@implementation %@\n", schema.className];

        NSArray *requiredProperties = [[schema.properties filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RLMProperty *property, __unused NSDictionary *bindings) {
            return !property.optional && [self objcPropertyTypeIsOptionalByDefault:property.type];
        }]] valueForKey:@"name"];
        if (requiredProperties.count > 0) {
            [mContents appendString:@"\n+ (NSArray<NSString *> *)requiredProperties {\n    return @[\n"];
            for (NSString *requiredProperty in requiredProperties) {
                [mContents appendFormat:@"        @\"%@\",\n", requiredProperty];
            }
            [mContents appendString:@"    ];\n}\n"];
        }

        NSString *primaryKey = [[[schema.properties filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isPrimary == YES"]] firstObject] name];
        if (primaryKey) {
            [mContents appendFormat:@"\n+ (NSString *)primaryKey {\n    return @\"%@\";\n}\n", primaryKey];
        }

        NSArray *indexedProperties = [[schema.properties filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isPrimary == NO && indexed == YES"]] valueForKey:@"name"];
        if (indexedProperties.count > 0) {
            [mContents appendString:@"\n+ (NSArray<NSString *> *)indexedProperties {\n    return @[\n"];
            for (NSString *indexedProperty in indexedProperties) {
                [mContents appendFormat:@"        @\"%@\",\n", indexedProperty];
            }
            [mContents appendString:@"    ];\n}\n"];
        }

        [mContents appendString:@"\n@end\n\n\n"];
    }

    // An array with filename and contents for the m-file model
    NSArray *mModel = @[[fileName stringByAppendingPathExtension:@"m"], mContents];

    // An aray with models for both files
    return @[hModel, mModel];
}

+ (NSString *)objcNameForProperty:(RLMProperty *)property
{
    if (property.array) {
        switch (property.type) {
            case RLMPropertyTypeBool:
                return @"RLMArray<NSNumber *><RLMBool> *";
            case RLMPropertyTypeInt:
                return @"RLMArray<NSNumber *><RLMInt> *";
            case RLMPropertyTypeFloat:
                return @"RLMArray<NSNumber *><RLMFloat> *";
            case RLMPropertyTypeDouble:
                return @"RLMArray<NSNumber *><RLMDouble> *";
            case RLMPropertyTypeString:
                return @"RLMArray<NSString *><RLMString> *";
            case RLMPropertyTypeData:
                return @"RLMArray<NSData *><RLMData> *";
            case RLMPropertyTypeAny:
                return @"id ";
            case RLMPropertyTypeDate:
                return @"RLMArray<NSDate *><RLMDate> *";
            case RLMPropertyTypeObject:
                return [NSString stringWithFormat:@"RLMArray<%@ *><%@> *", property.objectClassName, property.objectClassName];
            case RLMPropertyTypeLinkingObjects:
                return @"RLMLinkingObjects *";
        }
    }
    switch (property.type) {
        case RLMPropertyTypeBool:
            return property.optional ? @"NSNumber<RLMBool> *" : @"BOOL ";
        case RLMPropertyTypeInt:
            return property.optional ? @"NSNumber<RLMInt> *" :  @"NSInteger ";
        case RLMPropertyTypeFloat:
            return property.optional ? @"NSNumber<RLMFloat> *" : @"float ";
        case RLMPropertyTypeDouble:
            return property.optional ? @"NSNumber<RLMDouble> *" : @"double ";
        case RLMPropertyTypeString:
            return @"NSString *";
        case RLMPropertyTypeData:
            return @"NSData *";
        case RLMPropertyTypeAny:
            return @"id ";
        case RLMPropertyTypeDate:
            return @"NSDate *";
        case RLMPropertyTypeObject:
            return [NSString stringWithFormat:@"%@ *", property.objectClassName];
        case RLMPropertyTypeLinkingObjects:
            return @"RLMLinkingObjects *";
    }
}

+ (BOOL)objcPropertyTypeIsOptionalByDefault:(RLMPropertyType)type
{
    switch (type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            return NO;
        case RLMPropertyTypeString:
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeObject:
        case RLMPropertyTypeLinkingObjects:
            return YES;
    }

    return NO;
}

#pragma mark - Private methods - Swift helpers

+ (NSArray *)swiftModelsOfSchemas:(NSArray *)schemas withFileName:(NSString *)fileName
{
    NSMutableString *contents = [NSMutableString stringWithString:@"import Foundation\nimport RealmSwift\n\n"];

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

    if (property.array) {
        NSString *type;
        switch (property.type) {
            case RLMPropertyTypeBool:   type = @"Bool"; break;
            case RLMPropertyTypeInt:    type = @"Int"; break;
            case RLMPropertyTypeFloat:  type = @"Float"; break;
            case RLMPropertyTypeDouble: type = @"Double"; break;
            case RLMPropertyTypeString: type = @"String"; break;
            case RLMPropertyTypeData:   type = @"NSData"; break;
            case RLMPropertyTypeDate:   type = @"NSDate"; break;
            case RLMPropertyTypeObject: type = property.objectClassName;
            case RLMPropertyTypeAny: return @"/* Error! 'Any' properties are unsupported in Swift. */";
            case RLMPropertyTypeLinkingObjects: return @"";
        }
        return [NSString stringWithFormat:@"let %@ = List<%@%s>()", property.name, type,
                property.optional && property.type != RLMPropertyTypeObject ? "?" : ""];
    }

    if (property.optional) {
        switch (property.type) {
            case RLMPropertyTypeBool:
                return namedProperty(@"let %@ = RealmOptional<Bool>()");
            case RLMPropertyTypeInt:
                return namedProperty(@"let %@ = RealmOptional<Int>()");
            case RLMPropertyTypeFloat:
                return namedProperty(@"let %@ = RealmOptional<Float>()");
            case RLMPropertyTypeDouble:
                return namedProperty(@"let %@ = RealmOptional<Double>()");
            case RLMPropertyTypeString:
                return namedProperty(@"dynamic var %@: String?");
            case RLMPropertyTypeData:
                return namedProperty(@"dynamic var %@: NSData?");
            case RLMPropertyTypeAny:
                return @"/* Error! 'Any' properties are unsupported in Swift. */";
            case RLMPropertyTypeDate:
                return namedProperty(@"dynamic var %@: NSDate?");
            case RLMPropertyTypeObject:
                return objectClassProperty(@"dynamic var %@: %@?");
            case RLMPropertyTypeLinkingObjects:
                return @"";
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
        case RLMPropertyTypeObject:
            return @"/* Error! 'Object' properties should always be optional. Please report this by emailing help@realm.io. */";
        case RLMPropertyTypeLinkingObjects:
            return @"";
    }

    return nil;
}

#pragma mark - Private methods - JavaScript helpers

+ (NSArray *)javaScriptModelsOfSchemas:(NSArray *)schemas withFileName:(NSString *)fileName
{
    NSMutableString *contents = [NSMutableString string];
    NSMutableString *exports = [NSMutableString stringWithString:@"module.exports = {\n"];

    for (RLMObjectSchema *schema in schemas) {
        NSString *schemaName = [schema.className stringByAppendingString:@"Schema"];
        [exports appendFormat:@"  %@", schemaName];
        [exports appendFormat:@"%@", (schema != [schemas lastObject]) ? @",\n" : @"\n"];

        [contents appendFormat:@"const %@ = {\n", schemaName];
        [contents appendFormat:@"  name: '%@',\n", schema.className];
        NSMutableString *properties = [NSMutableString stringWithString:@"  properties: {\n"];
        NSString *primaryKey = nil;

        for (RLMProperty *property in schema.properties) {
            if (property.isPrimary) {
                primaryKey = property.name;
            }
            [properties appendString:[self javaScriptDefinitionForProperty:property]];
            [properties appendFormat:@"%@", (property != [schema.properties lastObject]) ? @",\n" : @"\n"];

        }

        [properties appendString:@"  }\n"];

        if (primaryKey) {
            [contents appendFormat:@"  primaryKey: '%@',\n", primaryKey];
        }

        [contents appendString:properties];
        [contents appendString:@"};\n\n"];
    }

    [exports appendString:@"};\n"];
    [contents appendString:exports];

    // An array of a single model array with filename and contents
    return @[@[[fileName stringByAppendingPathExtension:@"js"], contents]];
}

+ (NSString *)javaScriptDefinitionForProperty:(RLMProperty *)property
{
    NSMutableDictionary *props = [NSMutableDictionary dictionary];

    switch (property.type) {
        case RLMPropertyTypeBool:
            props[@"type"] = @"bool";
            break;
        case RLMPropertyTypeInt:
            props[@"type"] = @"int";
            break;
        case RLMPropertyTypeFloat:
            props[@"type"] = @"float";
            break;
        case RLMPropertyTypeDouble:
            props[@"type"] = @"double";
            break;
        case RLMPropertyTypeString:
            props[@"type"] = @"string";
            break;
        case RLMPropertyTypeData:
            props[@"type"] = @"data";
            break;
        case RLMPropertyTypeAny:
            break;
        case RLMPropertyTypeDate:
            props[@"type"] = @"date";
            break;
        case RLMPropertyTypeObject:
        case RLMPropertyTypeLinkingObjects:
            props[@"type"] = property.objectClassName;
            break;
    }

    if (property.array) {
        props[@"type"] = [props[@"type"] stringByAppendingString:@"[]"];
    }

    if (property.indexed && !property.isPrimary) {
        props[@"indexed"] = @"true";
    }

    if (property.optional) {
        props[@"optional"] = @"true";
    }

    if ([props count] == 1) {
        return [NSString stringWithFormat:@"    %@: '%@'", property.name, props[@"type"]];
    }

    NSMutableString *definition = [NSMutableString stringWithFormat:@"    %@: {", property.name];
    NSInteger count = props.count, check = 0;
    for (NSString *key in props) {
        NSString *value = [NSString stringWithFormat:@"'%@'", props[key]];
        if ([key isEqualToString:@"indexed"] || [key isEqualToString:@"optional"]) {
            value = [props objectForKey:key];
        }
        [definition appendFormat:@" %@: %@%@", key, value, (++check == count) ? @" }" : @", "];
    }

    return definition;
}

#pragma mark - Private methods - C# helpers

+ (NSArray *)cSharpModelsOfSchemas:(NSArray *)schemas withFileName:(NSString *)fileName {
    NSMutableString *contents = [NSMutableString stringWithString:@"using System;\nusing System.Collections.Generic;\nusing Realms;\n\n"];

    for (RLMObjectSchema *schema in schemas) {
        [contents appendFormat:@"public class %@ : RealmObject\n{\n", schema.className];

        for (RLMProperty *property in schema.properties) {
            [contents appendFormat:@"%@\n\n", [[self cSharpDefinitionForProperty:property] indentedBy:4]];
        }

        // Delete extra newline
        [contents deleteCharactersInRange:NSMakeRange(contents.length - 1, 1)];

        [contents appendString:@"}\n\n"];
    }

    // Delete extra newline
    [contents deleteCharactersInRange:NSMakeRange(contents.length - 1, 1)];

    return @[@[[fileName stringByAppendingPathExtension:@"cs"], contents]];
}

+ (NSString *)cSharpDefinitionForProperty:(RLMProperty *)property {
    NSMutableString *definition = [NSMutableString string];

    BOOL(^typeOptionalByDefault)(RLMPropertyType) = ^BOOL(RLMPropertyType type) {
        switch (type) {
            case RLMPropertyTypeString:
            case RLMPropertyTypeData:
            case RLMPropertyTypeObject:
                return true;
            default:
                return false;
        }
    };

    NSString *(^valueType)(NSString *, BOOL) = ^NSString *(NSString *typename, BOOL optional) {
        return [typename stringByAppendingString:optional ? @"?" : @""];
    };

    if (property.isPrimary) {
        [definition appendString:@"[PrimaryKey]\n"];
    }

    if (property.type == RLMPropertyTypeLinkingObjects) {
        [definition appendFormat:@"[Backlink(nameof(%@.%@))]\n", property.objectClassName, property.linkOriginPropertyName];
    }

    if (!property.optional && typeOptionalByDefault(property.type)) {
        [definition appendString:@"[Required]\n"];
    }

    NSString *type;
    NSString *access = @"get; set;";

    switch (property.type) {
        case RLMPropertyTypeBool:
            type = valueType(@"bool", property.optional);
            break;
        case RLMPropertyTypeInt:
            type = valueType(@"long", property.optional);
            break;
        case RLMPropertyTypeFloat:
            type = valueType(@"float", property.optional);
            break;
        case RLMPropertyTypeDouble:
            type = valueType(@"double", property.optional);
            break;
        case RLMPropertyTypeString:
            type = @"string";
            break;
        case RLMPropertyTypeData:
            type = @"byte[]";
            break;
        case RLMPropertyTypeAny:
            break;
        case RLMPropertyTypeDate:
            type = valueType(@"DateTimeOffset", property.optional);
            break;
        case RLMPropertyTypeObject:
            type = property.objectClassName;
            break;
        case RLMPropertyTypeLinkingObjects:
            type = [NSString stringWithFormat:@"IQueryable<%@>", property.objectClassName];
            access = @"get;";
            break;
    }
    if (property.array && property.type != RLMPropertyTypeLinkingObjects) {
        type = [NSString stringWithFormat:@"IList<%@>", type];
        access = @"get;";
    }

    [definition appendFormat:@"public %@ %@ { %@ }", type, property.name, access];

    return definition;
}

@end
