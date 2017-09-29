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

#import "RLMDescriptions.h"

#import "RLMRealmBrowserWindowController.h"
#import "RLMArrayNavigationState.h"
#import "RLMQueryNavigationState.h"
#import "RLMArrayNode.h"
#import "RLMRealmNode.h"

#import "RLMBadgeTableCellView.h"
#import "RLMBasicTableCellView.h"
#import "RLMBoolTableCellView.h"
#import "RLMNumberTableCellView.h"
#import "RLMImageTableCellView.h"

#import "RLMTableColumn.h"

const NSUInteger kMaxNumberOfArrayEntriesInToolTip = 5;
const NSUInteger kMaxNumberOfStringCharsInObjectLink = 20;
const NSUInteger kMaxNumberOfStringCharsForTooltip = 300;
const NSUInteger kMaxNumberOfInlineStringCharsForTooltip = 20;
const NSUInteger kMaxNumberOfObjectCharsForTable = 200;
const NSUInteger kMaxDepthForTooltips = 2;

typedef NS_ENUM(int32_t, RLMDescriptionFormat) {
    RLMDescriptionFormatEllipsis,
    RLMDescriptionFormatFull,
    RLMDescriptionFormatObject
};

@implementation RLMDescriptions {
    NSDateFormatter *dateFormatter;
    NSNumberFormatter *integerFormatter;
    NSNumberFormatter *floatingPointFormatter;
    NSNumberFormatter *floatingPointTooltipFormatter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        
        integerFormatter = [[NSNumberFormatter alloc] init];
        integerFormatter.numberStyle = NSNumberFormatterDecimalStyle;

        floatingPointFormatter = [[NSNumberFormatter alloc] init];
        floatingPointFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        floatingPointFormatter.minimumFractionDigits = 3;
        floatingPointFormatter.maximumFractionDigits = 3;

        floatingPointTooltipFormatter = [[NSNumberFormatter alloc] init];
        floatingPointTooltipFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        floatingPointTooltipFormatter.minimumFractionDigits = 0;
        floatingPointTooltipFormatter.maximumFractionDigits = NSUIntegerMax;
    }

    return self;
}

-(NSString *)descriptionOfObject:(RLMObject *)object
{
    return [self descriptionOfObject:object format:RLMDescriptionFormatObject];
}

-(NSString *)descriptionOfObject:(RLMObject *)object format:(RLMDescriptionFormat)format
{
    if (object == nil) {
        return @"";
    }

    if (format == RLMDescriptionFormatEllipsis) {
        return [NSString stringWithFormat:@"%@(...)", object.objectSchema.className];
    }

    NSString *returnString = @"(";

    for (RLMProperty *property in object.objectSchema.properties) {
        id propertyValue = object[property.name];
        NSString *propertyDescription = [self printablePropertyValue:propertyValue ofType:property
                                                              format:RLMDescriptionFormatEllipsis];

        if (returnString.length > kMaxNumberOfObjectCharsForTable - 4) {
            returnString = [returnString stringByAppendingFormat:@"..."];
            break;
        }

        returnString = [returnString stringByAppendingFormat:@"%@, ", propertyDescription];
    }

    if ([returnString hasSuffix:@", "]) {
        returnString = [returnString substringToIndex:returnString.length - 2];
    }

    return [returnString stringByAppendingString:@")"];
}

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMProperty *)property
{
    return [self printablePropertyValue:propertyValue ofType:property format:RLMDescriptionFormatFull];
}

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMProperty *)property format:(RLMDescriptionFormat)format
{
    if (!propertyValue) {
        return @"";
    }

    if (property.array) {
        // FIXME: arrays of primitives
        RLMArray *referredArray = (RLMArray *)propertyValue;
        if (format == RLMDescriptionFormatEllipsis) {
            return [NSString stringWithFormat:@"%@[%lu]", referredArray.objectClassName, referredArray.count];
        }

        return [NSString stringWithFormat:@"%@", referredArray.objectClassName];
    }

    switch (property.type) {
        case RLMPropertyTypeInt:
            return [integerFormatter stringFromNumber:propertyValue];
            
            // Intentional fallthrough
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            return [floatingPointFormatter stringFromNumber:propertyValue];
            
        case RLMPropertyTypeString: {
            NSString *stringValue = propertyValue;
            
            if (format == RLMDescriptionFormatEllipsis && stringValue.length > kMaxNumberOfStringCharsInObjectLink) {
                stringValue = [stringValue substringToIndex:kMaxNumberOfStringCharsInObjectLink - 3];
                stringValue = [stringValue stringByAppendingString:@"..."];
            }
            
            return stringValue;
        }
            
        case RLMPropertyTypeBool:
            return [(NSNumber *)propertyValue boolValue] ? @"TRUE" : @"FALSE";
            
        case RLMPropertyTypeDate:
            return [dateFormatter stringFromDate:(NSDate *)propertyValue];
            
        case RLMPropertyTypeData:
            return @"<Data>";
            
        case RLMPropertyTypeAny:
            return @"<Any>";
        
        case RLMPropertyTypeLinkingObjects:
            return @"<LinkingObjects>";
            
        case RLMPropertyTypeObject:
            return [self descriptionOfObject:propertyValue format:format];
    }
}

