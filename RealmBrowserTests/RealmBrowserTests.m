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

@import XCTest;
@import Realm;
@import Realm.Private;
@import Realm.Dynamic;
#import "RLMTestObjects.h"
#import "RLMTestDataGenerator.h"
#import "RLMRealmNode.h"

@interface RealmBrowserTests : XCTestCase

@end

@implementation RealmBrowserTests

- (NSURL *)urlForGeneratedTestRealmWithClassNames:(NSArray *)classNames count:(NSInteger)count encryptionKey:(NSData *)encryptionKey
{
    NSString *fileName = [NSString stringWithFormat:@"%@.realm", [[NSUUID UUID] UUIDString]];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    @autoreleasepool {
        BOOL success = [RLMTestDataGenerator createRealmAtUrl:fileURL withClassesNamed:classNames objectCount:count encryptionKey:encryptionKey];
        XCTAssertEqual(YES, success);
    }
    
    return fileURL;
}

- (void)testGenerateDemoDatabase
{
    NSURL *fileURL = [self urlForGeneratedTestRealmWithClassNames:@[[RealmObject1 className]] count:10 encryptionKey:nil];
    XCTAssertNotNil(fileURL);
                      
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithPath:fileURL.path
                                          key:nil
                                     readOnly:NO
                                     inMemory:NO
                                      dynamic:YES
                                       schema:nil
                                        error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(realm);
    XCTAssertEqual(10, [[realm allObjects:[RealmObject1 className]] count]);
}

- (void)testDoesNotShowObjectsWithNoPersistedProperties {
    NSURL *fileURL = [self urlForGeneratedTestRealmWithClassNames:@[[RealmObjectWithoutStoredProperties className]] count:10 encryptionKey:nil];
    XCTAssertNotNil(fileURL);
    
    NSError *error = nil;
    RLMRealmNode *realmNode = [[RLMRealmNode alloc] initWithName:@"name" url:fileURL.path];
    XCTAssertTrue([realmNode connect:&error]);
    XCTAssertNil(error);
    XCTAssertNotNil(realmNode.topLevelClasses);
    for (RLMClassNode *node in realmNode.topLevelClasses) {
        XCTAssertNotEqualObjects(@"RealmObjectWithoutStoredProperties", node.name);
    }
}

- (void)testEncryptedRealmNode
{
    NSMutableData *key = [NSMutableData dataWithLength:64];
    SecRandomCopyBytes(kSecRandomDefault, key.length, (uint8_t *)key.mutableBytes);
    
    NSURL *fileURL = [self urlForGeneratedTestRealmWithClassNames:@[[RealmObject1 className]] count:10 encryptionKey:key];
    XCTAssertNotNil(fileURL);
    
    RLMRealmNode *testNode = [[RLMRealmNode alloc] initWithName:@"Test Realm" url:fileURL.path];
    XCTAssertNotNil(testNode);
    
    //Ensure the Realm file was successfully processed by the node object
    XCTAssertTrue([testNode.name isEqualToString:@"Test Realm"]);
    
    //Check to make sure the encrypted Realm DOES NOT open without the key
    XCTAssertFalse([testNode connect:nil]);
    
    //Pass the encryption key to the node
    testNode.encryptionKey = key;
    
    //Ensure the data in the Realm file is accessible
    NSLog(@"Classes %@",testNode.topLevelClasses);
    XCTAssertNotNil(testNode.topLevelClasses);
}


@end
