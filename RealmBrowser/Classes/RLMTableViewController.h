//
//  RLMTableViewController.h
//  RealmBrowser
//
//  Created by Matt Bauer on 10/27/15.
//  Copyright © 2015 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RLMDocument.h"
#import "RLMResultsController.h"

@interface RLMTableViewController : NSViewController <NSTableViewDelegate>

@property (weak) IBOutlet NSTableView * tableView;
@property (weak) IBOutlet NSArrayController * arrayController;

@property (nonatomic, strong) RLMDocument * document;
@property (nonatomic, strong) RLMObjectSchema * objectSchema;

@end
