//
//  RLMTableViewController.m
//  RealmBrowser
//
//  Created by Matt Bauer on 10/27/15.
//  Copyright © 2015 Realm inc. All rights reserved.
//

#import "RLMTableViewController.h"
#import "RLMBadgeTableCellView.h"
#import "RLMBasicTableCellView.h"
#import "RLMBoolTableCellView.h"
#import "RLMNumberTableCellView.h"
#import "RLMImageTableCellView.h"
#import "RLMTableRowView.h"

@import Realm.Dynamic;

@interface RLMTableViewController ()

@end

@implementation RLMTableViewController

- (void)setDocument:(RLMDocument *)document
{
    [self willChangeValueForKey:@"document"];
    _document = document;
    [self didChangeValueForKey:@"document"];
}

- (void)setObjectSchema:(RLMObjectSchema *)objectSchema
{
    [self willChangeValueForKey:@"objectSchema"];
    _objectSchema = objectSchema;
    [self didChangeValueForKey:@"objectSchema"];

    for (RLMObject *o in [self.document.realm allObjects:[_objectSchema className]]) {
        [(NSArrayController *)self.arrayController addObject:o];
    }

    [self.tableView beginUpdates];
 
    [self.tableView removeTableColumn:[self.tableView.tableColumns lastObject]];

    for (RLMProperty * property in _objectSchema.properties) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:property.name];
        tableColumn.title = property.name;
        [tableColumn setResizingMask:NSTableColumnAutoresizingMask|NSTableColumnUserResizingMask];
        [tableColumn bind:NSValueBinding toObject:self.arrayController withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", property.name] options:nil];
        [self.tableView addTableColumn:tableColumn];
    }
    
    [self.tableView endUpdates];
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    RLMTableRowView *rowView = [tableView makeViewWithIdentifier:@"rlmrow" owner:self];
    
    if (!rowView) {
        rowView = [[RLMTableRowView alloc] initWithFrame:NSZeroRect];
        rowView.identifier = @"rlmrow";
//        rowView.canDrawSubviewsIntoLayer = YES;
    }

    return rowView;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    RLMProperty * property = [self.document.selectedObjectSchema objectForKeyedSubscript:tableColumn.identifier];
    
    switch (property.type) {
        case RLMPropertyTypeInt: {
            RLMNumberTableCellView *view = [tableView makeViewWithIdentifier:@"NumberCell" owner:self];
            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }

        case RLMPropertyTypeBool: {
            RLMBoolTableCellView *view = [tableView makeViewWithIdentifier:@"BoolCell" owner:self];
            [view.checkBox bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }

        case RLMPropertyTypeFloat: {
            RLMNumberTableCellView *view = [tableView makeViewWithIdentifier:@"NumberCell" owner:self];
            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }

        case RLMPropertyTypeDouble: {
            RLMNumberTableCellView *view = [tableView makeViewWithIdentifier:@"NumberCell" owner:self];
            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }

        case RLMPropertyTypeString: {
            RLMBasicTableCellView *view = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }

        case RLMPropertyTypeData: {
            RLMBasicTableCellView *view = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }

        case RLMPropertyTypeAny: {
            RLMBasicTableCellView *view = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }

        case RLMPropertyTypeDate: {
            RLMBasicTableCellView *view = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }

        case RLMPropertyTypeObject: {
            RLMLinkTableCellView *view = [tableView makeViewWithIdentifier:@"LinkCell" owner:self];
//            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }
            
        case RLMPropertyTypeArray: {
            RLMBadgeTableCellView *view = [tableView makeViewWithIdentifier:@"BadgeCell" owner:self];
//            [view.textField bind:NSValueBinding toObject:view withKeyPath:[NSString stringWithFormat:@"objectValue.%@", tableColumn.identifier] options:nil];
            return view;
        }
            
        default:
            break;
    }

    return nil;
}

@end
