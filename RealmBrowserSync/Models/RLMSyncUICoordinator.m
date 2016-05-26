//
//  RLMSyncUICoordinator.m
//  RealmBrowser
//
//  Created by Tim Oliver on 26/05/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;
@import Realm.Private;

#import "RLMBrowserConstants.h"
#import "RLMSyncUICoordinator.h"

#import "RLMSyncCredentialsView.h"
#import "RLMSyncWindowController.h"
#import "RLMRunSyncServerWindowController.h"
#import "RLMSyncAuthWindowController.h"

#import "NSURLComponents+FragmentItems.h"

@interface RLMSyncUICoordinator ()

@property (nonatomic, strong) RLMSyncWindowController *syncWindowController;
@property (nonatomic, strong) RLMRunSyncServerWindowController *runSyncWindowController;
@property (nonatomic, strong) RLMSyncAuthWindowController *syncAuthWindowController;

@end

@implementation RLMSyncUICoordinator

#pragma mark - Sync -
- (void)configureMainMenuWithSyncItems
{
    NSMenu *mainMenu = [NSApp mainMenu];
    
    // Get the 'File' and 'Tools' menu items
    NSMenuItem *fileMenu, *toolsMenu = nil;
    for (NSMenuItem *subMenu in mainMenu.itemArray) {
        if ([subMenu.title isEqualToString:@"File"]) {
            fileMenu = subMenu;
        }
        else if ([subMenu.title isEqualToString:@"Tools"]) {
            toolsMenu = subMenu;
        }
    }
    
    // ---
    
    //Create and insert the menu items for the 'File' item
    NSMenuItem *openSyncURLItem  = [[NSMenuItem alloc] initWithTitle:@"Open Sync URL..." action:@selector(connectToSyncRealmWithURL:) keyEquivalent:@"o"];
    openSyncURLItem.keyEquivalentModifierMask = (NSShiftKeyMask | NSControlKeyMask | NSCommandKeyMask);
    
    NSMenuItem *openSyncFileItem = [[NSMenuItem alloc] initWithTitle:@"Open File with Sync..." action:@selector(openSyncRealmFileWithMenuItem:) keyEquivalent:@"o"];
    openSyncFileItem.keyEquivalentModifierMask = (NSShiftKeyMask | NSCommandKeyMask);
    
    NSMenuItem *newSyncFileItem  = [[NSMenuItem alloc] initWithTitle:@"New Sync File with URL..." action:@selector(createNewRealmFileAndOpenWithSyncURL:) keyEquivalent:@"n"];
    newSyncFileItem.keyEquivalentModifierMask = (NSCommandKeyMask);
    
    NSMenuItem *separator = [NSMenuItem separatorItem];
    
    NSArray *items = @[separator,newSyncFileItem,openSyncFileItem,openSyncURLItem];
    for (NSMenuItem *item in items) {
        [fileMenu.submenu insertItem:item atIndex:4];
    }
    
    // ---
    
    // Create and insert the menu items for the 'Tools' item
    NSMenuItem *runSyncServerItem  = [[NSMenuItem alloc] initWithTitle:@"Run Sync Server..." action:@selector(runSyncServer:) keyEquivalent:@""];
    NSMenuItem *createCredsItem = [[NSMenuItem alloc] initWithTitle:@"Generate Sync Auth Crendentials..." action:@selector(generateAuthCredentials:) keyEquivalent:@""];
    separator = [NSMenuItem separatorItem];
    items = @[createCredsItem, runSyncServerItem, separator];
    
    for (NSMenuItem *item in items) {
        [toolsMenu.submenu insertItem:item atIndex:1];
    }
}

- (IBAction)openSyncRealmFileWithMenuItem:(NSMenuItem *)menuItem
{
    NSNib *accessoryViewNib = [[NSNib alloc] initWithNibNamed:@"SyncCredentialsView" bundle:nil];
    NSArray *views = nil;
    [accessoryViewNib instantiateWithOwner:self topLevelObjects:&views];
    
    RLMSyncCredentialsView *accessoryView = nil;
    for (NSObject *view in views) {
        if ([view isKindOfClass:[RLMSyncCredentialsView class]]) {
            accessoryView = (RLMSyncCredentialsView *)view;
            break;
        }
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[kRealmFileExtension];
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.accessoryView = accessoryView;
    
    // Force the options to be displayed (only available in El Cap)
    // Not sure if older versions default to displaying?
    if ([openPanel respondsToSelector:@selector(isAccessoryViewDisclosed)]) {
        openPanel.accessoryViewDisclosed = YES;
    }
    
    if ([openPanel runModal] == NSFileHandlingPanelCancelButton) {
        return;
    }
    
    NSURL *realmFileURL = [openPanel.URLs firstObject];
    if (realmFileURL == nil) {
        return;
    }
    
    NSString *syncServerURL = accessoryView.syncServerURLField.stringValue;
    NSString *syncServerSignedUserToken = accessoryView.syncSignedUserTokenField.stringValue;
    
    if (!syncServerURL ||
        !syncServerSignedUserToken ||
        [syncServerURL isEqualToString:@""] ||
        [syncServerSignedUserToken isEqualToString:@""] ||
        ![syncServerURL hasPrefix:@"realm://"]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Failed To Enter Valid Sync Credentials"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"To open a Realm file with sync, you must enter a valid sync server URL and sync user token. If you don't see these fields in the 'Open' dialog box, click 'Options' in the lower left corner. Please try again."];
        
        [alert runModal];
        return;
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Make a copy of this Realm file?"
                                     defaultButton:@"No"
                                   alternateButton:@"Yes"
                                       otherButton:nil
                         informativeTextWithFormat:@"Making a copy of this file is necessary if it is going to be accessed from another process at the same time (eg, via iOS Simulator)."];
    
    NSModalResponse response = [alert runModal];
    
    //Deferred to the next run loop iteration to give the modal prompt
    //time to dismiss before the sandboxing prompt appears.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *fragmentItems = [NSMutableArray array];
        
        NSURLComponents *components = [NSURLComponents componentsWithURL:realmFileURL resolvingAgainstBaseURL:NO];
        if (response != 0) {
            [fragmentItems addObject:[NSURLQueryItem queryItemWithName:@"disableSyncFileCopy" value:@"1"]];
        }
        
        NSURLQueryItem *syncURLItem = [NSURLQueryItem queryItemWithName:@"syncServerURL" value:syncServerURL];
        [fragmentItems addObject:syncURLItem];
        
        NSURLQueryItem *syncSignedUserTokenItem = [NSURLQueryItem queryItemWithName:@"syncSignedUserToken" value:syncServerSignedUserToken];
        [fragmentItems addObject:syncSignedUserTokenItem];
        
        components.fragmentItems = fragmentItems;
        
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:components.URL
                                                                               display:YES
                                                                     completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error)
         {
             
         }];
    });
}

