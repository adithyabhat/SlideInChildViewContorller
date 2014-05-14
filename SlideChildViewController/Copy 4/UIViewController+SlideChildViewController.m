//
//  UIViewController+SlideChildViewController.m
//  SlidePresentVC
//
//  Created by Adithya H on 06/02/13.
//  Copyright (c) 2013 Robosoft Technologies. All rights reserved.
//

#import "UIViewController+SlideChildViewController.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char kIsChildViewVisible;
static char kOverlayViewIdentifier;
static char kChildViewController;
static char kSlideDirection;

//static const CGFloat kFullSlideAnimataionDuration = 0.30f;
static const CGFloat kMaxAnimataionDuration = 0.75f;
static const CGFloat kMinAnimataionDuration = 0.65f;
static const CGFloat kMaxFrontBounceDistance = 40.0f;
static const CGFloat kMaxBackBounceDistance = -10.0f;
static const CGFloat kMaxOverlayViewAlpha = 0.4f;
static const CGFloat kReductionRate = 0.05;   //This value is used in the exponential reduction function.

@implementation UIViewController (SlideChildViewController)

#pragma mark - Associative Referencing

- (BOOL)isChildViewVisible
{
    return [objc_getAssociatedObject(self, &kIsChildViewVisible) boolValue];
}

