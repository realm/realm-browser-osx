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

@interface RLMModelExporter ()

+ (NSString *)stringForLanguage:(RLMModelExporterLanguage)language;

@end

@implementation RLMModelExporter

#pragma mark - Public methods

+ (void)saveModelsForSchemas:(NSArray *)objectSchemas inLanguage:(RLMModelExporterLanguage)language
{
    NSString *dialogTitle = [NSString stringWithFormat:@"Save %@ model definitions", [RLMModelExporter stringForLanguage:language]];
    
    if (language == RLMModelExporterLanguageJava) {
        NSOpenPanel *fileDialog = [NSOpenPanel openPanel];
        
        fileDialog.prompt = @"Select folder";
        fileDialog.canChooseDirectories = YES;
        fileDialog.canChooseFiles = NO;
        fileDialog.canCreateDirectories = YES;
        fileDialog.title = dialogTitle;
        [fileDialog beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton) {
                [fileDialog orderOut:self];
                NSArray *models = [self javaModelsOfSchemas:objectSchemas];
                [self saveModels:models toFolder:fileDialog.URL];
            }
        }];
    }
    else if (language == RLMModelExporterLanguageObjectiveC) {
        NSSavePanel *fileDialog = [NSSavePanel savePanel];
        fileDialog.prompt = @"Save as filename";
        fileDialog.nameFieldStringValue = @"RealmModels";
        fileDialog.canCreateDirectories = YES;
        fileDialog.title = dialogTitle;
        [fileDialog beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton) {
                [fileDialog orderOut:self];
                NSString *fileName = [[fileDialog.URL lastPathComponent] stringByDeletingPathExtension];
                NSArray *models = [self objcModelsOfSchemas:objectSchemas withFileName:fileName];
                [self saveModels:models toFolder:[fileDialog.URL URLByDeletingLastPathComponent]];
            }
        }];
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

#pragma mark - Private methods - Java helpers

+(NSArray *)javaModelsOfSchemas:(NSArray *)schemas
{
    NSMutableArray *models = [NSMutableArray array];
    
    for (RLMObjectSchema *schema in schemas) {
        NSString *fileName = [schema.className stringByAppendingPathExtension:@"java"];
        
        NSMutableString *model = [NSMutableString string];
        [model appendFormat:@"package your.package.name.here;\n\nimport io.realm.RealmObject;\n"];
        for (RLMProperty *property in schema.properties) {
            if (property.type == RLMPropertyTypeArray) {
                [model appendFormat:@"import io.realm.RealmList;\n"];
                break; // one import is enough
            }
        }
        [model appendFormat:@"\n"];

        [model appendFormat:@"public class %@ extends RealmObject {\n", schema.className];

        // fields
        for (RLMProperty *property in schema.properties) {
            [model appendFormat:@"    private %@ %@;\n", [self javaNameForProperty:property], property.name];
        }
        [model appendFormat:@"\n"];

        // setters and getters
        for (RLMProperty *property in schema.properties) {
            [model appendFormat:@"    public %@ get%@() { return %@; }\n\n",
             [self javaNameForProperty:property], [property.name capitalizedString], property.name];
            [model appendFormat:@"    public void set%@(%@ %@) { this.%@ = %@; } \n\n",
               [property.name capitalizedString], [self javaNameForProperty:property], property.name, property.name,
               property.name
             ];
        }

        [model appendFormat:@"}\n"];

        [models addObject:@[fileName, model]];
    }
    
    return models;
}

+(NSString *)javaNameForProperty:(RLMProperty *)property
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
            return [NSString stringWithFormat:@"%@", property.objectClassName];
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

+ (NSString *)stringForLanguage:(RLMModelExporterLanguage)language
{
    switch (language) {
        case RLMModelExporterLanguageJava: return @"Java";
        default: return @"Objective-C";
    }
    
    return nil;
}

@end
