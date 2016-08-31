//
//  RLMWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 30/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMWindowController.h"

static NSString * const RLMWindowControllerClassPrefix = @"RLM";
static NSString * const RLMWindowControllerClassSyffix = @"Controller";

@interface RLMWindowController ()

@property (nonatomic, copy) RLMShowWindowCompletionHandler completionHandler;
@property (nonatomic, readwrite) RLMWindowDisplayMode displayMode;

@end

@implementation RLMWindowController

+ (NSString *)defaultNibName {
    NSString* nibName = NSStringFromClass(self);

    if ([nibName hasPrefix:RLMWindowControllerClassPrefix]) {
        nibName = [nibName substringFromIndex:RLMWindowControllerClassPrefix.length];
    }

    if ([nibName hasSuffix:RLMWindowControllerClassSyffix]) {
        nibName = [nibName substringToIndex:nibName.length - RLMWindowControllerClassSyffix.length];
    }

    return nibName;
}

- (instancetype)init {
    return [self initWithWindowNibName:[self.class defaultNibName]];
}

- (instancetype)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];

    if (self != nil) {
        self.displayMode = RLMWindowDisplayModeNone;
    }

    return self;
}

- (BOOL)windowVisible {
    if (!self.windowLoaded) {
        return NO;
    }

    return self.window.visible;
}

#pragma mark - Default Window

- (void)showWindow:(id)sender {
    self.displayMode = RLMWindowDisplayModeNormal;

    [super showWindow:sender];
}

- (void)showWindow:(id)sender completionHandler:(RLMShowWindowCompletionHandler)completionHandler {
    self.completionHandler = completionHandler;

    [self showWindow:sender];
}

- (void)closeWindowWithReturnCode:(NSModalResponse)returnCode {
    [super close];

    if (self.completionHandler != nil) {
        self.completionHandler(returnCode);
        self.completionHandler = nil;
    }
}

#pragma mark - Sheet

- (void)showSheetForWindow:(NSWindow *)window completionHandler:(RLMShowWindowCompletionHandler)completionHandler {
    self.displayMode = RLMWindowDisplayModeSheet;

    [window beginSheet:self.window completionHandler:completionHandler];
}

- (void)closeSheetWithReturnCode:(NSModalResponse)returnCode {
    [self.window.sheetParent endSheet:self.window returnCode:returnCode];
}

#pragma mark - Modal Window

- (NSModalResponse)showWindowModal:(id)sender {
    [self.window center];

    self.displayMode = RLMWindowDisplayModeModal;

    return [NSApp runModalForWindow:self.window];
}

- (void)closeModalWindowWithReturnCode:(NSModalResponse)returnCode {
    [super close];
    [NSApp stopModalWithCode:returnCode];
}

#pragma mark - Closing

- (void)closeWithReturnCode:(NSModalResponse)returnCode {
    RLMWindowDisplayMode displayMode = self.displayMode;

    // Workaround to propagate all NSTextFields values to bindings
    [self.window makeFirstResponder:nil];

    self.displayMode = RLMWindowDisplayModeNone;

    switch (displayMode) {
        case RLMWindowDisplayModeNormal:
            [self closeWindowWithReturnCode:returnCode];
            break;

        case RLMWindowDisplayModeSheet:
            [self closeSheetWithReturnCode:returnCode];
            break;

        case RLMWindowDisplayModeModal:
            [self closeModalWindowWithReturnCode:returnCode];
            break;

        default:
            break;
    }
}

- (void)closeWindow:(id)sender {
    [self closeWindowWithReturnCode:[sender tag]];
}

- (void)close {
    [self closeWindowWithReturnCode:NSModalResponseCancel];
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender {
    [self closeWithReturnCode:NSModalResponseCancel];
    return YES;
}

@end
