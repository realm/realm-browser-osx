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

#import "RLMInstanceTableViewController.h"
@import Foundation;
@import Realm.Dynamic;

#import "RLMRealmBrowserWindowController.h"
#import "RLMObjectLinkSelectionViewController.h"
#import "RLMArrayNavigationState.h"
#import "RLMQueryNavigationState.h"
#import "RLMArrayNode.h"
#import "RLMResultsNode.h"
#import "RLMRealmNode.h"

#import "RLMBadgeTableCellView.h"
#import "RLMBasicTableCellView.h"
#import "RLMBoolTableCellView.h"
#import "RLMOptionalBoolTableCellView.h"
#import "RLMNumberTableCellView.h"
#import "RLMImageTableCellView.h"

#import "RLMTableColumn.h"

#import "NSColor+ByteSizeFactory.h"

#import "objc/objc-class.h"

#import "RLMDescriptions.h"

NSString * const kRLMObjectType = @"RLMObjectType";
static const NSInteger NOT_A_COLUMN = -1;
static const NSInteger NOT_A_ROW = -1;
static const NSInteger ARRAY_GUTTER_INDEX = -1;

typedef NS_ENUM(int32_t, RLMUpdateType) {
    RLMUpdateTypeRealm,
    RLMUpdateTypeTableView
};

@implementation RLMInstanceTableViewController {
    BOOL awake;
    BOOL linkCursorDisplaying;
    NSDateFormatter *dateFormatter;
    NSNumberFormatter *numberFormatter;
    NSMutableDictionary *autofittedColumns;
    RLMDescriptions *realmDescriptions;
}

#pragma mark - NSObject Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];

    if (awake) {
        return;
    }
    
    [self.tableView setTarget:self];
    [self.tableView setAction:@selector(userClicked:)];
    [self.tableView setDoubleAction:@selector(userDoubleClicked:)];

    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    linkCursorDisplaying = NO;
    
    autofittedColumns = [NSMutableDictionary dictionary];
    
    realmDescriptions = [[RLMDescriptions alloc] init];
    
    [self.tableView registerForDraggedTypes:@[kRLMObjectType]];
    [self.tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];

    awake = YES;
}

#pragma mark - Public methods - Accessors

- (RLMTableView *)realmTableView
{
    return (RLMTableView *)self.tableView;
}

#pragma mark - RLMViewController Overrides

- (void)performUpdateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState
{
    [super performUpdateUsingState:newState oldState:oldState];
    
    [self.tableView setAutosaveTableColumns:NO];
    
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    
    if ([newState isMemberOfClass:[RLMNavigationState class]]) {
        self.displayedType = newState.selectedType;
        [self.realmTableView setupColumnsWithType:newState.selectedType];
        
        if (newState.selectedInstanceIndex != NSNotFound) {
            [self setSelectionIndex:newState.selectedInstanceIndex];
        }
    }
    else if ([newState isMemberOfClass:[RLMArrayNavigationState class]]) {
        RLMArrayNavigationState *arrayState = (RLMArrayNavigationState *)newState;
        
        RLMClassNode *referringType = (RLMClassNode *)arrayState.selectedType;
        RLMObject *referingInstance = [referringType instanceAtIndex:arrayState.selectedInstanceIndex];
        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithReferringProperty:arrayState.property
                                                                         onObject:referingInstance
                                                                            realm:realm];
        self.displayedType = arrayNode;
        [self.realmTableView setupColumnsWithType:arrayNode];
        [self setSelectionIndex:arrayState.arrayIndex];
    }
    else if ([newState isMemberOfClass:[RLMQueryNavigationState class]]) {
        RLMQueryNavigationState *queryState = (RLMQueryNavigationState *)newState;
        
        RLMResultsNode *resultsNode = [[RLMResultsNode alloc] initWithQuery:queryState.searchText
                                                                     result:queryState.results
                                                                  andParent:queryState.selectedType];
        self.displayedType = resultsNode;
        [self.realmTableView setupColumnsWithType:resultsNode];
        [self setSelectionIndex:0];
    }
    
    self.tableView.autosaveName = [NSString stringWithFormat:@"%lu:%@", realm.hash, self.displayedType.name];
    [self.tableView setAutosaveTableColumns:YES];
    
    if (![autofittedColumns[self.tableView.autosaveName] isEqual:@YES]) {
        [self.realmTableView makeColumnsFitContents];
        autofittedColumns[self.tableView.autosaveName] = @YES;
    }
}

