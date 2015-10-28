//
//  RLMResultsControllerArray.h
//  RealmBrowser
//
//  Created by Matt Bauer on 10/28/15.
//  Copyright © 2015 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLMResultsController.h"

@interface RLMResultsControllerArray : NSMutableArray

- (instancetype)initWithController:(RLMResultsController *)controller;

@end
