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

#import "RLMNumberTableCellView.h"

@interface RLMNumberTextField()

@property (nonatomic) NSNumberFormatter *numberFormatter;

@end


@implementation RLMNumberTextField

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setupNumberFormatter];
    }
    
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setupNumberFormatter];
    }
    
    return self;
}

- (void)setupNumberFormatter {
    [super awakeFromNib];
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.hasThousandSeparators = NO;
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.numberFormatter.maximumFractionDigits = UINT16_MAX;
}

-(BOOL)becomeFirstResponder {
    if (self.number) {
        self.stringValue = [self.numberFormatter stringFromNumber:self.number];
    }
    else {
        self.stringValue = @"";
    }
    
    return [super becomeFirstResponder];
}

@end


@implementation RLMNumberTableCellView

+ (instancetype)makeWithIdentifier:(NSString *)identifier {
    RLMNumberTableCellView *cellView = [[RLMNumberTableCellView alloc] initWithFrame:NSZeroRect];
    cellView.identifier = identifier;
    RLMNumberTextField *textField = [[RLMNumberTextField alloc] initWithFrame:[cellView frame]];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setAlignment:NSRightTextAlignment];
    cellView.textField = textField;
    [cellView addSubview:textField];
    
    [textField setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSDictionary *views = NSDictionaryOfVariableBindings(textField);
    
    [cellView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textField]|" options:0 metrics:nil views:views]];
    [cellView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textField]|" options:0 metrics:nil views:views]];
    
    return cellView;
}

@end

