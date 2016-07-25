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
@import RealmConverter;

#import "RLMBrowserConstants.h"
#import "RLMApplicationDelegate.h"
#import "RLMTestDataGenerator.h"
#import "RLMUtils.h"
#import "TestClasses.h"

#import <AppSandboxFileAccess/AppSandboxFileAccess.h>

@interface RLMApplicationDelegate ()

@property (nonatomic, weak) IBOutlet NSMenu *fileMenu;
@property (nonatomic, weak) IBOutlet NSMenuItem *openMenuItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *openEncryptedMenuItem;
@property (nonatomic, weak) IBOutlet NSMenu *openAnyRealmMenu;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, assign) BOOL didLoadFile;

@property (nonatomic, strong) NSMetadataQuery *realmQuery;
@property (nonatomic, strong) NSMetadataQuery *appQuery;
@property (nonatomic, strong) NSMetadataQuery *projQuery;
@property (nonatomic, strong) NSArray *groupedFileItems;

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
    NSImage *image = [NSImage imageNamed:@"RealmFileIcon"];
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
    NSString *homeDir = RLMRealHomeDirectory();
    
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
    NSArray *tempGroupedFileItems = @[simDict, devDict, desktopDict, documentsdDict, downloadDict, otherDict];
    
    // Iterate through all search results
    for (NSMetadataItem *fileItem in self.realmQuery.results) {
        // Iterate through the different prefixes and add item to corresponding array within dictionary
        for (NSDictionary *dict in tempGroupedFileItems) {
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
    
    // Do not include empty groups
    self.groupedFileItems = [tempGroupedFileItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K.@count > 1", kItems]];
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
        
        AppSandboxFileAccess *fileAccess = [AppSandboxFileAccess fileAccess];
        [fileAccess requestAccessPermissionsForFileURL:directoryURL persistPermission:YES withBlock:^(NSURL *securelyScopedURL, NSData *bookmarkData) {
            [securelyScopedURL startAccessingSecurityScopedResource];
            
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
            
            //As realm files perform some file-system level cleanup during their dealloc phase,
            //make sure the sandbox access is removed in the next run loop to give it some time to finish.
            dispatch_async(dispatch_get_main_queue(), ^{
                [securelyScopedURL stopAccessingSecurityScopedResource];
            });
        }];
    }];
}

#pragma mark - Import Methods -
- (IBAction)importFileFromXLSX:(id)sender
{
    // Get the file to import
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.message = @"Please choose the XLSX file you wish to import.";
    openPanel.allowedFileTypes = @[@"xlsx"];

    NSInteger result = [openPanel runModal];
    if (result != NSFileHandlingPanelOKButton) {
        return;
    }
    
    NSURL *targetFileURL = openPanel.URL;
    
    // Get the destination folder to save the Realm file
    NSOpenPanel *savePanel = [NSOpenPanel openPanel];
    savePanel.canChooseDirectories = YES;
    savePanel.canChooseFiles = NO;
    savePanel.canCreateDirectories = YES;
    savePanel.allowsMultipleSelection = NO;
    savePanel.message = @"Please choose the destination folder for the new Realm file.";
    
    result = [savePanel runModal];
    if (result != NSFileHandlingPanelOKButton) {
        return;
    }
    
    NSURL *targetDirectoryURL = savePanel.URL;
    NSString *realmFilePath = [targetDirectoryURL.path stringByAppendingPathComponent:@"default.realm"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:realmFilePath]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"A Realm file named \"default.realm\" already exists in that location. Do you wish to proceed?"
                                         defaultButton:@"Cancel"
                                       alternateButton:@"OK"
                                           otherButton:nil
                             informativeTextWithFormat:@"The existing file will be deleted and replaced with a new one. This operation cannot be undone."];
        NSInteger result = [alert runModal];
        if (result > 0) {
            return;
        }
    
        [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    }
    
    AppSandboxFileAccess *fileAccess = [AppSandboxFileAccess fileAccess];
    [fileAccess requestAccessPermissionsForFileURL:targetDirectoryURL persistPermission:YES withBlock:^(NSURL *securelyScopedURL, NSData *bookmarkData) {
        [securelyScopedURL startAccessingSecurityScopedResource];
    
        @autoreleasepool {
            RLMImportSchemaGenerator *schemaGenerator = [[RLMImportSchemaGenerator alloc] initWithFile:targetFileURL.path encoding:EncodingUTF8];
            RLMImportSchema *schema = [schemaGenerator generatedSchemaWithError:nil];
            
            if (schema == nil) {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to Generate Schema" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please check the file is in the correct format and try again."];
                [alert runModal];
                return;
            }
            
            RLMXLSXDataImporter *importer = [[RLMXLSXDataImporter alloc] initWithFile:targetFileURL.path encoding:EncodingUTF8];
            [importer importToPath:targetDirectoryURL.path withSchema:schema error:nil];
        }
        
        [securelyScopedURL stopAccessingSecurityScopedResource];
    }];
}

