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

@import Realm;
@import Realm.Private;
@import Realm.Dynamic;
@import RealmConverter;
@import AppSandboxFileAccess;

#import "RLMRealmBrowserWindowController.h"
#import "RLMNavigationStack.h"
#import "RLMModelExporter.h"
#import "RLMExportIndicatorWindowController.h"
#import "RLMEncryptionKeyWindowController.h"
#import "RLMCredentialsWindowController.h"
#import "RLMConnectionIndicatorWindowController.h"
#import "RLMBrowserConstants.h"

NSString * const kRealmLockedImage = @"RealmLocked";
NSString * const kRealmUnlockedImage = @"RealmUnlocked";
NSString * const kRealmLockedTooltip = @"Unlock to enable editing";
NSString * const kRealmUnlockedTooltip = @"Lock to prevent editing";
NSString * const kRealmKeyIsLockedForRealm = @"LockedRealm:%@";

NSString * const kRealmKeyWindowFrameForRealm = @"WindowFrameForRealm:%@";
NSString * const kRealmKeyOutlineWidthForRealm = @"OutlineWidthForRealm:%@";

static void const *kWaitForDocumentSchemaLoadObservationContext;

@interface RLMRealm ()
- (BOOL)compact;
@end

@interface RLMRealmBrowserWindowController()<NSWindowDelegate>

@property (atomic, weak) IBOutlet NSSplitView *splitView;
@property (nonatomic, strong) IBOutlet NSSegmentedControl *navigationButtons;
@property (atomic, weak) IBOutlet NSToolbarItem *lockRealmButton;
@property (nonatomic, strong) IBOutlet NSSearchField *searchField;

@property (nonatomic, strong) RLMExportIndicatorWindowController *exportWindowController;
@property (nonatomic, strong) RLMEncryptionKeyWindowController *encryptionController;
@property (nonatomic, strong) RLMCredentialsWindowController *credentialsController;
@property (nonatomic, strong) RLMConnectionIndicatorWindowController *connectionIndicatorWindowController;

@property (nonatomic, strong) RLMNotificationToken *documentNotificationToken;

@end

@implementation RLMRealmBrowserWindowController {
    RLMNavigationStack *navigationStack;
}

@dynamic document;

- (void)setDocument:(RLMDocument *)document {
    if (document == self.document) {
        return;
    }

    [self stopObservingDocument];

    [super setDocument:document];

    if (self.windowLoaded && self.window.isVisible) {
        [self handleDocumentState];
    }
}

#pragma mark - NSWindowController Overrides

- (void)windowDidLoad
{
    navigationStack = [[RLMNavigationStack alloc] init];

    NSString *realmPath = self.document.fileURL.path;
    [self setWindowFrameAutosaveName:[NSString stringWithFormat:kRealmKeyWindowFrameForRealm, realmPath]];
    [self.splitView setAutosaveName:[NSString stringWithFormat:kRealmKeyOutlineWidthForRealm, realmPath]];
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow:sender];
    [self handleDocumentState];
}

#pragma mark - Document observation

- (void)handleDocumentState {
    switch (self.document.state) {
        case RLMDocumentStateRequiresFormatUpgrade:
            [self handleFormatUpgrade];
            break;

        case RLMDocumentStateNeedsEncryptionKey:
            [self handleEncryption];
            break;

        case RLMDocumentStateLoadingSchema:
            [self waitForDocumentSchemaLoad];
            break;

        case RLMDocumentStateNeedsValidCredential:
            [self handleSyncCredentials];
            break;

        case RLMDocumentStateLoaded:
            [self realmDidLoad];
            break;

        case RLMDocumentStateUnrecoverableError:
            [self handleUnrecoverableError];
            break;
    }
}

- (void)startObservingDocument {
    __weak typeof(self) weakSelf = self;

    self.documentNotificationToken = [self.document.presentedRealm.realm addNotificationBlock:^(RLMNotification notification, RLMRealm *realm) {
        // Send notifications to all document's window controllers
        [weakSelf.document.windowControllers makeObjectsPerformSelector:@selector(handleDocumentChange)];
    }];
}

