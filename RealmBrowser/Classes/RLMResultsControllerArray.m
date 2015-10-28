//
//  RLMResultsControllerArray.m
//  RealmBrowser
//
//  Created by Matt Bauer on 10/28/15.
//  Copyright © 2015 Realm inc. All rights reserved.
//

#import "RLMResultsControllerArray.h"
#import "RLMResultsControllerObservationProxy.h"

@implementation RLMResultsControllerArray {
    NSMutableArray *_array;
    NSMutableArray *_observationProxies;
    NSMutableIndexSet *_roi;
    RLMResultsController * _controller;
}

-objectAtIndex:(NSUInteger)idx {
    return [_array objectAtIndex:idx];
}

-(NSUInteger)count {
    return [_array count];
}

-init {
    return [self initWithObjects:NULL count:0];
}

- (instancetype)initWithController:(RLMResultsController *)controller
{
    return [self init];
}

-initWithObjects:(id *)objects count:(NSUInteger)count {
    _array=[[NSMutableArray alloc] initWithObjects:objects count:count];
    _observationProxies=[NSMutableArray new];
    return self;
}

-(void)dealloc {
    if([_observationProxies count]>0)
        [NSException raise:NSInvalidArgumentException format:@"_NSControllerArray still being observed by %@ on %@",
         [[_observationProxies objectAtIndex:0] observer],[[_observationProxies objectAtIndex:0] keyPath]];
}

-(void)addObserver:(id)observer forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options context:(void*)context {
    // init the proxy
    RLMResultsControllerObservationProxy *proxy=[[RLMResultsControllerObservationProxy alloc] initWithKeyPath:keyPath observer:observer object:self];
    
    proxy->_options=options;
    proxy->_context=context;
    [_observationProxies addObject:proxy];
    
    // get the relevant indexes
    id idxs;
    if(_roi)
        idxs=_roi;
    else
        idxs=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])];
    
    // is this an operator?
    if([keyPath hasPrefix:@"@"])
    {
        NSString* firstPart, *rest;
        NSStringKVCSplitOnDot(keyPath,&firstPart,&rest);
        
        // observe ourselves
        [super addObserver:observer forKeyPath:keyPath options:options context:context];
        
        // if there's anything the operator depends on, observe _all_ objects for that path
        keyPath=rest;
        idxs=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])];
    }
    
    // add observer proxy for all relevant indexes
    if([_array count] && keyPath) {
        [_array addObserver:proxy toObjectsAtIndexes:idxs forKeyPath:keyPath options:options context:context];
    }
}

-(void)removeObserver:(id)observer forKeyPath:(NSString*)keyPath {
    // find the proxy again
    RLMResultsControllerObservationProxy *proxy=[[RLMResultsControllerObservationProxy alloc] initWithKeyPath:keyPath observer:observer object:self];
    NSUInteger idx=[_observationProxies indexOfObject:proxy];
    proxy=[_observationProxies objectAtIndex:idx];
    [_observationProxies removeObjectAtIndex:idx];
    
    // get the relevant indexes
    id idxs;
    
    if(_roi)
        idxs=_roi;
    else
        idxs=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])];
    
    // operator?
    if([keyPath hasPrefix:@"@"])
    {
        NSString* firstPart, *rest;
        NSStringKVCSplitOnDot(keyPath,&firstPart,&rest);
        
        [super removeObserver:observer forKeyPath:keyPath];
        
        // remove dependent key path from all children
        keyPath=rest;
        idxs=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])];
    }
    if([_array count] && keyPath) {
        [_array removeObserver:proxy fromObjectsAtIndexes:idxs forKeyPath:keyPath];
    }
}

