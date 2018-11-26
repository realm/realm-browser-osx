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

@interface RLMNumberTextField : NSTextField

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

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
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.numberFormatter.maximumFractionDigits = UINT16_MAX;
    
    self.formatter = self.numberFormatter;
}

-(BOOL)becomeFirstResponder {
    self.numberFormatter.hasThousandSeparators = NO;
    
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    self.numberFormatter.hasThousandSeparators = YES;
    
    return [super resignFirstResponder];
}

@end

@implementation RLMNumberTableCellView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self == nil) {
        return nil;
    }
    
    RLMNumberTextField *textField = [[RLMNumberTextField alloc] initWithFrame:self.bounds];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.bordered = NO;
    textField.drawsBackground = NO;
    textField.alignment = NSRightTextAlignment;
    textField.cell.sendsActionOnEndEditing = YES;
    
    if ([NSFont respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)]) {
        textField.font = [NSFont monospacedDigitSystemFontOfSize:12.0 weight:NSFontWeightRegular];
    }

    if ([textField respondsToSelector:@selector(setUsesSingleLineMode:)]) {
        textField.usesSingleLineMode = YES;
    }
    
    if ([textField respondsToSelector:@selector(setLineBreakMode:)]) {
        textField.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    
    self.textField = textField;
    [self addSubview:textField];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.textField
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.textField
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1.0
                                                      constant:0.0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.textField
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.textField
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    return self;
}

@end