+(NSString *)typeNameOfProperty:(RLMProperty *)property
{
    if (property.array) {
        // FIXME: arrays of primitives
        return [NSString stringWithFormat:@"[%@]", property.objectClassName];
    }
    switch (property.type) {
        case RLMPropertyTypeInt:
            return [NSString stringWithFormat:@"Int%@", property.optional ? @" (Optional)":@""];
        case RLMPropertyTypeFloat:
            return [NSString stringWithFormat:@"Float%@", property.optional ? @" (Optional)":@""];
        case RLMPropertyTypeDouble:
            return [NSString stringWithFormat:@"Double%@", property.optional ? @" (Optional)":@""];
        case RLMPropertyTypeDate:
            return @"Date";
        case RLMPropertyTypeBool:
            return [NSString stringWithFormat:@"Boolean%@", property.optional ? @" (Optional)":@""];
        case RLMPropertyTypeString:
            return @"String";
        case RLMPropertyTypeData:
            return @"Data";
        case RLMPropertyTypeAny:
            return @"Any";
        case RLMPropertyTypeLinkingObjects:
            return @"LinkingObjects";
        case RLMPropertyTypeObject:
            return [NSString stringWithFormat:@"<%@>", property.objectClassName];
    }
}

-(NSString *)tooltipForPropertyValue:(id)propertyValue ofType:(RLMProperty *)property
{
    if (!propertyValue) {
        return nil;
    }

    if (property.array) {
        return [self tooltipForArray:propertyValue];
    }
    
    switch (property.type) {
        case RLMPropertyTypeString: {
            NSUInteger chars = MIN(kMaxNumberOfStringCharsForTooltip, [(NSString *)propertyValue length]);
            return [(NSString *)propertyValue substringToIndex:chars];
        }
            
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            return [floatingPointTooltipFormatter stringFromNumber:propertyValue];
            
        case RLMPropertyTypeObject:
            return [self tooltipForObject:propertyValue];
            
        case RLMPropertyTypeLinkingObjects:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeInt:
            return nil;
    }
}

- (NSString *)tooltipForObject:(RLMObject *)object
{
    return [self tooltipForObject:object withDepth:0];
}

- (NSString *)tooltipForObject:(RLMObject *)object withDepth:(NSUInteger)depth
{
    if (depth == kMaxDepthForTooltips) {
        return [object.objectSchema.className stringByAppendingString:@"[...]"];
    }
    
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@:\n", object.objectSchema.className];
    NSString *tabs = [@"" stringByPaddingToLength:depth + 1 withString:@"\t" startingAtIndex:0];
    
    for (RLMProperty *property in object.objectSchema.properties) {
        id obj = object[property.name];
        
        NSString *sub;
        if (property.array) {
            sub = [self tooltipForArray:obj withDepth:kMaxDepthForTooltips];
        }
        else if (property.type == RLMPropertyTypeObject) {
            sub = [self tooltipForObject:obj withDepth:depth + 1];
        }
        else {
            sub = [self printablePropertyValue:obj ofType:property];

            if (property.type == RLMPropertyTypeString && sub.length > kMaxNumberOfInlineStringCharsForTooltip) {
                sub = [sub substringToIndex:kMaxNumberOfInlineStringCharsForTooltip];
                sub = [sub stringByAppendingString:@"..."];
            }
        }
        
        [string appendFormat:@"%@%@ = %@\n", tabs, property.name, sub];
    }
    
    return string;
}

- (NSString *)tooltipForArray:(RLMArray *)array
{
    return [self tooltipForArray:array withDepth:0];
}

- (NSString *)tooltipForArray:(RLMArray *)array withDepth:(NSUInteger)depth
{
    // FIXME: arrays of primitives
    if (depth == kMaxDepthForTooltips) {
        return [NSString stringWithFormat:@"<%@>[%lu]", array.objectClassName, array.count];
    }
    
    const NSUInteger maxObjects = 3;
    NSString *tabs = [@"" stringByPaddingToLength:depth withString:@"\t" startingAtIndex:0];
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@<%@>[%lu]", tabs, array.objectClassName, array.count];
    
    if (array.count == 0) {
        return string;
    }
    [string appendString:@":\n"];
    
    NSUInteger index = 0;
    NSUInteger skipped = 0;
    for (id obj in array) {
        NSString *sub = [self tooltipForObject:obj withDepth:depth + 1];
        [string appendFormat:@"%@\t[%lu] %@\n", tabs, index++, sub];
        if (index >= maxObjects) {
            skipped = array.count - maxObjects;
            break;
        }
    }
    
    // Remove last comma and newline characters
    if (array.count > 0) {
        [string deleteCharactersInRange:NSMakeRange(string.length - 1, 1)];
    }
    if (skipped) {
        [string appendFormat:@"\n\t%@+%lu more", tabs, skipped];
    }
    [string appendFormat:@"\n"];
    
    return string;
}

@end