#pragma mark - NSTableView Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView != self.tableView) {
        return 0;
    }
    
    return self.displayedType.instanceCount;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if (self.realmIsLocked || !self.displaysArray) {
        return NO;
    }
    
    NSData *indexSetData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:@[kRLMObjectType] owner:self];
    [pboard setData:indexSetData forType:kRLMObjectType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropAbove) {
        return NSDragOperationMove;
    }
    
    return NSDragOperationNone;
}

-(void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes {
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)destination dropOperation:(NSTableViewDropOperation)operation
{
    if (self.realmIsLocked || !self.displaysArray) {
        return NO;
    }
    
    // Check that the dragged item is of correct type
    NSArray *supportedTypes = @[kRLMObjectType];
    NSPasteboard *draggingPasteboard = [info draggingPasteboard];
    NSString *availableType = [draggingPasteboard availableTypeFromArray:supportedTypes];
    
    if ([availableType compare:kRLMObjectType] == NSOrderedSame) {
        NSData *rowIndexData = [draggingPasteboard dataForType:kRLMObjectType];
        NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowIndexData];
        
        // Performs the move in the realm
        [self moveRowsInRealmFrom:rowIndexes to:destination];
        
        return YES;
    }
    
    return NO;
}

#pragma mark - RLMTableView Data Source

-(NSString *)headerToolTipForColumn:(RLMClassProperty *)propertyColumn
{
    numberFormatter.maximumFractionDigits = 3;

    // For certain types we want to add some statistics
    RLMPropertyType type = propertyColumn.property.type;
    NSString *propertyName = propertyColumn.property.name;
    
    if (![self.displayedType isKindOfClass:[RLMClassNode class]]) {
        return nil;
    }
    
    RLMResults *results = ((RLMClassNode *)self.displayedType).allObjects;
    switch (type) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble: {
            numberFormatter.minimumFractionDigits = (type == RLMPropertyTypeInt) ? 0 : 3;
            NSString *min = [numberFormatter stringFromNumber:[results minOfProperty:propertyName]];
            NSString *avg = [numberFormatter stringFromNumber:[results averageOfProperty:propertyName]];
            NSString *max = [numberFormatter stringFromNumber:[results maxOfProperty:propertyName]];
            NSString *sum = [numberFormatter stringFromNumber:[results sumOfProperty:propertyName]];
            
            return [NSString stringWithFormat:@"Minimum: %@\nAverage: %@\nMaximum: %@\nSum: %@", min, avg, max, sum];
        }
        case RLMPropertyTypeDate: {
            NSString *min = [dateFormatter stringFromDate:[results minOfProperty:propertyName]];
            NSString *max = [dateFormatter stringFromDate:[results maxOfProperty:propertyName]];
            
            return [NSString stringWithFormat:@"Earliest: %@\nLatest: %@", min, max];
        }
        case RLMPropertyTypeBool: {
            NSUInteger count = results.count;
            if (count == 0) return nil;

            // we have to query for both, as there might also be NULL values.
            NSUInteger trueCount  = [results objectsWhere:@"%K == YES", propertyName].count;
            NSUInteger falseCount = [results objectsWhere:@"%K == NO",  propertyName].count;
            float percentTrue  = trueCount * 100.0 / count;
            float percentFalse = falseCount * 100.0 / count;

            return [NSString stringWithFormat:@"True: %lu (%.1f%%)\nFalse: %lu (%.1f%%)", (unsigned long)trueCount, percentTrue, (unsigned long)falseCount, percentFalse];
        }
        default:
            return nil;
    }
}

#pragma mark - NSTableView Delegate

