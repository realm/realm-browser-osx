//
//  RLMObjectLinkSelectionViewController.h
//  RealmBrowser
//
//  Created by sbuglakov on 24/08/15.
//  Copyright (c) 2015 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RLMTypeNode;
@class RLMObject;

@interface RLMObjectLinkSelectionViewController : NSViewController

@property (nonatomic, copy) void(^didSelectedBlock)(RLMObject *rowObject);
@property (nonatomic, strong) RLMTypeNode *displayedType;

+ (instancetype)loadInstance;

@end
