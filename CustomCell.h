//
//  CustomCell.h
//  TRAC
//
//  Created by Griffin Kelly on 12/8/14.
//  Copyright (c) 2014 Griffin Kelly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StopWatchControl.h"

@class CustomCell;

@protocol CustomCellDelegate

@optional

@property (nonatomic, readonly, getter=isPseudoEditing) BOOL pseudoEdit;
- (void)selectCell:(CustomCell *)cell;

@end

@interface CustomCell : UITableViewCell
@property(weak, nonatomic) IBOutlet UILabel *Name;
@property(weak, nonatomic) IBOutlet UILabel *Split;
@property(weak, nonatomic) IBOutlet UILabel *Total;
@property (weak, nonatomic) IBOutlet UIView *customEditControl;
@property (weak, nonatomic) IBOutlet UIView *backgroundcell;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingSpaceMainViewConstraint;

@property (strong, nonatomic) StopWatchControl *sw;
- (void)configureCell;
@property (nonatomic, assign) id <CustomCellDelegate> delegate;
@end
