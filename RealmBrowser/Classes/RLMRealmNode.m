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

#import "RLMRealmNode.h"

@import Realm;
@import Realm.Private;
@import Realm.Dynamic;

#import "RLMSidebarTableCellView.h"
#import "NSColor+ByteSizeFactory.h"

@implementation RLMRealmNode

- (instancetype)init
{
    return self = [self initWithName:@"Unknown name"
                                 url:@"Unknown location"];
}

- (instancetype)initWithName:(NSString *)name url:(NSString *)url
{
    if (self = [super init]) {
        _name = name;
        _url = url;        
    }
    return self;
}

- (void)dealloc
{
    _realm = nil;
}

- (BOOL)connect:(NSError **)error
{
    NSError *localError;
    _realm = [RLMRealm realmWithPath:_url
                                 key:self.encryptionKey
                            readOnly:NO
                            inMemory:NO
                             dynamic:YES
                              schema:nil
                               error:&localError];

    if (localError) {
        NSLog(@"Realm was opened with error: %@", localError);
    }
    else {
        _topLevelClasses = [self constructTopLevelClasses];    
    }

    if (error) {
        *error = localError;
    }
    
    return !localError;
}


- (void)addTable:(RLMClassNode *)table
{

}

- (void)setEncryptionKey:(NSData *)encryptionKey
{
    if (encryptionKey == _encryptionKey)
        return;
    
    _realm = nil;
    _encryptionKey = encryptionKey;
    [self connect:nil];
}

- (BOOL)realmFileRequiresFormatUpgrade
{
    NSError *localError;
    [RLMRealm realmWithPath:_url
                      key:self.encryptionKey
                 readOnly:NO
                 inMemory:NO
                  dynamic:YES
                   schema:nil
     disableFormatUpgrade:YES
                    error:&localError];
    
    if (localError && localError.code == RLMErrorFileFormatUpgradeRequired) {
        return YES;
    }
    
    return NO;
}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isRootNode
{
    return YES;
}

- (BOOL)isExpandable
{
    return self.topLevelClasses.count != 0;
}

- (NSUInteger)numberOfChildNodes
{
    return self.topLevelClasses.count;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return self.topLevelClasses[index];
}

- (BOOL)hasToolTip
{
    return YES;
}

- (NSString *)toolTipString
{
    return _url;
}

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    NSTextField *result = [tableView makeViewWithIdentifier:@"HeaderLabel" owner:self];
    [result setStringValue:@"CLASSES"];
    
    return result;
}

#pragma mark - Private methods

- (NSArray *)constructTopLevelClasses
{
    RLMSchema *realmSchema = _realm.schema;
    NSArray *objectSchemas = realmSchema.objectSchema;

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:objectSchemas.count];
    
    for (RLMObjectSchema *objectSchema in objectSchemas) {
        if (objectSchema.properties.count > 0) {
            RLMClassNode *tableNode = [[RLMClassNode alloc] initWithSchema:objectSchema inRealm:_realm];
            [result addObject:tableNode];
        }
    }

    [result sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];

    return result;
}

@end
