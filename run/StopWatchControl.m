//
//  StopWatchControl.m
//  stopwatch_control
//
//  Created by Jack Miller on 5/23/16.
//  Copyright © 2016 Jack Miller. All rights reserved.
//

#import "StopWatchControl.h"
#import <QuartzCore/QuartzCore.h>

#define DEGREES_TO_RADIANS(degrees) ((M_PI* (degrees))/180)

@interface StopWatchControl ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIView *hand;
@property (nonatomic, assign) NSInteger rotationInterval;

@end

@implementation StopWatchControl

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        
        UIColor *watchColor = [UIColor whiteColor];
        UIColor *handColor = [UIColor grayColor];
        self.rotationInterval = 5;
        _animating = NO;
        
        // Draw watchface
        CGFloat diameter = (CGRectGetWidth(frame) <= CGRectGetHeight(frame)) ? CGRectGetWidth(frame) : CGRectGetHeight(frame);
        CGFloat radius = diameter/2.0;
        CGRect squareFrame = CGRectMake(0, 0, diameter, diameter);
        
        UIView *watchFace = [[UIView alloc] initWithFrame:squareFrame];
        [watchFace.layer setCornerRadius:radius];
        [watchFace setBackgroundColor:watchColor];
        [watchFace.layer setBorderColor:[handColor CGColor]];
        [watchFace.layer setBorderWidth:2.0];
        
        [self addSubview:watchFace];
        
        
        CGFloat centerCircleDiameter = diameter/5.0;
        CGFloat centerCircleRadius = centerCircleDiameter/2.0;
        UIView *centerCircle = [[UIView alloc] initWithFrame:CGRectMake(radius - centerCircleRadius, radius - centerCircleRadius, centerCircleDiameter, centerCircleDiameter)];
        [centerCircle.layer setCornerRadius:centerCircleRadius];
        [centerCircle setBackgroundColor:handColor];
        [self addSubview:centerCircle];
        
        // Draw Hand
        CGFloat handWidth = ceilf(diameter/25.0);
        CGRect handRect = CGRectMake(radius - handWidth/2.0, 0.0, handWidth, radius);
        
        self.hand = [[UIView alloc] initWithFrame:handRect];
        [self setAnchorPoint:CGPointMake(0.5, 1.0) forView:self.hand];
        [self.hand setBackgroundColor:handColor];
        [self addSubview:self.hand];
    }
    
    return self;
}

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}


- (void)startWatch {
    if (!self.animating) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.rotationInterval target:self selector:@selector(updateWatch:) userInfo:NULL repeats:YES];
        // Adds timer to the same runloop as scrolling so it continues to fire while scrolling in a table
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self.timer fire];
        _animating = YES;
    }
    
}

- (void)stopWatch {
    if (self.animating) {
        [self.timer invalidate];
        self.timer = nil;
        [self.hand.layer removeAllAnimations];
        self.hand.transform = CGAffineTransformMakeRotation([self millsecondHandAngleFromTime:CACurrentMediaTime()]);
        _animating = NO;
    }
}

- (CGFloat)millsecondHandAngleFromTime:(CGFloat)currentTime {
    CGFloat sliceSize = ((2.0*M_PI)/self.rotationInterval);
    NSInteger slice = ((int)floorf(currentTime)%self.rotationInterval);
    CGFloat sliceAngle = slice * sliceSize;
    CGFloat millisecondFrac = currentTime - floorf(currentTime);
    CGFloat milliAngle = millisecondFrac * sliceSize;
    return sliceAngle + milliAngle;
}

- (void)updateWatch:(NSTimer *)timer {
    CGFloat milliSecAngle = [self millsecondHandAngleFromTime:CACurrentMediaTime()];
    self.hand.transform = CGAffineTransformMakeRotation(milliSecAngle);
    
    CABasicAnimation *fullRotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    fullRotation.fromValue = [NSNumber numberWithFloat:milliSecAngle];
    fullRotation.byValue = [NSNumber numberWithFloat:M_PI*2.0];
    fullRotation.duration = self.rotationInterval;
    [self.hand.layer addAnimation:fullRotation forKey:@"360 rotation"];
}




@end
