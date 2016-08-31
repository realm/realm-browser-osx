//
//  RLMWindowController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 30/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

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