- (void)handleDocumentChange {
    [self reloadAfterEdit];
}

- (void)stopObservingDocument {
    [self.documentNotificationToken stop];
}

- (void)realmDidLoad {
    [self.outlineViewController realmDidLoad];
    [self.tableViewController realmDidLoad];
    
    [self updateNavigationButtons];

    id firstItem = self.document.presentedRealm.topLevelClasses.firstObject;
    if (firstItem != nil && navigationStack.currentState == nil) {
        RLMNavigationState *initState = [[RLMNavigationState alloc] initWithSelectedType:firstItem index:NSNotFound];
        [self addNavigationState:initState fromViewController:nil];
    }

    [self startObservingDocument];
}

- (void)handleFormatUpgrade {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat:@"\"%@\" is at an older file format version and must be upgraded before it can be opened. Would you like to proceed?", self.document.fileURL.lastPathComponent];
    alert.informativeText = @"If the file is upgraded, it will no longer be compatible with older versions of Realm. File format upgrades are permanent and cannot be undone.";

    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Proceed with Upgrade"];

    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            [self.document loadByPerformingFormatUpgradeWithError:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleDocumentState];
            });
        } else {
            [self.document close];
        }
    }];
}

- (void)handleEncryption {
    self.encryptionController = [[RLMEncryptionKeyWindowController alloc] init];

    [self.encryptionController showSheetForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            [self.document loadWithEncryptionKey:self.encryptionController.encryptionKey error:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleDocumentState];
            });
        } else {
            [self.document close];
        }

        self.encryptionController = nil;
    }];
}

- (void)waitForDocumentSchemaLoad {
    [self showLoadingIndicator];
    [self.document addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:&kWaitForDocumentSchemaLoadObservationContext];
}

- (void)documentSchemaLoaded {
    [self.document removeObserver:self forKeyPath:@"state"];
    [self hideLoadingIndicator];
    [self handleDocumentState];
}

- (void)handleSyncCredentials {
    self.credentialsController = [[RLMCredentialsWindowController alloc] init];
    self.credentialsController.credential = self.document.credential;

    [self.credentialsController showSheetForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            [self showLoadingIndicator];

            [self.document loadWithCredential:self.credentialsController.credential completionHandler:^(NSError *error) {
                [self hideLoadingIndicator];

                // TODO: handle error code properly
                if (error != nil) {
                    [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                        [self handleSyncCredentials];
                    }];
                } else {
                    [self handleDocumentState];
                }
            }];
        } else {
            [self.document close];
        }

        self.credentialsController = nil;
    }];
}

- (void)showLoadingIndicator {
    if (self.connectionIndicatorWindowController.isWindowVisible) {
        return;
    }

    self.connectionIndicatorWindowController = [[RLMConnectionIndicatorWindowController alloc] init];

    [self.connectionIndicatorWindowController showSheetForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseCancel) {
            [self.document close];
        }

        self.connectionIndicatorWindowController = nil;
    }];
}

- (void)hideLoadingIndicator {
    [self.connectionIndicatorWindowController closeWithReturnCode:NSModalResponseOK];
}

