//
//  RLMOpenSyncURLWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 15/06/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMSyncServerConnectionWindowController.h"
#import "RLMSyncCredentialsViewController.h"

@interface RLMSyncServerConnectionWindowController () <NSWindowDelegate>

@property (weak) IBOutlet NSView *credentialsViewContainer;
@property (weak) IBOutlet NSButton *openButton;

@end

@implementation RLMSyncServerConnectionWindowController

- (instancetype)init {
    return [super initWithWindowNibName:@"SyncServerConnectionWindow"];
}

- (void)dealloc {
    [self.credentialsViewController removeObserver:self forKeyPath:@"syncServerURL"];
    [self.credentialsViewController removeObserver:self forKeyPath:@"signedUserToken"];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.credentialsViewController = [[RLMSyncCredentialsViewController alloc] init];
    
    self.credentialsViewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.credentialsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.credentialsViewContainer addSubview:self.credentialsViewController.view];
    
    NSDictionary *views = @{@"credentialsView": self.credentialsViewController.view};
    
    [self.credentialsViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[credentialsView]|"
                                                                                          options:0
                                                                                          metrics:nil
                                                                                            views:views]];
    
    [self.credentialsViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[credentialsView]|"
                                                                                          options:0
                                                                                          metrics:nil
                                                                                            views:views]];
    
    [self.credentialsViewController addObserver:self forKeyPath:@"syncServerURL" options:NSKeyValueObservingOptionInitial context:nil];
    [self.credentialsViewController addObserver:self forKeyPath:@"signedUserToken" options:NSKeyValueObservingOptionInitial context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    self.openButton.enabled = [self.credentialsViewController validateCredentials:nil];
}

- (IBAction)open:(id)sender {
    [self close];
    [NSApp stopModalWithCode:NSModalResponseOK];
}

- (NSModalResponse)runModal {
    return [NSApp runModalForWindow:self.window];
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender {
    [NSApp stopModalWithCode:NSModalResponseCancel];
    return YES;
}

@end
