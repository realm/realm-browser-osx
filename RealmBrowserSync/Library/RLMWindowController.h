////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

typedef NS_ENUM(NSInteger, RLMWindowDisplayMode) {
    RLMWindowDisplayModeNone,
    RLMWindowDisplayModeNormal,
    RLMWindowDisplayModeModal,
    RLMWindowDisplayModeSheet
};

typedef void (^RLMShowWindowCompletionHandler)(NSModalResponse returnCode);

@interface RLMWindowController : NSWindowController<NSWindowDelegate>

@property (getter=isWindowVisible, readonly) BOOL windowVisible;
@property (nonatomic, readonly) RLMWindowDisplayMode displayMode;

+ (NSString *)defaultNibName;

- (void)showWindow:(id)sender completionHandler:(RLMShowWindowCompletionHandler)completionHandler;
- (void)showSheetForWindow:(NSWindow *)window completionHandler:(RLMShowWindowCompletionHandler)completionHandler;
- (NSModalResponse)showWindowModal:(id)sender;

- (void)closeWithReturnCode:(NSModalResponse)code;

- (IBAction)closeWindow:(id)sender;

@end