- (IBAction)connectToSyncRealmWithURL:(NSMenuItem *)item
{
    if (self.syncWindowController) {
        return;
    }
    
    self.syncWindowController = [[RLMSyncWindowController alloc] initWithTempRealmFile];
    [self.syncWindowController showWindow:self];
    
    __weak typeof(self) weakSelf = self;
    self.syncWindowController.OKButtonClickedHandler = ^{
        NSURL *url = [NSURL fileURLWithPath:weakSelf.syncWindowController.realmFilePath];
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSURLQueryItem *syncURLItem = [NSURLQueryItem queryItemWithName:@"syncServerURL" value:weakSelf.syncWindowController.serverURL];
        NSURLQueryItem *syncSignedUserTokenItem = [NSURLQueryItem queryItemWithName:@"syncSignedUserToken" value:weakSelf.syncWindowController.serverSignedUserToken];
        components.fragmentItems = @[syncURLItem, syncSignedUserTokenItem];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:components.URL
                                                                                   display:YES
                                                                         completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error){ }];
        });
    };
    
    self.syncWindowController.windowClosedHandler = ^{
        weakSelf.syncWindowController = nil;
    };
}

- (IBAction)createNewRealmFileAndOpenWithSyncURL:(NSMenuItem *)item
{
    NSNib *accessoryViewNib = [[NSNib alloc] initWithNibNamed:@"SyncCredentialsView" bundle:nil];
    NSArray *views = nil;
    [accessoryViewNib instantiateWithOwner:self topLevelObjects:&views];
    
    RLMSyncCredentialsView *accessoryView = nil;
    for (NSObject *view in views) {
        if ([view isKindOfClass:[RLMSyncCredentialsView class]]) {
            accessoryView = (RLMSyncCredentialsView *)view;
            break;
        }
    }
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = @[kRealmFileExtension];
    savePanel.accessoryView = accessoryView;
    if ([savePanel runModal] != NSFileHandlingPanelOKButton) {
        return;
    }
    
    NSString *filePath = savePanel.URL.path;
    NSString *syncServerURL = accessoryView.syncServerURLField.stringValue;
    NSString *syncServerSignedUserToken = accessoryView.syncSignedUserTokenField.stringValue;
    
    //Create a new Realm instance to create the file on disk
    //(This NEEDS to be done since RLMDocument requires a file on disk to open)
    @autoreleasepool {
        RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
        configuration.fileURL = [NSURL fileURLWithPath:filePath];
        configuration.dynamic = YES;
        configuration.customSchema = nil;
        
        if (syncServerURL.length > 0) {
            configuration.syncServerURL = [NSURL URLWithString:syncServerURL];
        }
        
        if (syncServerSignedUserToken.length > 0) {
            configuration.syncUserToken = syncServerSignedUserToken;
        }
        
        [RLMRealmConfiguration setDefaultConfiguration:configuration];
        [RLMRealm realmWithConfiguration:configuration error:nil];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL fileURLWithPath:filePath] resolvingAgainstBaseURL:NO];
        NSURLQueryItem *syncURLItem = [NSURLQueryItem queryItemWithName:@"syncServerURL" value:syncServerURL];
        NSURLQueryItem *syncSignedUserTokenItem = [NSURLQueryItem queryItemWithName:@"syncSignedUserToken" value:syncServerSignedUserToken];
        components.fragmentItems = @[syncURLItem, syncSignedUserTokenItem];
        
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:components.URL
                                                                               display:YES
                                                                     completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error)
         {
             
         }];
    });
}

- (IBAction)generateAuthCredentials:(id)sender
{
    if (self.syncAuthWindowController) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.syncAuthWindowController = [[RLMSyncAuthWindowController alloc] init];
    self.syncAuthWindowController.closedHandler = ^{ weakSelf.syncAuthWindowController = nil; };
    [self.syncAuthWindowController showWindow:nil];
}

- (IBAction)runSyncServer:(id)sender
{
    if (self.runSyncWindowController) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.runSyncWindowController = [[RLMRunSyncServerWindowController alloc] init];
    self.runSyncWindowController.closedHandler = ^{ weakSelf.runSyncWindowController = nil; };
    [self.runSyncWindowController showWindow:nil];
}

@end