-(void)insertObject:(id)obj atIndex:(NSUInteger)idx
{
    for(RLMResultsControllerObservationProxy *proxy in _observationProxies)
    {
        id keyPath=[proxy keyPath];
        
        if([keyPath hasPrefix:@"@"]) {
            // this operator will probably have changed
            [self willChangeValueForKey:keyPath];
            
            NSString* firstPart, *rest;
            NSStringKVCSplitOnDot(keyPath,&firstPart,&rest);
            
            // if dependencies: observe these in any case
            if(rest)
                [obj addObserver:proxy
                      forKeyPath:rest
                         options:[proxy options]
                         context:[proxy context]];
        }
        else
            if(!_roi) {
                // only observe if no ROI
                [obj addObserver:proxy
                      forKeyPath:keyPath
                         options:[proxy options]
                         context:[proxy context]];
            }
    }
    
    [_array insertObject:obj atIndex:idx];
    // change ROI to reflect new state (unobserved for new index)
    [_roi shiftIndexesStartingAtIndex:idx by:1];
    
    for(RLMResultsControllerObservationProxy *proxy in _observationProxies)
    {
        id keyPath=[proxy keyPath];
        
        if([keyPath hasPrefix:@"@"])
            [self didChangeValueForKey:keyPath];
    }
}

-(void)removeObjectAtIndex:(NSUInteger)idx
{
    id obj=[_array objectAtIndex:idx];
    for(RLMResultsControllerObservationProxy *proxy in _observationProxies)
    {
        id keyPath=[proxy keyPath];
        
        if([keyPath hasPrefix:@"@"]) {
            [self willChangeValueForKey:keyPath];
            NSString* firstPart, *rest;
            NSStringKVCSplitOnDot(keyPath,&firstPart,&rest);
            
            if(rest) {
                [obj removeObserver:proxy forKeyPath:rest];
            }
        }
        else {
            if(!_roi || [_roi containsIndex:idx]) {
                [obj removeObserver:proxy forKeyPath:keyPath];
            }
        }
    }
    [_array removeObjectAtIndex:idx];
    
    if([_roi containsIndex:idx])
        [_roi shiftIndexesStartingAtIndex:idx+1 by:-1];
    
    for(RLMResultsControllerObservationProxy *proxy in _observationProxies)
    {
        id keyPath=[proxy keyPath];
        
        if([keyPath hasPrefix:@"@"])
            [self didChangeValueForKey:keyPath];
    }
}

-(void)addObject:(id)obj {
    [self insertObject:obj atIndex:[self count]];
}

-(void)removeLastObject {
    [self removeObjectAtIndex:[self count]-1];
}

-(void)replaceObjectAtIndex:(NSUInteger)idx withObject:(id)obj
{
    id old=[_array objectAtIndex:idx];
    for(RLMResultsControllerObservationProxy *proxy in _observationProxies)
    {
        id keyPath=[proxy keyPath];
        
        if([keyPath hasPrefix:@"@"]) {
            [self willChangeValueForKey:keyPath];
            NSString* firstPart, *rest;
            NSStringKVCSplitOnDot(keyPath,&firstPart,&rest);
            
            if(rest) {
                [old removeObserver:proxy forKeyPath:[proxy keyPath]];
                
                [obj addObserver:proxy
                      forKeyPath:rest
                         options:[proxy options]
                         context:[proxy context]];
            }
        }
        else {
            if(!_roi || [_roi containsIndex:idx]) {
                [old removeObserver:proxy forKeyPath:[proxy keyPath]];
                
                [obj addObserver:proxy
                      forKeyPath:[proxy keyPath]
                         options:[proxy options]
                         context:[proxy context]];
            }
        }
    }
    [_array replaceObjectAtIndex:idx withObject:obj];
    
    for(RLMResultsControllerObservationProxy *proxy in _observationProxies)
    {
        id keyPath=[proxy keyPath];
        
        if([keyPath hasPrefix:@"@"])
            [self didChangeValueForKey:keyPath];
    }
}

-(void)setROI:(NSIndexSet*)newROI {
    if(newROI != _roi) {
        id proxies=[_observationProxies copy];
        
        // TODO: this should be optimized to only change those indexes that actually changed
        for(RLMResultsControllerObservationProxy *proxy in proxies) {
            [self removeObserver:[proxy observer] forKeyPath:[proxy keyPath]];
        }
        
        _roi=[newROI mutableCopy];
        
        for(RLMResultsControllerObservationProxy *proxy in proxies) {
            [self addObserver:[proxy observer] forKeyPath:[proxy keyPath] options:[proxy options] context:[proxy context]];
        }
    }
}
@end
