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

#import <Cocoa/Cocoa.h>

@interface RLMSyncWindowController : NSWindowController

@property (nonatomic, weak) IBOutlet NSTextField *urlTextField;
@property (nonatomic, weak) IBOutlet NSTextField *signedUserTokenTextField;
@property (nonatomic, weak) IBOutlet NSButton *okayButton;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, weak) IBOutlet NSTextField *errorTextField;

@property (readonly) NSString *serverURL;
@property (readonly) NSString *serverSignedUserToken;

@property (nonatomic, readonly) NSString *realmFilePath;

- (instancetype)initWithTempRealmFile;
- (instancetype)initWithRealmFilePath:(NSURL *)realmFilePath;

@property (nonatomic, copy) void (^OKButtonClickedHandler)(void);
@property (nonatomic, copy) void (^windowClosedHandler)(void);

@end
