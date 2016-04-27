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

#import "RLMRealmFileManager.h"
#import "RLMSidebarTableCellView.h"
#import "NSColor+ByteSizeFactory.h"

void RLMClearRealmCache();

@interface RLMRealmNode ()

@property (nonatomic, strong) RLMNotificationToken  *notificationToken;
@property (nonatomic, strong) NSRunLoop *notificationRunLoop;
@property (nonatomic, strong) RLMRealmConfiguration *realmConfiguration;
@property (nonatomic, strong) RLMRealm *internalRealmForSync;
@property (assign) BOOL didInitialRefresh;

@end

@implementation RLMRealmNode
@synthesize topLevelClasses = _topLevelClasses;
@synthesize realm = _realm;

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
    [self registerChangeNotification:NO schemaLoadedCallBack:nil error:nil];
}

- (BOOL)connect:(NSError **)error schemaLoadedCallBack:(RLMSchemaLoadedCallback)callback
{
    NSError *localError;
    
    [self registerChangeNotification:YES schemaLoadedCallBack:callback error:&localError];
    
    if (localError) {
        NSLog(@"Realm was opened with error: %@", localError);
    }

    if (error) {
        *error = localError;
    }
    
    return !localError;
}

- (void)registerChangeNotification:(BOOL)registerNotifications
              schemaLoadedCallBack:(RLMSchemaLoadedCallback)callback
                             error:(NSError **)error
{
    if (registerNotifications) {
        typeof(self) __weak weakSelf = self;
        
        // Setup run loop
        if (!self.notificationRunLoop) {
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
                    weakSelf.notificationRunLoop = [NSRunLoop currentRunLoop];
                    
                    dispatch_semaphore_signal(sem);
                });
                
                CFRunLoopRun();
            });
            
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        }
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);        
        
        CFRunLoopPerformBlock(self.notificationRunLoop.getCFRunLoop, kCFRunLoopDefaultMode, ^{
            if (weakSelf.notificationToken) {
                [weakSelf.notificationToken stop];
                weakSelf.notificationToken = nil;
                weakSelf.internalRealmForSync = nil;
            }
            
            RLMRealm *realm = [RLMRealm realmWithConfiguration:weakSelf.realmConfiguration error:error];
            
            if (realm) {
                weakSelf.internalRealmForSync = realm;
                weakSelf.notificationToken = [realm addNotificationBlock:^(NSString * _Nonnull notification,
                                                                           RLMRealm * _Nonnull realm) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // The first notification means the schema is loaded so fire callback
                        if (!weakSelf.didInitialRefresh) {
                            weakSelf.didInitialRefresh = YES;
                            
                            [weakSelf setupAfterSchemaLoad];
                            
                            if (callback) {
                                callback();
                            }
                        }
                        else { // All other notifications call the registered notification block
                            if (weakSelf.notificationBlock) {
                                RLMRealm *aRealm = [RLMRealm realmWithConfiguration:weakSelf.realmConfiguration error:error];
                                weakSelf.notificationBlock(notification, aRealm);
                            }
                        }
                    });
                }];
            }
            dispatch_semaphore_signal(sem);
        });
        
        CFRunLoopWakeUp(self.notificationRunLoop.getCFRunLoop);
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        // Stop sync service if we didn't connect after 5 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!weakSelf.didInitialRefresh) {
                [weakSelf registerChangeNotification:NO schemaLoadedCallBack:nil error:nil];
            }
        });
    }
    else if (self.notificationRunLoop) {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        RLMNotificationToken __weak *token = self.notificationToken;
        CFRunLoopPerformBlock(self.notificationRunLoop.getCFRunLoop, kCFRunLoopDefaultMode, ^{
            [token stop];
            dispatch_semaphore_signal(sem);
        });
        CFRunLoopWakeUp(self.notificationRunLoop.getCFRunLoop);
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        CFRunLoopStop(self.notificationRunLoop.getCFRunLoop);
        
        self.notificationRunLoop = nil;
        self.notificationToken = nil;
        self.internalRealmForSync = nil;
    }
}

- (void)setupAfterSchemaLoad
{
    _realm = [RLMRealm realmWithConfiguration:self.realmConfiguration error:nil];
    _topLevelClasses = [self constructTopLevelClasses];
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
    
    // Is this necessary?
    [self connect:nil schemaLoadedCallBack:nil];
}

- (BOOL)realmFileRequiresFormatUpgrade
{
    NSError *localError;
    
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.disableFormatUpgrade = YES;
    configuration.dynamic = YES;
    configuration.encryptionKey = self.encryptionKey;
    configuration.path = _url;
    [RLMRealm realmWithConfiguration:configuration error:&localError];
    
    if (localError && localError.code == RLMErrorFileFormatUpgradeRequired) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Getters

- (RLMRealmConfiguration *)realmConfiguration
{
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.encryptionKey = self.encryptionKey;
    configuration.path = _url;
    configuration.dynamic = YES;
    configuration.customSchema = nil;
    
    if (self.syncSignedUserToken.length) {
        configuration.syncUserToken = self.syncSignedUserToken;
    }
    
    if (self.syncServerURL) {
        configuration.syncServerURL = [NSURL URLWithString:self.syncServerURL];
    }
    
    return configuration;
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
    RLMRealm *realm = self.realm;
    RLMSchema *realmSchema = realm.schema;
    NSArray *objectSchemas = realmSchema.objectSchema;

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:objectSchemas.count];
    
    for (RLMObjectSchema *objectSchema in objectSchemas) {
        if (objectSchema.properties.count > 0) {
            RLMClassNode *tableNode = [[RLMClassNode alloc] initWithSchema:objectSchema inRealm:realm];
            [result addObject:tableNode];
        }
    }

    [result sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];

    return result;
}

@end