- (IBAction)importFileFromCSV:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.message   = @"Please choose the CSV files you wish to import.";
    openPanel.allowedFileTypes = @[@"csv"];
    
    NSInteger result = [openPanel runModal];
    if (result != NSFileHandlingPanelOKButton) {
        return;
    }
    
    NSArray *fileURLs = openPanel.URLs;
    NSMutableArray *filePaths = [NSMutableArray array];
    for (NSURL *url in fileURLs) {
        [filePaths addObject:url.path];
    }
    
    NSOpenPanel *savePanel = [NSOpenPanel openPanel];
    savePanel.canChooseDirectories = YES;
    savePanel.canChooseFiles = NO;
    savePanel.canCreateDirectories = YES;
    savePanel.allowsMultipleSelection = NO;
    savePanel.message = @"Please choose the destination folder for the new Realm file.";
    
    result = [savePanel runModal];
    if (result != NSFileHandlingPanelOKButton) {
        return;
    }
    
    NSURL *targetDirectoryURL = savePanel.URL;
    NSString *realmFilePath = [targetDirectoryURL.path stringByAppendingPathComponent:@"default.realm"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:realmFilePath]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"A Realm file named \"default.realm\" already exists in that location. Do you wish to proceed?"
                                         defaultButton:@"Cancel"
                                       alternateButton:@"OK"
                                           otherButton:nil
                             informativeTextWithFormat:@"The existing file will be deleted and replaced with a new one. This operation cannot be undone."];
        
        NSInteger result = [alert runModal];
        if (result > 0) {
            return;
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    }
    
    AppSandboxFileAccess *fileAccess = [AppSandboxFileAccess fileAccess];
    [fileAccess requestAccessPermissionsForFileURL:targetDirectoryURL persistPermission:YES withBlock:^(NSURL *securelyScopedURL, NSData *bookmarkData) {
        [securelyScopedURL startAccessingSecurityScopedResource];
    
        @autoreleasepool {
            RLMImportSchemaGenerator *schemaGenerator = [[RLMImportSchemaGenerator alloc] initWithFiles:filePaths encoding:EncodingUTF8];
            RLMImportSchema *schema = [schemaGenerator generatedSchemaWithError:nil];
            
            if (schema == nil) {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to Generate Schema" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please check the files are in the correct format and try again."];
                [alert runModal];
                return;
            }
            
            RLMCSVDataImporter *importer = [[RLMCSVDataImporter alloc] initWithFiles:filePaths encoding:EncodingUTF8];
            [importer importToPath:targetDirectoryURL.path withSchema:schema error:nil];
        }
        
        [securelyScopedURL stopAccessingSecurityScopedResource];
    }];
}

#pragma mark - Private methods

-(void)openFileWithMenuItem:(NSMenuItem *)menuItem
{
    [self openFileAtURL:menuItem.representedObject];
}

-(void)openFileAtURL:(NSURL *)url
{
    NSDocumentController *documentController = [[NSDocumentController alloc] init];
    [documentController openDocumentWithContentsOfURL:url
                                              display:YES
                                    completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
                                    }];
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

@end