-(CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column
{
    RLMTableColumn *tableColumn = (RLMTableColumn *)self.realmTableView.tableColumns[column];
    
    return [tableColumn sizeThatFitsWithLimit:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView == notification.object) {
        NSInteger selectedIndex = self.tableView.selectedRow;
        [self.parentWindowController.currentState updateSelectionToIndex:selectedIndex];
        
        if (self.didSelectedBlock != nil) {
            RLMObject *selectedInstance = [self.displayedType instanceAtIndex:selectedIndex];
            self.didSelectedBlock(selectedInstance);
        }
    }
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView != self.tableView) {
        return nil;
    }
    
    NSUInteger column = [tableView.tableColumns indexOfObject:tableColumn];
    NSInteger propertyIndex = [self propertyIndexForColumn:column];
    
    // Array gutter
    if (propertyIndex == ARRAY_GUTTER_INDEX) {
        RLMBasicTableCellView *gutterCellView = [tableView makeViewWithIdentifier:@"GutterCell" owner:self];

        if (gutterCellView == nil) {
            gutterCellView = [RLMBasicTableCellView viewWithIdentifier:@"GutterCell"];
        }

        gutterCellView.textField.stringValue = [@(rowIndex) stringValue];
        gutterCellView.textField.editable = NO;

        return gutterCellView;
    }
    
    RLMClassProperty *classProperty = self.displayedType.propertyColumns[propertyIndex];
    RLMObject *selectedInstance = [self.displayedType instanceAtIndex:rowIndex];
    id propertyValue = selectedInstance[classProperty.name];
    RLMPropertyType type = classProperty.type;
    BOOL optional = classProperty.property.optional;
    NSString *reuseIdentifier = [NSString stringWithFormat:@"Property.%@.Optional.%d", [RLMDescriptions typeNameOfProperty:classProperty.property], optional];
    
    NSTableCellView *cellView;
    switch (type) {
        case RLMPropertyTypeArray: {
            RLMBadgeTableCellView *badgeCellView = [tableView makeViewWithIdentifier:reuseIdentifier owner:self];
            if (!badgeCellView) {
                badgeCellView = [RLMBadgeTableCellView viewWithIdentifier:reuseIdentifier];
                badgeCellView.optional = YES;
            }
            NSString *string = [realmDescriptions printablePropertyValue:propertyValue ofType:type];
            NSDictionary *attr = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)};
            badgeCellView.textField.attributedStringValue = [[NSAttributedString alloc] initWithString:string attributes:attr];
            
            badgeCellView.textField.editable = NO;

            badgeCellView.badge.hidden = NO;
            badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", [(RLMArray *)propertyValue count]];
            [badgeCellView.badge.cell setHighlightsBy:0];
            
            cellView = badgeCellView;
            
            break;
        }
            
        case RLMPropertyTypeBool: {
            if (optional) {
                RLMOptionalBoolTableCellView *boolCellView = [tableView makeViewWithIdentifier:reuseIdentifier owner:self];
                if (!boolCellView) {
                    boolCellView = [RLMOptionalBoolTableCellView viewWithIdentifier:reuseIdentifier];
                    boolCellView.popupControl.target = self;
                    boolCellView.popupControl.action = @selector(optionalBoolPopupChanged:);
                }
                
                // 0 = nil, 1 = False, 2 = True
                if (propertyValue == nil) {
                    [boolCellView.popupControl selectItemAtIndex:0];
                }
                else {
                    if ([propertyValue boolValue]) {
                        [boolCellView.popupControl selectItemAtIndex:2];
                    }
                    else {
                        [boolCellView.popupControl selectItemAtIndex:1];
                    }
                }

                cellView = boolCellView;
            }
            else {
                RLMBoolTableCellView *boolCellView = [tableView makeViewWithIdentifier:reuseIdentifier owner:self];
                if (!boolCellView) {
                    boolCellView = [RLMBoolTableCellView viewWithIdentifier:reuseIdentifier];
                    boolCellView.checkBox.target = self;
                    boolCellView.checkBox.action = @selector(editedCheckBox:);
                }
                boolCellView.checkBox.state = [(NSNumber *)propertyValue boolValue] ? NSOnState : NSOffState;
                [boolCellView.checkBox setEnabled:!self.realmIsLocked];
                
                cellView = boolCellView;
            }
            
            break;
        }
            // Intentional fallthrough
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble: {
            RLMNumberTableCellView *numberCellView = [tableView makeViewWithIdentifier:reuseIdentifier owner:self];
            if (!numberCellView) {
                numberCellView = [RLMNumberTableCellView viewWithIdentifier:reuseIdentifier];
                numberCellView.textField.target = self;
                numberCellView.textField.action = @selector(editedTextField:);
            }

            numberCellView.optional = optional;
            numberCellView.textField.objectValue = propertyValue;            
            numberCellView.textField.editable = !self.realmIsLocked;

            cellView = numberCellView;
            
            break;
        }

        case RLMPropertyTypeObject: {
            RLMLinkTableCellView *linkCellView = [tableView makeViewWithIdentifier:reuseIdentifier owner:self];
            if (!linkCellView) {
                linkCellView = [RLMLinkTableCellView viewWithIdentifier:reuseIdentifier];
                linkCellView.textField.target = self;
                linkCellView.textField.action = @selector(editedTextField:);
            }
            linkCellView.optional = optional;
            
            NSString *string = [realmDescriptions printablePropertyValue:propertyValue ofType:type];
            NSDictionary *attr = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)};
            linkCellView.textField.attributedStringValue = [[NSAttributedString alloc] initWithString:string attributes:attr];
            
            linkCellView.textField.editable = NO;

            cellView = linkCellView;

            break;
        }
            // Intentional fallthrough
        case RLMPropertyTypeLinkingObjects:
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeString: {
            RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:reuseIdentifier owner:self];
            if (!basicCellView) {
                basicCellView = [RLMBasicTableCellView viewWithIdentifier:reuseIdentifier];
                basicCellView.textField.target = self;
                basicCellView.textField.action = @selector(editedTextField:);
            }
            basicCellView.optional = optional;
            basicCellView.textField.stringValue = [realmDescriptions printablePropertyValue:propertyValue ofType:type];
            basicCellView.textField.editable = !self.realmIsLocked && type != RLMPropertyTypeData;

            cellView = basicCellView;
            
            break;
        }
    }
    
    if (type != RLMPropertyTypeArray) {
        cellView.toolTip = [realmDescriptions tooltipForPropertyValue:propertyValue ofType:type];
    }

    return cellView;
}