- (void)handleUnrecoverableError {
    NSAlert *alert;

    if (self.document.error != nil) {
        alert = [NSAlert alertWithError:self.document.error];
    } else {
        alert = [[NSAlert alloc] init];

        alert.messageText = @"Realm couldn't be opened";
        alert.alertStyle = NSCriticalAlertStyle;
    }

    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        [self.document close];
    }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == &kWaitForDocumentSchemaLoadObservationContext) {
        if (self.document.state != RLMDocumentStateLoadingSchema) {
            [self documentSchemaLoaded];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Public methods - Accessors

- (RLMNavigationState *)currentState
{
    return navigationStack.currentState;
}

#pragma mark - Public methods - Menu items

- (void)saveModelsForLanguage:(RLMModelExporterLanguage)language
{
    NSArray *objectSchemas = self.document.presentedRealm.realm.schema.objectSchema;
    [RLMModelExporter saveModelsForSchemas:objectSchemas inLanguage:language];
}

- (IBAction)saveJavaModels:(id)sender
{
    [self saveModelsForLanguage:RLMModelExporterLanguageJava];
}

- (IBAction)saveObjcModels:(id)sender
{
    [self saveModelsForLanguage:RLMModelExporterLanguageObjectiveC];
}

- (IBAction)saveSwiftModels:(id)sender
{
    [self saveModelsForLanguage:RLMModelExporterLanguageSwift];
}

- (IBAction)exportToCompactedRealm:(id)sender
{
    NSString *fileName = self.document.fileURL.lastPathComponent ?: self.document.syncURL.lastPathComponent ?: @"Compacted";

    if (![fileName.pathExtension isEqualToString:kRealmFileExtension]) {
        fileName = [fileName.stringByDeletingPathExtension stringByAppendingPathExtension:kRealmFileExtension];
    }

    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.canCreateDirectories = YES;
    panel.nameFieldStringValue = fileName;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result != NSFileHandlingPanelOKButton || !panel.URL) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppSandboxFileAccess *fileAccess = [AppSandboxFileAccess fileAccess];
            [fileAccess requestAccessPermissionsForFileURL:panel.URL persistPermission:YES withBlock:^(NSURL *securelyScopedURL, NSData *bookmarkData) {
                [securelyScopedURL startAccessingSecurityScopedResource];
                [self exportAndCompactCopyOfRealmFileAtURL:panel.URL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [securelyScopedURL stopAccessingSecurityScopedResource];
                }); 
            }];
        });
    }];
}

- (IBAction)exportToCSV:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canCreateDirectories = YES;
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    panel.message = @"Choose the directory in which to save the CSV files generated from this Realm file.";
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton) {
            return;
        }
    
        AppSandboxFileAccess *fileAccess = [AppSandboxFileAccess fileAccess];
        [fileAccess requestAccessPermissionsForFileURL:panel.URL persistPermission:YES withBlock:^(NSURL *securelyScopedURL, NSData *bookmarkData) {
            [securelyScopedURL startAccessingSecurityScopedResource];
            
            NSString *folderPath = panel.URL.path;
            NSString *realmFolderPath = self.document.fileURL.path;
            RLMCSVDataExporter *exporter = [[RLMCSVDataExporter alloc] initWithRealmFileAtPath:realmFolderPath];
            NSError *error = nil;
            [exporter exportToFolderAtPath:folderPath withError:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [securelyScopedURL stopAccessingSecurityScopedResource];
            });
        }];
    }];
}

- (void)exportAndCompactCopyOfRealmFileAtURL:(NSURL *)realmFileURL
{
    NSError *error = nil;
    
    //Check that this won't end up overwriting the original file
    if ([realmFileURL.path.lowercaseString isEqualToString:self.document.fileURL.path.lowercaseString]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"You cannot overwrite the original Realm file.";
        alert.informativeText = @"Please choose a different location in which to save this Realm file.";
        [alert runModal];
        return;
    }
    
    //Ensure a file with the same name doesn't already exist
    BOOL directory = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:realmFileURL.path isDirectory:&directory] && !directory) {
        [[NSFileManager defaultManager] removeItemAtPath:realmFileURL.path error:&error];
        if (error) {
            [NSApp presentError:error];
            return;
        }
    }

    void (^closeExportWindowOnMainThreadAndShowError)(NSError *) = ^void(NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.window endSheet:self.exportWindowController.window];

            if (error != nil) {
                [NSApp presentError:error];
            }
        });
    };

    //Display an 'exporting' progress indicator
    self.exportWindowController = [[RLMExportIndicatorWindowController alloc] init];
    [self.window beginSheet:self.exportWindowController.window completionHandler:nil];
    
    //Perform the export/compact operations on a background thread as they can potentially be time-consuming
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError *error = nil;

        RLMRealm *currentThreadRealm = [RLMRealm realmWithConfiguration:self.document.presentedRealm.realm.configuration error:&error];
        if (currentThreadRealm == nil) {
            closeExportWindowOnMainThreadAndShowError(error);
            return;
        }

        if (![currentThreadRealm writeCopyToURL:realmFileURL encryptionKey:nil error:&error]) {
            closeExportWindowOnMainThreadAndShowError(error);
            return;
        }

        RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
        configuration.fileURL = realmFileURL;
        configuration.dynamic = YES;
        
        RLMRealm *exportedRealm = [RLMRealm realmWithConfiguration:configuration error:&error];
        if (exportedRealm == nil) {
            closeExportWindowOnMainThreadAndShowError(error);
            return;
        }

        [exportedRealm compact];

        closeExportWindowOnMainThreadAndShowError(nil);
    });
}

