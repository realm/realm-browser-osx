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

#import "RLMApplicationDelegate.h"
#import "RLMTestDataGenerator.h"
#import "TestClasses.h"
#import "RLMDocument.h"
#import "RLMSyncCredentialsView.h"
#import "RLMSyncWindowController.h"
#import "NSURLComponents+FragmentItems.h"
#import "RLMSyncAuthWindowController.h"

const NSUInteger kTopTipDelay = 250;
const NSUInteger kMaxFilesPerCategory = 7;
const CGFloat kMenuImageSize = 16;

NSString *const kRealmFileExtension = @"realm";
NSString *const kDeveloperFolder = @"/Developer";
NSString *const kSimulatorFolder = @"/Library/Application Support/iPhone Simulator";
NSString *const kDesktopFolder = @"/Desktop";
NSString *const kDownloadFolder = @"/Download";
NSString *const kDocumentsFolder = @"/Documents";

NSInteger const kMaxNumberOfFilesAtOnce = 20;

@interface RLMApplicationDelegate ()

@property (nonatomic, weak) IBOutlet NSMenu *fileMenu;
@property (nonatomic, weak) IBOutlet NSMenuItem *openMenuItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *openSyncMenuItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *openEncryptedMenuItem;
@property (nonatomic, weak) IBOutlet NSMenu *openAnyRealmMenu;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, assign) BOOL didLoadFile;

@property (nonatomic, strong) NSMetadataQuery *realmQuery;
@property (nonatomic, strong) NSMetadataQuery *appQuery;
@property (nonatomic, strong) NSMetadataQuery *projQuery;
@property (nonatomic, strong) NSArray *groupedFileItems;

@property (nonatomic, strong) RLMSyncWindowController *syncWindowController;
@property (nonatomic, strong) RLMSyncAuthWindowController *syncAuthWindowController;

@end

@implementation RLMApplicationDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] setObject:@(kTopTipDelay) forKey:@"NSInitialToolTipDelay"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (!self.didLoadFile && ![[NSProcessInfo processInfo] environment][@"TESTING"]) {
        [NSApp sendAction:self.openMenuItem.action to:self.openMenuItem.target from:self];

        self.realmQuery = [[NSMetadataQuery alloc] init];
        [self.realmQuery setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemContentModificationDate ascending:NO]]];
        NSPredicate *realmPredicate = [NSPredicate predicateWithFormat:@"kMDItemFSName like[c] '*.realm'"];
        self.realmQuery.predicate = realmPredicate;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(realmQueryNote:) name:nil object:self.realmQuery];
        [self.realmQuery startQuery];
        
        self.appQuery = [[NSMetadataQuery alloc] init];
        NSPredicate *appPredicate = [NSPredicate predicateWithFormat:@"kMDItemFSName like[c] '*.app'"];
        self.appQuery.predicate = appPredicate;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otherQueryNote:) name:nil object:self.appQuery];

        self.projQuery = [[NSMetadataQuery alloc] init];
        NSPredicate *projPredicate = [NSPredicate predicateWithFormat:@"kMDItemFSName like[c] '*.xcodeproj'"];
        self.projQuery.predicate = projPredicate;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otherQueryNote:) name:nil object:self.projQuery];

        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename
{
    [self openFileAtURL:[NSURL fileURLWithPath:filename]];
    self.didLoadFile = YES;

    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    if (filenames.count > kMaxNumberOfFilesAtOnce) {
        NSString *message = [NSString stringWithFormat:@"Are you sure you wish to open all %lu Realm files?", (unsigned long)filenames.count];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:message];
        [alert setInformativeText:@"Opening too many files at once may result in Realm Browser becoming unstable."];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        if ([alert runModal] != NSAlertFirstButtonReturn)
            return;
    }
    
    self.didLoadFile = YES;
    for (NSString *filename in filenames)
        [self openFileAtURL:[NSURL fileURLWithPath:filename]];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)application
{
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)flag
{
    return NO;
}

#pragma mark - Event handling