#pragma mark - RLMTableView Delegate

// Asking the delegate about the state
- (BOOL)displaysArray
{
    return ([self.displayedType isMemberOfClass:[RLMArrayNode class]]);
}

- (BOOL)isColumnObjectType:(NSInteger)column;
{
    NSAssert(column != NOT_A_COLUMN, @"This method can only be used with an actual column index");
    return [self propertyTypeForColumn:column] == RLMPropertyTypeObject;
}

// Asking the delegate about the contents
- (BOOL)containsObjectInRows:(NSIndexSet *)rowIndexes column:(NSInteger)column;
{
    NSAssert(column != NOT_A_COLUMN, @"This method can only be used with an actual column index");
    
    if ([self propertyTypeForColumn:column] != RLMPropertyTypeObject) {
        return NO;
    }

    NSInteger propertyIndex = [self propertyIndexForColumn:column];
   
    return [self cellsAreNonEmptyInRows:rowIndexes propertyColumn:propertyIndex];
}

- (BOOL)containsArrayInRows:(NSIndexSet *)rowIndexes column:(NSInteger)column;
{
    NSAssert(column != NOT_A_COLUMN, @"This method can only be used with an actual column index");

    NSInteger propertyIndex = [self propertyIndexForColumn:column];
    
    if ([self propertyTypeForColumn:column] != RLMPropertyTypeArray) {
        return NO;
    }
    
    return [self cellsAreNonEmptyInRows:rowIndexes propertyColumn:propertyIndex];
}

// RLMObject operations (when showing class table)
- (void)deleteObjects:(NSIndexSet *)rowIndexes
{
    [self deleteObjectsInRealmAtIndexes:rowIndexes];
    [self.parentWindowController reloadAllWindows];
}

- (void)addNewObjects:(NSIndexSet *)rowIndexes
{
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    NSUInteger objectCount = MAX(rowIndexes.count, 1);

    RLMObject *newObject;
    
    [realm beginWriteTransaction];
    for (NSUInteger i = 0; i < objectCount; i++) {
        newObject = [self.class createObjectInRealm:realm withSchema:self.displayedType.schema];
    }
    [realm commitWriteTransaction];
    
    [self.parentWindowController reloadAllWindows];
    
    if (newObject && [self.displayedType isKindOfClass:RLMClassNode.class]) {
        RLMClassNode *classNode = (RLMClassNode *)self.displayedType;
        NSUInteger row = [classNode indexOfInstance:newObject];
        [self.realmTableView scrollToRow:row];
    }
}

// RLMArray operations
- (void)removeRows:(NSIndexSet *)rowIndexes
{
    [self removeRowsInRealmAt:rowIndexes];
}

- (void)deleteRows:(NSIndexSet *)rowIndexes
{
    [self deleteRowsInRealmAt:rowIndexes];
}

- (void)addNewRows:(NSIndexSet *)rowIndexes
{
    [self insertNewRowsInRealmAt:rowIndexes];
}

// Operations on links in cells

- (void)setObjectLinkAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)columnIndex {
    RLMObjectLinkSelectionViewController *popoverContent = [RLMObjectLinkSelectionViewController loadInstance];
    NSPopover *popover = [[NSPopover alloc] init];
    popover.contentViewController = popoverContent;
    popover.behavior = NSPopoverBehaviorTransient;
    
    NSArray *topLevelClasses = self.parentWindowController.document.presentedRealm.topLevelClasses;
    
    RLMObject *selectedInstance = [self.displayedType instanceAtIndex:rowIndexes.firstIndex];
    NSInteger propertyIndex = [self propertyIndexForColumn:columnIndex];
    
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:self.displayedType.name];
    RLMProperty *property = objectSchema.properties[propertyIndex];
    
    for (RLMClassNode *classNode in topLevelClasses) {
        if ([classNode.name isEqualToString:property.objectClassName]) {
            [popoverContent setDisplayedType:classNode];
        }
    }
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(popover) weakPopover = popover;
    
    popoverContent.didSelectedBlock = ^(RLMObject *object) {
        RLMRealm *realm = weakSelf.parentWindowController.document.presentedRealm.realm;
        [realm beginWriteTransaction];
        
        selectedInstance[property.name] = object;
        
        [realm commitWriteTransaction];
        [weakPopover close];
    };
    
    NSRect cellRect = [self.tableView frameOfCellAtColumn:columnIndex row:rowIndexes.firstIndex];
    [popover showRelativeToRect:cellRect ofView:self.tableView preferredEdge:NSMaxYEdge];
}