#pragma mark - Public methods - User Actions

- (void)reloadAllWindows
{
    NSArray *windowControllers = [self.document windowControllers];
    
    for (RLMRealmBrowserWindowController *wc in windowControllers) {
        [wc reloadAfterEdit];
    }
}

- (void)reloadAfterEdit
{
    [self.outlineViewController.tableView reloadData];
    
    NSString *realmPath = self.document.fileURL.path;
    NSString *key = [NSString stringWithFormat:kRealmKeyIsLockedForRealm, realmPath];
    
    BOOL realmIsLocked = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    self.tableViewController.realmIsLocked = realmIsLocked;
    self.lockRealmButton.image = [NSImage imageNamed:realmIsLocked ? kRealmLockedImage : kRealmUnlockedImage];
    self.lockRealmButton.toolTip = realmIsLocked ? kRealmLockedTooltip : kRealmUnlockedTooltip;
    
    [self.tableViewController.tableView reloadData];
}

#pragma mark - Public methods - Navigation

- (void)addNavigationState:(RLMNavigationState *)state fromViewController:(RLMViewController *)controller
{
    if (!controller.navigationFromHistory) {
        RLMNavigationState *oldState = navigationStack.currentState;
        
        [navigationStack pushState:state];
        [self updateNavigationButtons];
        
        if (controller == self.tableViewController || controller == nil) {
            [self.outlineViewController updateUsingState:state oldState:oldState];
        }
        
        [self.tableViewController updateUsingState:state oldState:oldState];
    }

    // Searching is not implemented for link arrays yet
    BOOL isArray = [state isMemberOfClass:[RLMArrayNavigationState class]];
    [self.searchField setEnabled:!isArray];
}

- (void)newWindowWithNavigationState:(RLMNavigationState *)state
{
    RLMRealmBrowserWindowController *wc = [[RLMRealmBrowserWindowController alloc] initWithWindowNibName:self.windowNibName];

    [self.document addWindowController:wc];
    [self.document showWindows];

    [wc addNavigationState:state fromViewController:wc.tableViewController];
}

- (IBAction)userClicksOnNavigationButtons:(NSSegmentedControl *)buttons
{
    RLMNavigationState *oldState = navigationStack.currentState;
    
    switch (buttons.selectedSegment) {
        case 0: { // Navigate backwards
            RLMNavigationState *state = [navigationStack navigateBackward];
            if (state != nil) {
                [self.outlineViewController updateUsingState:state oldState:oldState];
                [self.tableViewController updateUsingState:state oldState:oldState];
            }
            break;
        }
        case 1: { // Navigate forwards
            RLMNavigationState *state = [navigationStack navigateForward];
            if (state != nil) {
                [self.outlineViewController updateUsingState:state oldState:oldState];
                [self.tableViewController updateUsingState:state oldState:oldState];
            }
            break;
        }
        default:
            break;
    }
    
    [self updateNavigationButtons];
}

- (IBAction)userClickedLockRealm:(id)sender
{
    NSString *realmPath = self.document.fileURL.path;
    NSString *key = [NSString stringWithFormat:kRealmKeyIsLockedForRealm, realmPath];

    BOOL currentlyLocked = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    [self setRealmLocked:!currentlyLocked];
}

