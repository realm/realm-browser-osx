//
//  RLMObjectLinkSelectionViewController.m
//  RealmBrowser
//
//  Created by sbuglakov on 24/08/15.
//  Copyright (c) 2015 Realm inc. All rights reserved.
//

#import "RLMObjectLinkSelectionViewController.h"
#import "RLMInstanceTableViewController.h"

@interface RLMObjectLinkSelectionViewController ()
@property (nonatomic, strong) IBOutlet RLMInstanceTableViewController *tableController;
@end

@implementation RLMObjectLinkSelectionViewController

+ (instancetype)loadInstance {
    return [[RLMObjectLinkSelectionViewController alloc] initWithNibName:@"RLMObjectLinkSelectionViewController" bundle:[NSBundle mainBundle]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.displayedType != nil) {
        self.displayedType = self.displayedType;
    }
    if (self.didSelectedBlock != nil) {
        self.didSelectedBlock = self.didSelectedBlock;
    }
}

- (void)setDisplayedType:(RLMTypeNode *)newNode {
    _displayedType = newNode;
    if (self.isViewLoaded) {
        RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:_displayedType index:NSNotFound];
        [self.tableController performUpdateUsingState:state oldState:nil];
    }
}

- (void)setDidSelectedBlock:(void (^)(RLMObject *))didSelectedBlock {
    _didSelectedBlock = didSelectedBlock;
    if (self.isViewLoaded) {
        self.tableController.didSelectedBlock = didSelectedBlock;
    }
}

@end
