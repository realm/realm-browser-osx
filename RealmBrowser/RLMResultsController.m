//
//  RLMResultsController.m
//  RealmBrowser
//
//  Created by Matt Bauer on 10/26/15.
//  Copyright © 2015 Realm inc. All rights reserved.
//

#import "RLMResultsController.h"
#import "RLMResultsControllerArray.h"

@import Realm.Dynamic;

@implementation RLMResultsController {
    RLMResultsControllerArray *_arrangedObjects;
}

#pragma mark - Lifecycle

- (nonnull instancetype)initWithContent:(nullable id)content
{
    if (self = [super initWithContent:content]) {
        [self configure];
    }
    
    return self;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self configure];
    }
    
    return self;
}

- (nonnull id)arrangedObjects
{
    return _arrangedObjects;
}

#pragma mark - Private

- (void)configure
{
    [self willChangeValueForKey: @"arrangedObjects"];
    _arrangedObjects = [[RLMResultsControllerArray alloc] initWithController:self];
    [self didChangeValueForKey: @"arrangedObjects"];
}

@end
