//
//  RLMResultsControllerObservationProxy.m
//  RealmBrowser
//
//  Created by Matt Bauer on 10/28/15.
//  Copyright © 2015 Realm inc. All rights reserved.
//

#import <objc/runtime.h>
#import "RLMResultsControllerObservationProxy.h"

void NSStringKVCSplitOnDot(NSString *self,NSString **before,NSString **after){
    NSRange range=[self rangeOfString:@"."];
    if(range.location!=NSNotFound)
    {
        *before=[self substringToIndex:range.location];
        *after=[self substringFromIndex:range.location+1];
    }
    else
    {
        *before=self;
        *after=nil;
    }
}

@implementation RLMResultsControllerObservationProxy

-initWithKeyPath:(NSString *)keyPath observer:(id)observer object:(id)object {
    _keyPath=keyPath;
    _observer=observer;
    _object=object;
    return self;
}

-observer {
    return _observer;
}

-keyPath {
    return _keyPath;
}

-(void *)context {
    return _context;
}

-(NSKeyValueObservingOptions)options {
    return _options;
}

-(void)setNotifyObject:(BOOL)val
{
    _notifyObject=val;
}

- (BOOL)isEqual:(id)other
{
    if([other isMemberOfClass:object_getClass(self)])
    {
        RLMResultsControllerObservationProxy *o=other;
        if(o->_observer==_observer && [o->_keyPath isEqual:_keyPath] && [o->_object isEqual:_object])
            return YES;
    }
    return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(_notifyObject) {
        [_object observeValueForKeyPath:_keyPath ofObject:_object change:change context:_context];
    }
    
    [_observer observeValueForKeyPath:_keyPath ofObject:_object change:change context:_context];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"observation proxy for %@ on key path %@", _observer, _keyPath];
}

@end