- (void)removeObjectLinksAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)columnIndex
{
    [self removeContentsAtRows:rowIndexes column:columnIndex];
}

- (void)removeArrayLinksAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)columnIndex
{
    [self removeContentsAtRows:rowIndexes column:columnIndex];
}

// Opening an array in a new window
- (void)openArrayInNewWindowAtRow:(NSInteger)row column:(NSInteger)column
{
    NSInteger propertyIndex = [self propertyIndexForColumn:column];
    RLMClassProperty *propertyNode = self.displayedType.propertyColumns[propertyIndex];
    RLMArrayNavigationState *state = [[RLMArrayNavigationState alloc] initWithSelectedType:self.displayedType
                                                                                 typeIndex:row
                                                                                  property:propertyNode.property
                                                                                arrayIndex:0];
    
    [self.parentWindowController newWindowWithNavigationState:state];
}

#pragma mark - Private Methods - RLMTableView Delegate Helpers

+ (RLMObject *)createObjectInRealm:(RLMRealm *)realm withSchema:(RLMObjectSchema *)schema
{
    NSMutableDictionary *objectBlueprint = [self defaultValuesForSchema:schema];
    RLMProperty *primaryKey = schema.primaryKeyProperty;
    
    if (primaryKey) {
        id uniqueValue = [self uniqueValueForProperty:primaryKey className:schema.className inRealm:realm];
        if (!uniqueValue) {
            return nil;
        }
        
        objectBlueprint[primaryKey.name] = uniqueValue;
    }
    
    return [realm createObject:schema.className withValue:objectBlueprint];
}

+ (id)uniqueValueForProperty:(RLMProperty *)primaryKey className:(NSString *)className inRealm:(RLMRealm *)realm
{
    NSUInteger remainingAttempts = 100;
    NSUInteger maxBitsUsed = 8;
    
    while (remainingAttempts > 0) {
        id uniqueValue;
        
        if (primaryKey.type == RLMPropertyTypeInt) {
            u_int32_t maxInt = MIN(1 << maxBitsUsed++, UINT32_MAX);
            uniqueValue = @(arc4random_uniform(maxInt));
        } else if (primaryKey.type == RLMPropertyTypeString) {
            uniqueValue = [[NSUUID UUID] UUIDString];
        }
        
        if ([[realm objects:className where:@"%K == %@", primaryKey.name, uniqueValue] count] == 0) {
            return uniqueValue;
        }

        remainingAttempts--;
    }
    
    return nil;
}

+ (NSMutableDictionary *)defaultValuesForSchema:(RLMObjectSchema *)schema
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    for (RLMProperty *property in schema.properties) {
        defaultValues[property.name] = [self defaultValueForPropertyType:property.type];
    }
    
    return defaultValues;
}

+ (id)defaultValueForPropertyType:(RLMPropertyType)propertyType
{
    switch (propertyType) {
        case RLMPropertyTypeInt:
            return @0;
        
        case RLMPropertyTypeFloat:
            return @(0.0f);

        case RLMPropertyTypeDouble:
            return @0.0;
            
        case RLMPropertyTypeString:
            return @"";
            
        case RLMPropertyTypeBool:
            return @NO;
            
        case RLMPropertyTypeArray:
            return @[];
            
        case RLMPropertyTypeDate:
            return [NSDate date];
            
        case RLMPropertyTypeData:
            return [@"<Data>" dataUsingEncoding:NSUTF8StringEncoding];
            
        case RLMPropertyTypeAny:
            return @"<Any>";
            
        case RLMPropertyTypeObject:
            return [NSNull null];
            
        case RLMPropertyTypeLinkingObjects:
            return [NSNull null];
    }
}

- (RLMPropertyType)propertyTypeForColumn:(NSInteger)column
{
    NSInteger propertyIndex = [self propertyIndexForColumn:column];

    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:self.displayedType.name];
    RLMProperty *property = objectSchema.properties[propertyIndex];
    
    return property.type;
}

