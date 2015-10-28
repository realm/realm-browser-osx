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

#import "RLMTypeOutlineViewController.h"

#import "RLMRealmBrowserWindowController.h"
#import "RLMRealmOutlineNode.h"
#import "RLMArrayNavigationState.h"
#import "RLMQueryNavigationState.h"
#import "RLMObjectNode.h"
#import "RLMResultsNode.h"
#import "RLMRealmOutlineNode.h"

NSString * RLMTypeOutlineViewControllerClassesKey = @"Classes";
NSString * RLMTypeOutlineViewControllerObjectsKey = @"Objects";

@interface RLMTypeOutlineViewController ()

@end

@implementation RLMTypeOutlineViewController

- (void)viewDidLoad
{
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)viewDidAppear
{
    [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    [self outlineViewSelectionDidChange:[NSNotification notificationWithName:@"" object:self.outlineView]];
}

#pragma mark - NSOutlineViewDataSource implementation

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item) {
        if (index == 0) {
            return RLMTypeOutlineViewControllerClassesKey;
        } else if (index == 1) {
            return RLMTypeOutlineViewControllerObjectsKey;
        }
    } else if ([item isEqualToString:RLMTypeOutlineViewControllerClassesKey]) {
        return [self.document.realm.schema.objectSchema objectAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (!item) {
        return YES;
    } else if ([item isKindOfClass:[NSString class]]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    return ([item isKindOfClass:[NSString class]]);
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item) {
        return 2;
    } else if ([item isEqualToString:RLMTypeOutlineViewControllerClassesKey]) {
        return self.document.realm.schema.objectSchema.count;
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return item;
}

#pragma mark - NSOutlineViewDelegate implementation

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    // Group headers should not be selectable
    return ![item isKindOfClass:[NSString class]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    return NO;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView
           toolTipForCell:(NSCell *)cell
                     rect:(NSRectPointer)rect
              tableColumn:(NSTableColumn *)tc
                     item:(id)item
            mouseLocation:(NSPoint)mouseLocation
{
    if ([item respondsToSelector:@selector(hasToolTip)]) {
        if ([item respondsToSelector:@selector(toolTipString)]) {
            return [item toolTipString];
        }
    }
    
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSOutlineView *outlineView = notification.object;
    NSInteger row = [outlineView selectedRow];

    // The arrays we get from link views are ephemeral, so we
    // remove them when any class node is selected
    if (row != -1) {
        self.document.selectedObjectSchema = [outlineView itemAtRow:row];
    }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isKindOfClass:[NSString class]]) {
        return [outlineView makeViewWithIdentifier:@"header" owner:self];
    } else if ([item isKindOfClass:[RLMObjectSchema class]]) {
        return [outlineView makeViewWithIdentifier:@"class" owner:self];
    } else {
        return nil;
    }
}

@end
