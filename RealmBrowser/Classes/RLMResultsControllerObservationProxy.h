//
//  RLMResultsControllerObservationProxy.h
//  RealmBrowser
//
//  Created by Matt Bauer on 10/28/15.
//  Copyright © 2015 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RLMResultsControllerObservationProxy : NSObject {
    id _keyPath;
    id _observer;
    id _object;
    BOOL _notifyObject;
    // only as storage (context for _observer will be the one given in observeValueForKeyPath:)
    // FIXME: write accessors, remove @public
@public
    void *_context;
    NSKeyValueObservingOptions _options;
}
- initWithKeyPath:(NSString *)keyPath observer:(id)observer object:(id)object;
- (id)observer;
- (id)keyPath;
- (void)setNotifyObject:(BOOL)val;
- (void *)context;
- (NSKeyValueObservingOptions)options;
@end

void NSStringKVCSplitOnDot(NSString *self, NSString **before, NSString **after);