-(void)setRealmLocked:(BOOL)locked
{
    NSString *realmPath = self.document.fileURL.path;
    NSString *key = [NSString stringWithFormat:kRealmKeyIsLockedForRealm, realmPath];
    [[NSUserDefaults standardUserDefaults] setBool:locked forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self reloadAllWindows];
}

- (IBAction)searchAction:(NSSearchFieldCell *)searchCell
{
    NSString *searchText = searchCell.stringValue;
    RLMTypeNode *typeNode = navigationStack.currentState.selectedType;

    // Return to parent class (showing all objects) when the user clears the search text
    if (searchText.length == 0) {
        if ([navigationStack.currentState isMemberOfClass:[RLMQueryNavigationState class]]) {
            RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:typeNode index:0];
            [self addNavigationState:state fromViewController:self.tableViewController];
        }
        return;
    }

    NSArray *columns = typeNode.propertyColumns;
    NSUInteger columnCount = columns.count;
    RLMRealm *realm = self.document.presentedRealm.realm;

    NSString *predicate = @"";

    for (NSUInteger index = 0; index < columnCount; index++) {

        RLMClassProperty *property = columns[index];
        NSString *columnName = property.name;

        switch (property.type) {
            case RLMPropertyTypeBool: {
                if ([searchText caseInsensitiveCompare:@"true"] == NSOrderedSame ||
                    [searchText caseInsensitiveCompare:@"YES"] == NSOrderedSame) {
                    if (predicate.length != 0) {
                        predicate = [predicate stringByAppendingString:@" OR "];
                    }
                    predicate = [predicate stringByAppendingFormat:@"%@ = YES", columnName];
                }
                else if ([searchText caseInsensitiveCompare:@"false"] == NSOrderedSame ||
                         [searchText caseInsensitiveCompare:@"NO"] == NSOrderedSame) {
                    if (predicate.length != 0) {
                        predicate = [predicate stringByAppendingString:@" OR "];
                    }
                    predicate = [predicate stringByAppendingFormat:@"%@ = NO", columnName];
                }
                break;
            }
            case RLMPropertyTypeInt: {
                int value;
                if ([searchText isEqualToString:@"0"]) {
                    value = 0;
                }
                else {
                    value = [searchText intValue];
                    if (value == 0)
                        break;
                }

                if (predicate.length != 0) {
                    predicate = [predicate stringByAppendingString:@" OR "];
                }
                predicate = [predicate stringByAppendingFormat:@"%@ = %d", columnName, (int)value];
                break;
            }
            case RLMPropertyTypeString: {
                if (predicate.length != 0) {
                    predicate = [predicate stringByAppendingString:@" OR "];
                }
                predicate = [predicate stringByAppendingFormat:@"%@ CONTAINS[c] '%@'", columnName, searchText];
                break;
            }
            //case RLMPropertyTypeFloat: // search on float columns disabled until bug is fixed in binding
            case RLMPropertyTypeDouble: {
                double value;

                if ([searchText isEqualToString:@"0"] ||
                    [searchText isEqualToString:@"0.0"]) {
                    value = 0.0;
                }
                else {
                    value = [searchText doubleValue];
                    if (value == 0.0)
                        break;
                }

                if (predicate.length != 0) {
                    predicate = [predicate stringByAppendingString:@" OR "];
                }
                predicate = [predicate stringByAppendingFormat:@"%@ = %f", columnName, value];
                break;
            }
            default:
                break;
        }
    }

    RLMResults *result;
    
    if (predicate.length != 0) {
        result = [realm objects:typeNode.name where:predicate];
    }

    RLMQueryNavigationState *state = [[RLMQueryNavigationState alloc] initWithQuery:searchText type:typeNode results:result];
    [self addNavigationState:state fromViewController:self.tableViewController];
}

#pragma mark - Private methods

- (void)updateNavigationButtons
{
    [self.navigationButtons setEnabled:[navigationStack canNavigateBackward] forSegment:0];
    [self.navigationButtons setEnabled:[navigationStack canNavigateForward] forSegment:1];
}

@end
