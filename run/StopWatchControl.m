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
@property (nonatomic, strong) UIView *centerCircle;
@property (nonatomic, strong) UIView *watchFace;
@property (nonatomic, strong) UIView *topButton;
@property (nonatomic, strong) UIView *sideButton;
@property (nonatomic, assign) NSInteger rotationInterval;

@end

@implementation StopWatchControl

#pragma mark Rendering

CGAffineTransform CGAffineTransformMakeRotationAt(CGFloat angle, CGPoint pt){
    const CGFloat fx = pt.x, fy = pt.y, fcos = cos(angle), fsin = sin(angle);
    return CGAffineTransformMake(fcos, fsin, -fsin, fcos, fx - fx * fcos + fy * fsin, fy - fx * fsin - fy * fcos);
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        
        UIColor *watchColor = [UIColor grayColor];
        UIColor *handColor = [UIColor whiteColor];
        UIColor *buttonColor = watchColor;
        self.rotationInterval = 5;
        _animating = NO;
        
        // Draw watchface
        CGFloat squareDim = (CGRectGetWidth(frame) <= CGRectGetHeight(frame)) ? CGRectGetWidth(frame) : CGRectGetHeight(frame);
        CGFloat scaleFactor = 0.10;
        CGFloat diameter = squareDim*(1-scaleFactor);
        CGFloat radius = diameter/2.0;
        CGFloat handWidth = ceilf(diameter/25.0);
        if (handWidth > 5.0) {
            handWidth = 5.0;
        }
        
        CGRect squareFrame = CGRectMake(0, squareDim*scaleFactor, diameter, diameter);
        
        self.watchFace = [[UIView alloc] initWithFrame:squareFrame];
        [self.watchFace.layer setCornerRadius:radius];
        [self.watchFace.layer setBorderWidth:handWidth];
        [self addSubview:self.watchFace];
        
        
        CGFloat centerCircleDiameter = diameter/5.0;
        CGFloat centerCircleRadius = centerCircleDiameter/2.0;
        self.centerCircle = [[UIView alloc] initWithFrame:CGRectMake(radius - centerCircleRadius, radius - centerCircleRadius+squareDim*scaleFactor, centerCircleDiameter, centerCircleDiameter)];
        [self.centerCircle.layer setCornerRadius:centerCircleRadius];
        [self addSubview:self.centerCircle];
        
        // Draw Hand
        CGRect handRect = CGRectMake(radius - handWidth/2.0, squareDim*scaleFactor, handWidth, radius);
        
        self.hand = [[UIView alloc] initWithFrame:handRect];
        [self setAnchorPoint:CGPointMake(0.5, 1.0) forView:self.hand];
        [self addSubview:self.hand];
        
        // Draw buttons
        CGFloat buttonHeight = squareDim*scaleFactor;
        CGFloat buttonWidth = buttonHeight*2;
        
        self.topButton = [[UIView alloc] initWithFrame:CGRectMake(radius-(buttonWidth/2), 0, buttonWidth, buttonHeight)];
        
        [self addSubview:self.topButton];
        
        self.sideButton = [[UIView alloc] initWithFrame:self.topButton.frame];
        self.sideButton.transform = CGAffineTransformMakeRotationAt(DEGREES_TO_RADIANS(45), CGPointMake(0, radius));
        [self addSubview:self.sideButton];
        
        [self setUnselectedColors];
        
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

- (void)setSelectedColors {
    UIColor *watchColor = [UIColor grayColor];
    UIColor *handColor = [UIColor whiteColor];
    UIColor *buttonColor = watchColor;
    
    [self.watchFace setBackgroundColor:watchColor];
    //[self.watchFace.layer setBorderColor:[handColor CGColor]];
    
    [self.centerCircle setBackgroundColor:handColor];
    
    [self.hand setBackgroundColor:handColor];
    
    [self.topButton setBackgroundColor:buttonColor];
    
    [self.sideButton setBackgroundColor:buttonColor];
    
}

- (void)setUnselectedColors {
    UIColor *watchColor = [UIColor whiteColor];
    UIColor *handColor = [UIColor grayColor];
    UIColor *buttonColor = handColor;
    
    [self.watchFace setBackgroundColor:watchColor];
    [self.watchFace.layer setBorderColor:[handColor CGColor]];
    
    [self.centerCircle setBackgroundColor:handColor];
    
    [self.hand setBackgroundColor:handColor];
    
    [self.topButton setBackgroundColor:buttonColor];
    
    [self.sideButton setBackgroundColor:buttonColor];
    
}


#pragma mark Hand rotation animation

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

#pragma mark Control methods

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

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        [self setSelectedColors];
    }
    else {
        [self setUnselectedColors];
    }
}


@end
