//
//  StopWatchControl.h
//  stopwatch_control
//
//  Created by Jack Miller on 5/23/16.
//  Copyright © 2016 Jack Miller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StopWatchControl : UIControl

- (void)startWatch;
- (void)stopWatch;

@property (nonatomic, assign, readonly) BOOL animating;

@end