- (BOOL)cellsAreNonEmptyInRows:(NSIndexSet *)rowIndexes propertyColumn:(NSInteger)propertyColumn
{
    RLMClassProperty *classProperty = self.displayedType.propertyColumns[propertyColumn];
    
    __block BOOL returnValue = NO;
    
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger rowIndex, BOOL *stop) {
        RLMObject *selectedInstance = [self.displayedType instanceAtIndex:rowIndex];
        id propertyValue = selectedInstance[classProperty.name];
        if (propertyValue) {
            returnValue = YES;
            *stop = YES;
        }
    }];
    
    return returnValue;
}

- (void)removeContentsAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)column
{
    NSInteger propertyIndex = [self propertyIndexForColumn:column];
    
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    RLMClassProperty *classProperty = self.displayedType.propertyColumns[propertyIndex];
    
    id newValue = [NSNull null];
    if (classProperty.property.type == RLMPropertyTypeArray) {
        newValue = @[];
    }
    
    [realm beginWriteTransaction];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger rowIndex, BOOL *stop) {
        RLMObject *selectedInstance = [self.displayedType instanceAtIndex:rowIndex];
        selectedInstance[classProperty.name] = newValue;
    }];
    [realm commitWriteTransaction];
    
    [self.parentWindowController reloadAllWindows];
}

#pragma mark - Rearranging objects in arrays - Private methods

- (void)removeRowsInRealmAt:(NSIndexSet *)rowIndexes
{
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    
    [realm beginWriteTransaction];
    [rowIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger index, BOOL *stop) {
        [(RLMArrayNode *)self.displayedType removeInstanceAtIndex:index];
    }];
    [realm commitWriteTransaction];
}

- (void)deleteRowsInRealmAt:(NSIndexSet *)rowIndexes
{
    [self deleteObjectsInRealmAtIndexes:rowIndexes];
}

- (void)insertNewRowsInRealmAt:(NSIndexSet *)rowIndexes
{
    if (rowIndexes.count == 0) {
        rowIndexes = [NSIndexSet indexSetWithIndex:0];
    }
    
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    
    [realm beginWriteTransaction];
    
    [rowIndexes enumerateRangesWithOptions:NSEnumerationReverse usingBlock:^(NSRange range, BOOL *stop) {
        for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
            RLMObject *object = [self.class createObjectInRealm:realm withSchema:self.displayedType.schema];
            [(RLMArrayNode *)self.displayedType insertInstance:object atIndex:range.location];
        }
    }];
    
    [realm commitWriteTransaction];
}

- (void)moveRowsInRealmFrom:(NSIndexSet *)sourceIndexes to:(NSUInteger)destination
{
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    
    NSMutableArray *sources = [self arrayWithIndexSet:sourceIndexes];
    
    [realm beginWriteTransaction];
    
    // Iterate through the array, representing source row indices
    for (NSUInteger i = 0; i < sources.count; i++) {
        NSUInteger source = [sources[i] unsignedIntegerValue];
        
        [(RLMArrayNode *)self.displayedType moveInstanceFromIndex:source toIndex:destination];
        
        [self updateSourceIndices:sources afterIndex:i withSource:source destination:&destination];
    }
    
    [realm commitWriteTransaction];
}


- (void)deleteObjectsInRealmAtIndexes:(NSIndexSet *)rowIndexes
{
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    
    NSMutableArray *objectsToDelete = [NSMutableArray array];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        [objectsToDelete addObject:[self.displayedType instanceAtIndex:index]];
    }];
    
    [realm beginWriteTransaction];
    [realm deleteObjects:objectsToDelete];
    [realm commitWriteTransaction];
}

-(NSMutableArray *)arrayWithIndexSet:(NSIndexSet *)indexSet
{
    NSMutableArray *sources = [NSMutableArray array];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [sources addObject:@(idx)];
    }];
    
    return sources;
}

-(void)updateSourceIndices:(NSMutableArray *)sources
                afterIndex:(NSUInteger)i
                withSource:(NSUInteger)source
               destination:(NSUInteger *)destination
{
    for (NSUInteger j = i + 1; j < sources.count; j++) {
        NSUInteger sourceIndexToModify = [sources[j] unsignedIntegerValue];
        // Everything right of the destination is shifted right
        if (sourceIndexToModify > *destination) {
            sourceIndexToModify++;
        }
        // Everything right of the current source is shifted left
        if (sourceIndexToModify > source) {
            sourceIndexToModify--;
        }
        sources[j] = @(sourceIndexToModify);
    }
    
    // If the move was from higher index to lower, shift destination right
    if (source > *destination) {
        (*destination)++;
    }
}

