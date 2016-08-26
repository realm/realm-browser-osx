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

#import "RLMRealmBrowserWindowController.h"
#import "RLMNavigationStack.h"
#import "RLMModelExporter.h"
#import "RLMExportIndicatorWindowController.h"
#import "RLMEncryptionKeyWindowController.h"
#import "RLMOpenSyncURLWindowController.h"

@import Realm;
@import Realm.Private;
@import Realm.Dynamic;
@import RealmConverter;

#import <AppSandboxFileAccess/AppSandboxFileAccess.h>

NSString * const kRealmLockedImage = @"RealmLocked";
NSString * const kRealmUnlockedImage = @"RealmUnlocked";
NSString * const kRealmLockedTooltip = @"Unlock to enable editing";
NSString * const kRealmUnlockedTooltip = @"Lock to prevent editing";
NSString * const kRealmKeyIsLockedForRealm = @"LockedRealm:%@";

NSString * const kRealmKeyWindowFrameForRealm = @"WindowFrameForRealm:%@";
NSString * const kRealmKeyOutlineWidthForRealm = @"OutlineWidthForRealm:%@";

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
@property (nonatomic, strong) NSData *encryptionKey;

- (void)handleEncryptionKeyPrompt;
- (void)handleSyncPrompt;

@end

@implementation RLMRealmBrowserWindowController {
    RLMNavigationStack *navigationStack;
}

@dynamic document;

#pragma mark - NSViewController Overrides

- (void)windowDidLoad
{
    navigationStack = [[RLMNavigationStack alloc] init];
    self.window.alphaValue = 0.0;

    if (self.document.presentedRealm) {
        // if already loaded
        [self realmDidLoad];
    }
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow:sender];
    
    if (self.document.potentiallyEncrypted) {
        [self handleEncryptionKeyPrompt];
    }
    else if (self.document.potentiallySync) {
        [self handleSyncPrompt];
    }
}

#pragma mark - RLMViewController Overrides

-(void)realmDidLoad
{
    [self.outlineViewController realmDidLoad];
    [self.tableViewController realmDidLoad];
    
    [self updateNavigationButtons];

    NSString *realmPath = self.document.presentedRealm.realm.configuration.fileURL.path;
    [self setWindowFrameAutosaveName:[NSString stringWithFormat:kRealmKeyWindowFrameForRealm, realmPath]];
    [self.splitView setAutosaveName:[NSString stringWithFormat:kRealmKeyOutlineWidthForRealm, realmPath]];
    
    [self reloadAfterEdit];
    self.window.alphaValue = 1.0;

    id firstItem = self.document.presentedRealm.topLevelClasses.firstObject;
    if (firstItem != nil && navigationStack.currentState == nil) {
        RLMNavigationState *initState = [[RLMNavigationState alloc] initWithSelectedType:firstItem index:NSNotFound];
        [self addNavigationState:initState fromViewController:nil];
    }
}

- (void)handleEncryptionKeyPrompt
{
    self.encryptionController = [[RLMEncryptionKeyWindowController alloc] initWithRealmFilePath:self.document.fileURL];
    [self.window beginSheet:self.encryptionController.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode != NSModalResponseOK) {
            [self.document close];
            return;
        }
        
        self.encryptionKey = self.encryptionController.encryptionKey;
        self.document.presentedRealm.encryptionKey = self.encryptionKey;
        [self realmDidLoad];
    }];
}

