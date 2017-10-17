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

#import "RLMArrayNode.h"

#import "RLMSidebarTableCellView.h"

@interface RLMProperty (Dynamic)
- (instancetype)initWithName:(NSString *)name
                        type:(RLMPropertyType)type
             objectClassName:(nullable NSString *)objectClassName
      linkOriginPropertyName:(nullable NSString *)linkOriginPropertyName
                     indexed:(BOOL)indexed
                    optional:(BOOL)optional;
@end
@interface RLMObjectSchema (Dynamic)
- (instancetype)initWithClassName:(NSString *)objectClassName objectClass:(Class)objectClass properties:(NSArray *)properties;
@end

// A value which pretends to be an RLMObject representing a row in a non-object array
@interface RLMRowProxy : NSObject
@end
@implementation RLMRowProxy {
    RLMArray *_array;
    NSUInteger _index;
}

+ (instancetype)proxyForArray:(RLMArray *)array row:(NSUInteger)index {
    RLMRowProxy *proxy = [[self alloc] init];
    proxy->_array = array;
    proxy->_index = index;
    return proxy;
}

- (id)objectForKeyedSubscript:(__unused id)subscript {
    return _array[_index];
}
- (void)setObject:(id)value forKeyedSubscript:(__unused id)subscript {
    _array[_index] = value;
}
@end

@implementation RLMArrayNode {
    RLMProperty *_referringProperty;
    RLMObject *_referringObject;
    RLMArray *_displayedArray;
    bool _isObject;
}


#pragma mark - Public Methods

- (instancetype)initWithReferringProperty:(RLMProperty *)property onObject:(RLMObject *)object realm:(RLMRealm *)realm
{
    RLMArray *array = object[property.name];
    RLMObjectSchema *elementSchema;
    if (array.objectClassName) {
        elementSchema = [realm.schema schemaForClassName:array.objectClassName];
    }
    else {
        // Create a fake object schema representing the values of a primitive array
        RLMProperty *prop = [[RLMProperty alloc] initWithName:@"Value"
                                                         type:property.type
                                              objectClassName:nil
                                       linkOriginPropertyName:nil
                                                      indexed:NO
                                                     optional:property.optional];
        elementSchema = [[RLMObjectSchema alloc] initWithClassName:property.name objectClass:RLMObject.class properties:@[prop]];
    }
    if (self = [super initWithSchema:elementSchema inRealm:realm]) {
        _referringProperty = property;
        _referringObject = object;
        _displayedArray = array;
        _isObject = array.objectClassName != nil;
    }

    return self;
}

-(BOOL)insertInstance:(RLMObject *)object atIndex:(NSUInteger)index
{
    if (index > _displayedArray.count || object == nil) {
        return NO;
    }
    
    [_displayedArray insertObject:object atIndex:index];
    return YES;
}

-(BOOL)removeInstanceAtIndex:(NSUInteger)index
{
    if (index >= [_displayedArray count]) {
        return NO;
    }
    
    [_displayedArray removeObjectAtIndex:index];
    return YES;
}

-(BOOL)moveInstanceFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex >= [_displayedArray count] || toIndex > [_displayedArray count]) {
        return NO;
    }

    [_displayedArray moveObjectAtIndex:fromIndex toIndex:toIndex];
    return YES;
}

-(BOOL)isEqualTo:(id)object
{
    if ([object class] != [self class]) {
        return NO;
    }
    
    if (self == object) {
        return YES;
    }
    
    RLMArrayNode *otherArrayNode = object;
    if (self.instanceCount != otherArrayNode.instanceCount) {
        return NO;
    }
    
    for (int i = 0; i < self.instanceCount; i++) {
        if (![_displayedArray[i] isEqualToObject:[otherArrayNode instanceAtIndex:i]]) {
            return NO;
        }
    }
    
    return YES;
}

- (NSString *)objectClassName
{
    return _displayedArray.objectClassName;
}

#pragma mark - RLMTypeNode Overrides

- (NSString *)name
{
    return @"Array";
}

- (NSUInteger)instanceCount
{
    return _displayedArray.count;
}

- (BOOL)isInvalidated
{
    return _displayedArray.isInvalidated;
}

- (BOOL)isObject
{
    return _isObject;
}

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return _isObject ? _displayedArray[index] : [RLMRowProxy proxyForArray:_displayedArray row:index];
}

- (id)nodeElementForColumnWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return [NSString stringWithFormat:@"%@<%@>", _referringProperty.name, _referringProperty.objectClassName];
            
        default:
            return nil;
    }
}

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    RLMSidebarTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    cellView.textField.stringValue = [NSString stringWithFormat:@"%@: <%@>",
                                      _referringProperty.name, _referringProperty.objectClassName];

    cellView.button.title = [NSString stringWithFormat:@"%lu", [self instanceCount]];
    [[cellView.button cell] setHighlightsBy:0];
    cellView.button.hidden = NO;
    
    return cellView;
}

#pragma mark - RLMRealmOutlineNode Implementation

- (BOOL)hasToolTip
{
    return YES;
}

- (NSString *)toolTipString
{
    return _referringObject.description;
}

@end
