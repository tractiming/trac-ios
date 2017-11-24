//
//  CustomCell.m
//  TRAC
//
//  Created by Griffin Kelly on 12/8/14.
//  Copyright (c) 2014 Griffin Kelly. All rights reserved.
//

#import "CustomCell.h"

static NSInteger const kCustomEditControlWidth=42;

@interface CustomCell ()

@property (nonatomic, getter=isPseudoEditing) BOOL pseudoEdit;
@property (nonatomic, getter=isDeleting) BOOL deleting;


@end

@implementation CustomCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
        NSLog(@"%hhd",[self.delegate isPseudoEditing]);
    if ([self.delegate isPseudoEditing]) {
        self.pseudoEdit = editing;
        [self beginEditMode];
        [self.sw startWatch];
    } else {
        [super setEditing:editing animated:animated];
        [self beginEditMode];
        [self.sw stopWatch];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected)
        [self.sw stopWatch];
    else
        [self.sw startWatch];
    [self.sw setHighlighted:selected];
    //self.customEditControl.selected = selected;
}

#pragma mark - Public API
- (void)configureCell {
    CGFloat swDim = CGRectGetHeight(self.frame) - 16;
    self.sw = [[StopWatchControl alloc] initWithFrame:CGRectMake(8, 8, swDim, swDim)];
    [self.customEditControl addSubview:self.sw];
}

#pragma mark - Cell custom edit control Action

- (IBAction)customEditControlPressed:(id)sender {
    // [self setSelected:YES animated:YES];
    [self.delegate selectCell:self];
}


#pragma mark - Private Method

// Animate view to show/hide custom edit control/button
- (void)beginEditMode {
    //NSLog(@"%hhd",self.pseudoEdit);
    self.leadingSpaceMainViewConstraint.constant = [self.delegate isPseudoEditing] ? 0 : -42;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.superview layoutIfNeeded];
    }];
}

@end