- (void)handleSyncPrompt
{
    // FIXME: see https://github.com/realm/realm-browser-osx-private/issues/51
    NSAssert(NO, @"Not implemented");
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

- (IBAction)saveCopy:(id)sender
{
    NSString *fileName = [self.document.presentedRealm.realm.configuration.fileURL.path lastPathComponent];
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.canCreateDirectories = YES;
    panel.nameFieldStringValue = fileName;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *fileURL = [panel URL];
            
            AppSandboxFileAccess *fileAccess = [AppSandboxFileAccess fileAccess];
            [fileAccess requestAccessPermissionsForFileURL:panel.URL persistPermission:YES withBlock:^(NSURL *securelyScopedURL, NSData *bookmarkData) {
                [securelyScopedURL startAccessingSecurityScopedResource];
                [self exportAndCompactCopyOfRealmFileAtURL:fileURL];
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
            NSString *realmFolderPath = self.document.presentedRealm.realm.configuration.fileURL.path;
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
    if ([realmFileURL.path.lowercaseString isEqualToString:self.document.presentedRealm.realm.configuration.fileURL.path.lowercaseString]) {
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
    
    //Display an 'exporting' progress indicator
    self.exportWindowController = [[RLMExportIndicatorWindowController alloc] init];
    [self.window beginSheet:self.exportWindowController.window completionHandler:nil];
    
    //Perform the export/compact operations on a background thread as they can potentially be time-consuming
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError *error = nil;
        [self.document.presentedRealm.realm writeCopyToURL:realmFileURL encryptionKey:nil error:&error];
        if (error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.window endSheet:self.exportWindowController.window];
                [NSApp presentError:error];
            });
            return;
        }
        
        @autoreleasepool {
            RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
            configuration.fileURL = realmFileURL;
            configuration.dynamic = YES;
            configuration.customSchema = nil;
            
            RLMRealm *newRealm = [RLMRealm realmWithConfiguration:configuration error:&error];
            if (error) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.window endSheet:self.exportWindowController.window];
                    [NSApp presentError:error];
                });
                return;
            }
            [newRealm compact];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.window endSheet:self.exportWindowController.window];
        });
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
    
    NSString *realmPath = self.document.presentedRealm.realm.configuration.fileURL.path;
    NSString *key = [NSString stringWithFormat:kRealmKeyIsLockedForRealm, realmPath];
    
    BOOL realmIsLocked = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    self.tableViewController.realmIsLocked = realmIsLocked;
    self.lockRealmButton.image = [NSImage imageNamed:realmIsLocked ? kRealmLockedImage : kRealmUnlockedImage];
    self.lockRealmButton.toolTip = realmIsLocked ? kRealmLockedTooltip : kRealmUnlockedTooltip;
    
    [self.tableViewController.tableView reloadData];
}

#pragma mark - Public methods - Rearranging arrays

- (void)removeRowsInTableViewForArrayNode:(RLMArrayNode *)arrayNode at:(NSIndexSet *)rowIndexes
{
    for (RLMRealmBrowserWindowController *wc in [self.document windowControllers]) {
        if ([arrayNode isEqualTo:wc.tableViewController.displayedType]) {
            [wc.tableViewController removeRowsInTableViewAt:rowIndexes];
        }
        [wc.outlineViewController.tableView reloadData];
    }
}

- (void)deleteRowsInTableViewForArrayNode:(RLMArrayNode *)arrayNode at:(NSIndexSet *)rowIndexes
{
    for (RLMRealmBrowserWindowController *wc in [self.document windowControllers]) {
        if ([arrayNode isEqualTo:wc.tableViewController.displayedType]) {
            [wc.tableViewController deleteRowsInTableViewAt:rowIndexes];
        }
        else {
            [wc reloadAfterEdit];
        }
        [wc.outlineViewController.tableView reloadData];
    }
}

- (void)insertNewRowsInTableViewForArrayNode:(RLMArrayNode *)arrayNode at:(NSIndexSet *)rowIndexes
{
    for (RLMRealmBrowserWindowController *wc in [self.document windowControllers]) {
        if ([arrayNode isEqualTo:wc.tableViewController.displayedType]) {
            [wc.tableViewController insertNewRowsInTableViewAt:rowIndexes];
        }
        else {
            [wc reloadAfterEdit];
        }
        [wc.outlineViewController.tableView reloadData];
    }
}

- (void)moveRowsInTableViewForArrayNode:(RLMArrayNode *)arrayNode from:(NSIndexSet *)sourceIndexes to:(NSUInteger)destination
{
    for (RLMRealmBrowserWindowController *wc in [self.document windowControllers]) {
        if ([arrayNode isEqualTo:wc.tableViewController.displayedType]) {
            [wc.tableViewController moveRowsInTableViewFrom:sourceIndexes to:destination];
        }
    }
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
    NSString *realmPath = self.document.presentedRealm.realm.configuration.fileURL.path;
    NSString *key = [NSString stringWithFormat:kRealmKeyIsLockedForRealm, realmPath];

    BOOL currentlyLocked = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    [self setRealmLocked:!currentlyLocked];
}

-(void)setRealmLocked:(BOOL)locked
{
    NSString *realmPath = self.document.presentedRealm.realm.configuration.fileURL.path;
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