- (void)setIsChildViewVisible:(BOOL)value
{
    objc_setAssociatedObject(self,
                             &kIsChildViewVisible,
                             [NSNumber numberWithBool:value],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SlideDirection)slideDirection
{
    return [objc_getAssociatedObject(self, &kSlideDirection) integerValue];
}

- (void)setSlideDirection:(SlideDirection)value
{
    objc_setAssociatedObject(self,
                             &kSlideDirection,
                             [NSNumber numberWithInteger:value],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView*)overlayView
{
    return objc_getAssociatedObject(self, &kOverlayViewIdentifier);
}

- (void)setOverlayView:(UIView *)view
{
    objc_setAssociatedObject(self, &kOverlayViewIdentifier, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController*)childViewController
{
    return objc_getAssociatedObject(self, &kChildViewController);
}

- (void)setChildViewController:(UIViewController *)viewController
{
    objc_setAssociatedObject(self, &kChildViewController, viewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Helper functions

CGFloat centerXValue (UIViewController* controller)
{
    return controller.view.center.x;
}

CGFloat distanceBetweenCentersOfParentAndChildController (UIViewController* parent, UIViewController* child)
{
    return centerXValue(parent) - centerXValue(child);
}

BOOL translateReachedLimit (UIViewController *parent, UIViewController *child, SlideDirection slideDirection)
{
    CGFloat centerDifference = centerXValue(parent) - centerXValue(child);
    if (centerDifference < -10)
        return YES;
    else return NO;
}

NSArray* bounceAnimationValues (UIViewController* parent, UIViewController *child, SlideDirection slideDirection)
{
    CGFloat maxDistanceBetweenCenters = CGRectGetWidth(parent.view.bounds)/2 + CGRectGetWidth(child.view.bounds)/2;   //Max distance  between center of the parent and child view controller
    CGFloat distaceBetweenCenters = fabs(centerXValue(parent) - centerXValue(child));
    CGFloat forwardBounceValue = kMaxFrontBounceDistance;
    CGFloat backwardBounceValue = kMaxBackBounceDistance;
    
    if (distaceBetweenCenters != 0)
    {
        forwardBounceValue = kMaxFrontBounceDistance * distaceBetweenCenters / maxDistanceBetweenCenters;    //cross multi
        backwardBounceValue = kMaxBackBounceDistance * distaceBetweenCenters / maxDistanceBetweenCenters;    //cross multi
    }
    return @[
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(distaceBetweenCenters + (forwardBounceValue * slideDirection), 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(distaceBetweenCenters + (backwardBounceValue * slideDirection), 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(distaceBetweenCenters, 0.0f, 1.0f)]
    ];
}

- (CGFloat)animationDuration
{
    CGFloat duration = 0.0f;
    if (centerXValue(self.childViewController) < centerXValue(self))
    {
        CGFloat distanceBetweenCenters = distanceBetweenCentersOfParentAndChildController(self, self.childViewController);
        duration = MAX((kMaxAnimataionDuration * distanceBetweenCenters)/CGRectGetWidth(self.childViewController.view.bounds), kMinAnimataionDuration); //cross multi
    }
    return duration;
}

- (void)setOverlayViewAlphaForUpdatedPositionOfChildController
{
    CGFloat centerX = centerXValue(self.childViewController);
    CGFloat maxDistanceBetweenCenters = CGRectGetWidth(self.view.bounds)/2 + CGRectGetWidth(self.childViewController.view.bounds)/2;   //Max distance  between center of the parent and child view controller
    CGFloat alphaPerDistance = kMaxOverlayViewAlpha/maxDistanceBetweenCenters;
    CGFloat distanceCovered = (centerX + CGRectGetWidth(self.childViewController.view.bounds)/2);
    self.overlayView.alpha =  distanceCovered * alphaPerDistance;
}

#pragma mark - Private functions

- (void)prepareForAnimation
{
    UIView *childViewControllerView = self.childViewController.view;
    
    CGRect overlayViewFrame = {{0,0},self.view.frame.size};
    self.overlayView = [[UIView alloc] initWithFrame:overlayViewFrame];
    self.overlayView.backgroundColor = [UIColor blackColor];
    self.overlayView.alpha = 0;
    [self.view addSubview:self.overlayView];
    
    [self.view addSubview:childViewControllerView];
    CGPoint viewCenter = childViewControllerView.center;
    viewCenter.x = -CGRectGetWidth(childViewControllerView.bounds)/2;
    childViewControllerView.center = viewCenter;
    
    self.isChildViewVisible = YES;
}

- (void)performBounceAnimationWithAnimationDuration:(CGFloat)animationDuration
{
    CAKeyframeAnimation *slideAnimationWithBounce = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    slideAnimationWithBounce.fillMode = kCAFillModeBoth;
    slideAnimationWithBounce.values = bounceAnimationValues(self, self.childViewController, self.slideDirection);
    slideAnimationWithBounce.duration = animationDuration;
    slideAnimationWithBounce.keyTimes = @[@0.0f, @0.60f, @0.90f, @1.0f];
    slideAnimationWithBounce.timingFunctions =
    @[
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]
    ];
    slideAnimationWithBounce.removedOnCompletion = NO;
    [self.childViewController.view.layer addAnimation:slideAnimationWithBounce forKey:@"slideWithBounce"];
}

- (void)reinitializeConfigurationsForParentViewController:(UIViewController*)parentViewController
{
    parentViewController.overlayView = nil;
    [parentViewController.overlayView removeFromSuperview];
    parentViewController.isChildViewVisible = NO;
    parentViewController.childViewController = nil;
}

#pragma mark - Public functions
#pragma mark Called from Parent

- (void)slideInChildViewController:(UIViewController*)childViewController
                     fromDirection:(SlideDirection)slideDirection
{
    if (childViewController != nil)
    {
        self.childViewController = childViewController;
        if (self.isChildViewVisible == NO)
        {
            [self prepareForAnimation];
        }
        CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        CGPoint centerToMoveTo = self.view.center;
        centerToMoveTo.y -= statusBarHeight;
        
        CGFloat animationDuration = [self animationDuration];

        [UIView animateWithDuration:animationDuration animations:^{
            self.overlayView.alpha = kMaxOverlayViewAlpha;
            [self performBounceAnimationWithAnimationDuration:animationDuration];
        } completion:^(BOOL finished) {
            self.childViewController.view.center = centerToMoveTo;
            [self.childViewController.view.layer removeAllAnimations];
        }];
    }
}

- (void)translateInChildViewController:(UIViewController*)childViewController byValue:(CGFloat)value
{
   if (childViewController != nil)
   {
       self.childViewController = childViewController;
       if (self.isChildViewVisible == NO)
       {
           [self prepareForAnimation];
       }
       
       CGPoint viewCenter = childViewController.view.center;
       viewCenter.x += value;
       childViewController.view.center = viewCenter;
       
       [self setOverlayViewAlphaForUpdatedPositionOfChildController];
   }
}

#pragma mark Called from Child

- (void)slideOutFromParentController:(UIViewController*)parentViewController
                         toDirection:(SlideDirection)slideDirection
{
    CGPoint centerToMoveTo = CGPointMake(-CGRectGetWidth(self.view.bounds), self.view.center.y);
    [UIView animateWithDuration:0.3f animations:^{
        parentViewController.overlayView.alpha = 0;
        self.view.center = centerToMoveTo;
    } completion:^(BOOL finished) {
        [self reinitializeConfigurationsForParentViewController:parentViewController];
        [self.view removeFromSuperview];
    }];
}

- (void)translateOutFromParentViewController:(UIViewController*)parentViewController byValue:(CGFloat)value
{
    CGPoint viewCenter = self.view.center;
    if (YES == translateReachedLimit(parentViewController, self, SlideDirectionFromLeft))
    {
        CGFloat centerDifference = fabs(centerXValue(parentViewController) - centerXValue(self));
        CGFloat valueReduceFactor = pow((1-kReductionRate), centerDifference);    //Exponential decrement
        NSLog(@"%f",valueReduceFactor);
        value *= valueReduceFactor;
        viewCenter.x += value;
    }
    viewCenter.x += value;
    self.view.center = viewCenter;
    [parentViewController setOverlayViewAlphaForUpdatedPositionOfChildController];
}

@end
