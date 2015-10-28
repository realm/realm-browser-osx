//
//  RLMRealmViewController.m
//  RealmBrowser
//
//  Created by Matt Bauer on 10/27/15.
//  Copyright © 2015 Realm inc. All rights reserved.
//

#import "RLMRealmViewController.h"
#import "RLMTableViewController.h"

@interface RLMRealmViewController ()

@property (nonatomic, strong) NSMutableDictionary *objectSchemaTableViews;

@end

@implementation RLMRealmViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.objectSchemaTableViews = [NSMutableDictionary dictionary];
    
    [self.document addObserver:self forKeyPath:@"selectedObjectSchema" options:0 context:NULL];
}

- (void)dealloc
{
    [self.document removeObserver:self forKeyPath:@"selectedObjectSchema"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
//    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateForSelectedObjectSchema];
//    });
}

- (void)updateForSelectedObjectSchema
{
    [[[self.view subviews] firstObject] removeFromSuperview];
    
    RLMTableViewController *vc = self.objectSchemaTableViews[self.document.selectedObjectSchema.className];
    
    if (!vc) {
        vc = [[RLMTableViewController alloc] initWithNibName:@"RLMTableViewController" bundle:nil];
        [vc loadView];
        [vc bind:@"document" toObject:self withKeyPath:@"document" options:nil];
        [vc setObjectSchema:self.document.selectedObjectSchema];
        self.objectSchemaTableViews[self.document.selectedObjectSchema.className] = vc;
    }

    NSView *view = vc.view;
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:view];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];    
}

@end
