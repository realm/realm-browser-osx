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

@import Cocoa;

#import "RLMRealmNode.h"

typedef NS_ENUM(NSInteger, RLMDocumentState) {
    RLMDocumentStateRequiresFormatUpgrade,
    RLMDocumentStateNeedsEncryptionKey,
    RLMDocumentStateNeedsValidCredentials,
    RLMDocumentStateLoading,
    RLMDocumentStateLoaded
};

@interface RLMDocument : NSDocument

@property (nonatomic, readonly) BOOL potentiallyEncrypted;
@property (nonatomic, readonly) BOOL potentiallySync;
@property (nonatomic, strong) IBOutlet RLMRealmNode *presentedRealm;

@property (nonatomic, copy) NSURL *syncURL;

- (instancetype)initWithContentsOfFileURL:(NSURL *)fileURL error:(NSError **)outError;
- (instancetype)initWithContentsOfSyncURL:(NSURL *)syncURL credential:(RLMCredential *)credential error:(NSError **)outError;

- (BOOL)loadWithError:(NSError * __autoreleasing *)error;
- (void)loadWithCompletionHandler:(void (^)(NSError *error))completionHandler;

@end