#pragma mark - Mouse Handling

- (void)mouseDidEnterCellAtLocation:(RLMTableLocation)location
{
    NSInteger propertyIndex = [self propertyIndexForColumn:location.column];
    
    if (propertyIndex >= self.displayedType.propertyColumns.count || location.row >= self.displayedType.instanceCount) {
        [self disableLinkCursor];
        return;
    }
        
    RLMClassProperty *propertyNode = self.displayedType.propertyColumns[propertyIndex];
        
    RLMObject *selectedInstance = [self.displayedType instanceAtIndex:location.row];
    id propertyValue = selectedInstance[propertyNode.name];

    if (!propertyValue) {
        [self disableLinkCursor];
        return;
    }

    if (propertyNode.type == RLMPropertyTypeObject) {
        [self enableLinkCursor];
    }
    else if (propertyNode.type == RLMPropertyTypeArray) {
        [self enableLinkCursor];
    }
}

- (void)mouseDidExitCellAtLocation:(RLMTableLocation)location
{
    [self disableLinkCursor];
}

- (void)mouseDidExitView:(RLMTableView *)view
{
    [self disableLinkCursor];
}

#pragma mark - Public Methods - NSTableView Event Handling

- (IBAction)editedTextField:(NSTextField *)sender {
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    NSInteger propertyIndex = [self propertyIndexForColumn:column];

    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[propertyIndex];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
    BOOL optionalValue = propertyNode.property.optional;
    
    id result = nil;
    
    switch (propertyNode.type) {
        case RLMPropertyTypeInt:
            numberFormatter.allowsFloats = NO;
            result = [numberFormatter numberFromString:sender.stringValue];
            break;
            
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            numberFormatter.allowsFloats = YES;
            numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            result = [numberFormatter numberFromString:sender.stringValue];
            break;
            
        case RLMPropertyTypeString:
            result = sender.stringValue;
            break;

        case RLMPropertyTypeDate:
            result = [dateFormatter dateFromString:sender.stringValue];
            break;
        
        case RLMPropertyTypeLinkingObjects:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeObject:
            break;
    }
    
    if (result || optionalValue) {
        RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
        [realm beginWriteTransaction];
        selectedInstance[propertyNode.name] = result;
        [realm commitWriteTransaction];
    }
    
    [self.parentWindowController reloadAllWindows];
}

- (IBAction)editedCheckBox:(NSButton *)sender
{
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    NSInteger propertyIndex = [self propertyIndexForColumn:column];

    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[propertyIndex];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];

    NSNumber *result = @((BOOL)(sender.state == NSOnState));

    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    [realm beginWriteTransaction];
    selectedInstance[propertyNode.name] = result;
    [realm commitWriteTransaction];
    
    [self.parentWindowController reloadAllWindows];
}

- (void)optionalBoolPopupChanged:(NSPopUpButton *)sender
{
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    NSInteger propertyIndex = [self propertyIndexForColumn:column];
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[propertyIndex];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
    
    NSNumber *result = nil;
    if (sender.indexOfSelectedItem > 0) {
        result = @((BOOL)(sender.indexOfSelectedItem == 2));
    }
    
    RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
    [realm beginWriteTransaction];
    selectedInstance[propertyNode.name] = result;
    [realm commitWriteTransaction];
    
    [self.parentWindowController reloadAllWindows];
}

- (void)rightClickedLocation:(RLMTableLocation)location
{
    NSUInteger row = location.row;

    if (row >= self.displayedType.instanceCount || RLMTableLocationRowIsUndefined(location)) {
        [self clearSelection];
        return;
    }
    
    if ([self.tableView.selectedRowIndexes containsIndex:row]) {
        return;
    }
    
    [self setSelectionIndex:row];
}