- (void)realmQueryNote:(NSNotification *)notification {
    if ([[notification name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        [self updateFileItems];
        [self.appQuery startQuery];
        [self.projQuery startQuery];
    }
    else if ([[notification name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        [self updateFileItems];
        [self.appQuery startQuery];
    }
}

- (void)otherQueryNote:(NSNotification *)notification {
    if ([[notification name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        [self updateFileItems];
    }
    else if ([[notification name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        [self updateFileItems];
    }
}

-(void)menuNeedsUpdate:(NSMenu *)menu
{
    if (menu == self.openAnyRealmMenu) {
        [menu removeAllItems];
        NSArray *allItems = [self.groupedFileItems valueForKeyPath:@"Items.@unionOfArrays.self"];
        [self updateMenu:menu withItems:allItems indented:YES];
    }
}

-(void)updateMenu:(NSMenu *)menu withItems:(NSArray *)items indented:(BOOL)indented
{
    NSImage *image = [NSImage imageNamed:@"AppIcon"];
    image.size = NSMakeSize(kMenuImageSize, kMenuImageSize);
    
    for (id item in items) {
        // Category heading, create disabled menu item with corresponding name
        if ([item isKindOfClass:[NSString class]]) {
            NSMenuItem *categoryItem = [[NSMenuItem alloc] init];
            categoryItem.title = (NSString *)item;
            categoryItem.enabled = NO;
            [menu addItem:categoryItem];
        }
        // Array of items, create cubmenu and set them up there by calling this method recursively
        else if ([item isKindOfClass:[NSArray class]]) {
            NSMenuItem *submenuItem = [[NSMenuItem alloc] init];
            submenuItem.title = @"More";
            submenuItem.indentationLevel = 1;
            [menu addItem:submenuItem];
            
            NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"More"];
            NSArray *subitems = item;
            [self updateMenu:submenu withItems:subitems indented:NO];
            [menu setSubmenu:submenu forItem:submenuItem];
        }
        // Normal file item, just create a menu item for it and wire it up
        else if ([item isMemberOfClass:[NSMetadataItem class]]) {
            NSMetadataItem *metadataItem = (NSMetadataItem *)item;
            
            // Get the path to the realm and see if there is additional info for it, such as app name
            NSString *path = [metadataItem valueForAttribute:NSMetadataItemPathKey];
            NSString *title = [[path lastPathComponent] stringByAppendingString:[self extraInfoForRealmWithPath:path]];

            // Create a menu item using the title and link it with opening the file
            NSMenuItem *menuItem = [[NSMenuItem alloc] init];
            menuItem.title = title;
            menuItem.representedObject = [NSURL fileURLWithPath:path];
            
            menuItem.target = self;
            menuItem.action = @selector(openFileWithMenuItem:);
            menuItem.image = image;
            menuItem.indentationLevel = indented ? 1 : 0;
            
            // Give the menu item a tooltip with modification date and full path
            NSDate *date = [metadataItem valueForAttribute:NSMetadataItemFSContentChangeDateKey];
            NSString *dateString = [self.dateFormatter stringFromDate:date];
            menuItem.toolTip = [NSString stringWithFormat:@"%@\n\nModified: %@", path, dateString];
            
            [menu addItem:menuItem];
        }
    }
}

-(NSString *)extraInfoForRealmWithPath:(NSString *)realmPath
{
    NSArray *searchPaths;
    NSString *searchEndPath;
    
    NSString *developerPrefix = [NSHomeDirectory() stringByAppendingPathComponent:kDeveloperFolder];
    NSString *simulatorPrefix = [NSHomeDirectory() stringByAppendingPathComponent:kSimulatorFolder];
    
    if ([realmPath hasPrefix:developerPrefix]) {
        // The realm file is in the simulator, so we are looking for *.xcodeproj files
        searchPaths = [self.projQuery results];
        searchEndPath = developerPrefix;
    }
    else if ([realmPath hasPrefix:simulatorPrefix]) {
        // The realm file is in the simulator, so we are looking for *.app files
        searchPaths = [self.appQuery results];
        searchEndPath = simulatorPrefix;
    }
    else {
        // We have no extra info for this containing folder
        return @"";
    }
    
    // Search at most four levels up for a corresponding app/project file
    for (NSUInteger i = 0; i < 4; i++) {
        // Go up one level in the file hierachy by deleting last path component
        realmPath = [[realmPath stringByDeletingLastPathComponent] copy];
        if ([realmPath isEqualToString:searchEndPath]) {
            // Reached end of iteration, the respective folder we are searching within
            return @"";
        }
        
        for (NSString *pathItem in searchPaths) {
            NSMetadataItem *metadataItem = (NSMetadataItem *)pathItem;
            NSString *foundPath = [metadataItem valueForAttribute:NSMetadataItemPathKey];
            
            if ([[foundPath stringByDeletingLastPathComponent] isEqualToString:realmPath]) {
                // Found a project/app file, returning it in formatted form
                NSString *extraInfo = [[[foundPath pathComponents] lastObject] stringByDeletingPathExtension];
                return [NSString stringWithFormat: @" - %@", extraInfo];
            }
        }
    }
    
    // Tried four levels up and still found nothing, nor reached containing folder. Giving up
    return @"";
}

-(void)updateFileItems
{
    NSString *homeDir = NSHomeDirectory();
    
    NSString *kPrefix = @"Prefix";
    NSString *kItems = @"Items";
    
    NSString *simPrefix = [homeDir stringByAppendingPathComponent:kSimulatorFolder];
    NSDictionary *simDict = @{kPrefix : simPrefix, kItems : [NSMutableArray arrayWithObject:@"iPhone Simulator"]};
    
    NSString *devPrefix = [homeDir stringByAppendingPathComponent:kDeveloperFolder];
    NSDictionary *devDict = @{kPrefix : devPrefix, kItems : [NSMutableArray arrayWithObject:@"Developer"]};
    
    NSString *desktopPrefix = [homeDir stringByAppendingPathComponent:kDesktopFolder];
    NSDictionary *desktopDict = @{kPrefix : desktopPrefix, kItems : [NSMutableArray arrayWithObject:@"Desktop"]};
    
    NSString *downloadPrefix = [homeDir stringByAppendingPathComponent:kDownloadFolder];
    NSDictionary *downloadDict = @{kPrefix : downloadPrefix, kItems : [NSMutableArray arrayWithObject:@"Download"]};
    
    NSString *documentsPrefix = [homeDir stringByAppendingPathComponent:kDocumentsFolder];
    NSDictionary *documentsdDict = @{kPrefix : documentsPrefix, kItems : [NSMutableArray arrayWithObject:@"Documents"]};
    
    NSString *allPrefix = @"/";
    NSDictionary *otherDict = @{kPrefix : allPrefix, kItems : [NSMutableArray arrayWithObject:@"Other"]};
    
    // Create array of dictionaries, each corresponding to search folders
    self.groupedFileItems = @[simDict, devDict, desktopDict, documentsdDict, downloadDict, otherDict];
    
    // Iterate through all search results
    for (NSMetadataItem *fileItem in self.realmQuery.results) {
        // Iterate through the different prefixes and add item to corresponding array within dictionary
        for (NSDictionary *dict in self.groupedFileItems) {
            if ([[fileItem valueForAttribute:NSMetadataItemPathKey] hasPrefix:dict[kPrefix]]) {
                NSMutableArray *items = dict[kItems];
                // The first few items are just added
                if (items.count - 1 < kMaxFilesPerCategory) {
                    [items addObject:fileItem];
                }
                // When we reach the maximum number of files to show in the overview we create an array...
                else if (items.count - 1 == kMaxFilesPerCategory) {
                    NSMutableArray *moreFileItems = [NSMutableArray arrayWithObject:fileItem];
                    [items addObject:moreFileItems];
                }
                // ... and henceforth we put fileItems here instead - the menu method will create a submenu.
                else {
                    NSMutableArray *moreFileItems = [items lastObject];
                    [moreFileItems addObject:fileItem];
                }
                // We have already found a matching prefix, we can stop considering this item
                break;
            }
        }
    }
}

- (IBAction)generatedDemoDatabase:(id)sender
{
    // Find the document directory using it as default location for realm file.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directories = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *url = [directories firstObject];
    
    // Prompt the user for location af new realm file.
    [self showSavePanelStringFromDirectory:url completionHandler:^(BOOL userSelectedFile, NSURL *selectedFile) {
        
        NSURL *directoryURL = [selectedFile URLByDeletingLastPathComponent];
            
        // If the user has selected a file url for storing the demo database, we first check if the
        // file already exists (and is actually a file) we delete the old file before creating the
        // new demo file.
        if (userSelectedFile) {
            NSString *path = selectedFile.path;
            BOOL isDirectory = NO;
            
            if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
                if (!isDirectory) {
                    NSError *error;
                    [fileManager removeItemAtURL:selectedFile error:&error];
                }
            }
            
            NSArray *classNames = @[[RealmTestClass0 className], [RealmTestClass1 className], [RealmTestClass2 className]];
            BOOL success = [RLMTestDataGenerator createRealmAtUrl:selectedFile withClassesNamed:classNames objectCount:1000];
            
            if (success) {
                NSAlert *alert = [[NSAlert alloc] init];
                
                alert.alertStyle = NSInformationalAlertStyle;
                alert.showsHelp = NO;
                alert.informativeText = @"A demo database has been generated. Would you like to open it?";
                alert.messageText = @"Open demo database?";
                [alert addButtonWithTitle:@"Open"];
                [alert addButtonWithTitle:@"Cancel"];
                
                NSUInteger response = [alert runModal];
                if (response == NSAlertFirstButtonReturn) {
                    [self openFileAtURL:selectedFile];
                }
            }
        }
    }];
}

#pragma mark - Private methods

-(void)openFileWithMenuItem:(NSMenuItem *)menuItem
{
    [self openFileAtURL:menuItem.representedObject];
}

-(void)openFileAtURL:(NSURL *)url
{
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url
                                              display:YES
                                    completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
                                    }];
}

- (IBAction)openSyncRealmFileWithMenuItem:(NSMenuItem *)menuItem
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[kRealmFileExtension];
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = NO;

    if ([openPanel runModal] == NSFileHandlingPanelCancelButton) {
        return;
    }
    
    NSURL *realmFileURL = [openPanel.URLs firstObject];
    if (realmFileURL == nil) {
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
        [fragmentItems addObject:[NSURLQueryItem queryItemWithName:@"syncCredentialsPrompt" value:@"1"]];
        
        NSURLComponents *components = [NSURLComponents componentsWithURL:realmFileURL resolvingAgainstBaseURL:NO];
        if (response != 0) {
            [fragmentItems addObject:[NSURLQueryItem queryItemWithName:@"disableSyncFileCopy" value:@"1"]];
        }
        
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
        NSURLQueryItem *syncIdentityItem = [NSURLQueryItem queryItemWithName:@"syncIdentity" value:weakSelf.syncWindowController.serverIdentity];
        components.fragmentItems = @[syncURLItem, syncIdentityItem];
        
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
    NSString *syncServerIdentity = accessoryView.syncIdentityField.stringValue;
    
    //Create a new Realm instance to create the file on disk
    @autoreleasepool {
        RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
        configuration.path = filePath;
        configuration.dynamic = YES;
        configuration.customSchema = nil;
        
        if (accessoryView.syncServerURLField.stringValue.length) {
            configuration.syncServerURL = [NSURL URLWithString:syncServerURL];
        }
        
        if (accessoryView.syncIdentityField.stringValue.length) {
            configuration.syncIdentity = syncServerIdentity;
        }
            
        [RLMRealm realmWithConfiguration:configuration error:nil];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL fileURLWithPath:filePath] resolvingAgainstBaseURL:NO];
        NSURLQueryItem *syncURLItem = [NSURLQueryItem queryItemWithName:@"syncServerURL" value:syncServerURL];
        NSURLQueryItem *syncIdentityItem = [NSURLQueryItem queryItemWithName:@"syncIdentity" value:syncServerIdentity];
        components.fragmentItems = @[syncURLItem, syncIdentityItem];
        
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:components.URL
                                                                               display:YES
                                                                     completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error)
         {
             
         }];
    });
}

- (void)showSavePanelStringFromDirectory:(NSURL *)directoryUrl completionHandler:(void(^)(BOOL userSelectesFile, NSURL *selectedFile))completion
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    // Restrict the file type to whatever you like
    savePanel.allowedFileTypes = @[kRealmFileExtension];
    
    // Set the starting directory
    savePanel.directoryURL = directoryUrl;
    
    // And show another dialog headline than "Save"
    savePanel.title = @"Generate";
    savePanel.prompt = @"Generate";
    
    // Perform other setup
    // Use a completion handler -- this is a block which takes one argument
    // which corresponds to the button that was clicked
    [savePanel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            
            // Close panel before handling errors
            [savePanel orderOut:self];
            
            // Notify caller about the file selected
            completion(YES, savePanel.URL);
        }
        else {
            completion(NO, nil);
        }
    }];
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

@end