- (void)userClicked:(NSTableView *)sender
{
    if (self.tableView.selectedRowIndexes.count > 1) {
        return;
    }
    
    NSInteger row = self.tableView.clickedRow;
    NSInteger column = self.tableView.clickedColumn;
    NSInteger propertyIndex = [self propertyIndexForColumn:column];
    
    if (row == NOT_A_ROW || propertyIndex < 0) {
        return;
    }
    
    RLMClassProperty *propertyNode = self.displayedType.propertyColumns[propertyIndex];
    
    if (propertyNode.type == RLMPropertyTypeObject) {
        RLMObject *selectedInstance = [self.displayedType instanceAtIndex:row];
        id propertyValue = selectedInstance[propertyNode.name];
        
        if ([propertyValue isKindOfClass:[RLMObject class]]) {
            RLMObject *linkedObject = (RLMObject *)propertyValue;
            RLMObjectSchema *linkedObjectSchema = linkedObject.objectSchema;
            
            for (RLMClassNode *classNode in self.parentWindowController.document.presentedRealm.topLevelClasses) {
                if ([classNode.name isEqualToString:linkedObjectSchema.className]) {
                    RLMResults *allInstances = [linkedObject.realm allObjects:linkedObjectSchema.className];
                    NSUInteger objectIndex = [allInstances indexOfObject:linkedObject];
                    
                    RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:classNode index:objectIndex];
                    [self.parentWindowController addNavigationState:state fromViewController:self];
                    
                    break;
                }
            }
        }
    }
    else if (propertyNode.type == RLMPropertyTypeArray) {
        RLMObject *selectedInstance = [self.displayedType instanceAtIndex:row];
        NSObject *propertyValue = selectedInstance[propertyNode.name];
        
        if ([propertyValue isKindOfClass:[RLMArray class]]) {
            RLMArrayNavigationState *state = [[RLMArrayNavigationState alloc] initWithSelectedType:self.displayedType
                                                                                         typeIndex:row
                                                                                          property:propertyNode.property
                                                                                        arrayIndex:0];
            [self.parentWindowController addNavigationState:state fromViewController:self];
        }
    }
    else {
        [self setSelectionIndex:row];
    }
}

- (void)userDoubleClicked:(NSTableView *)sender {
    NSInteger row = self.tableView.clickedRow;
    NSInteger column = self.tableView.clickedColumn;
    NSInteger propertyIndex = [self propertyIndexForColumn:column];
    
    if (row == NOT_A_ROW || propertyIndex < 0 || self.realmIsLocked) {
        return;
    }
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[propertyIndex];
    RLMObject *selectedObject = [displayedType instanceAtIndex:row];
    id propertyValue = selectedObject[propertyNode.name];
    
    switch (propertyNode.type) {
        case RLMPropertyTypeDate: {
            // Create a menu with a single menu item, and later populate it with the propertyValue
            NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
            
            NSSize intercellSpacing = [self.tableView intercellSpacing];
            NSRect frame = [self.tableView frameOfCellAtColumn:column row:row];
            frame.origin.x -= 0.5*intercellSpacing.width;
            frame.origin.y -= 0.5*intercellSpacing.height;
            frame.size.width += intercellSpacing.width;
            frame.size.height += intercellSpacing.height;
            
            frame.size.height = MAX(23.0, frame.size.height);
            
            // Set up a date picker with no border or background
            NSDatePicker *datepicker = [[NSDatePicker alloc] initWithFrame:frame];
            datepicker.bordered = NO;
            datepicker.drawsBackground = NO;
            datepicker.datePickerStyle = NSTextFieldAndStepperDatePickerStyle;
            datepicker.datePickerElements = NSHourMinuteSecondDatePickerElementFlag
              | NSYearMonthDayDatePickerElementFlag | NSTimeZoneDatePickerElementFlag;
            datepicker.dateValue = propertyValue;
            
            item.view = datepicker;
            [menu addItem:item];
            
            if ([menu popUpMenuPositioningItem:nil atLocation:frame.origin inView:self.tableView]) {
                RLMRealm *realm = self.parentWindowController.document.presentedRealm.realm;
                [realm beginWriteTransaction];
                selectedObject[propertyNode.name] = datepicker.dateValue;
                [realm commitWriteTransaction];
                [self.tableView reloadData];
            }
            break;
        }
            
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeString: {
            // Start editing the textfield
            NSTableCellView *cellView = [self.tableView viewAtColumn:column row:row makeIfNecessary:NO];
            [[cellView.textField window] makeFirstResponder:cellView.textField];
            break;
        }
        case RLMPropertyTypeAny:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeObject:
        case RLMPropertyTypeLinkingObjects:
            // Do nothing
            break;
    }
}

#pragma mark - Public Methods - Table View Construction

- (void)enableLinkCursor
{
    if (linkCursorDisplaying) {
        return;
    }
    NSCursor *currentCursor = [NSCursor currentCursor];
    [currentCursor push];
    
    NSCursor *newCursor = [NSCursor pointingHandCursor];
    [newCursor set];
    
    linkCursorDisplaying = YES;
}

- (void)disableLinkCursor
{
    if (!linkCursorDisplaying) {
        return;
    }
    
    [NSCursor pop];
    linkCursorDisplaying = NO;
}

#pragma mark - Private Methods - Convenience

-(NSInteger)propertyIndexForColumn:(NSInteger)column
{
    return self.displaysArray ? column - 1 : column;
}

@end
