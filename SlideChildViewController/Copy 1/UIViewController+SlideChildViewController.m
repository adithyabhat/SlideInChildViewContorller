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
static const CGFloat kFullSlideAnimataionDuration = 0.30f;
static const CGFloat kMaxFrontBounceDistance = 40.0f;
static const CGFloat kMaxBackBounceDistance = -10.0f;

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

- (UIView*)overlayView
{
    return objc_getAssociatedObject(self, &kOverlayViewIdentifier);
}

- (void)setOverlayView:(UIView *)view
{
    objc_setAssociatedObject(self, &kOverlayViewIdentifier, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Helper functions

CGFloat distanceBetweenCentersOfParentAndChildController (UIViewController* parent, UIViewController* child)
{
    return parent.view.center.x - child.view.center.x;
}

- (CGFloat)animationDurationForChildViewController:(UIViewController*)childVC
{
    CGFloat duration = 0.0f;
    if (childVC.view.center.x < self.view.center.x)
    {
        CGFloat distanceBetweenCenters = distanceBetweenCentersOfParentAndChildController(self, childVC);
        duration = (kFullSlideAnimataionDuration * CGRectGetWidth(childVC.view.bounds))/distanceBetweenCenters; //cross multi
    }
    return duration;
}

NSArray* bounceValuesForAnimationDuration (CGFloat animationDuration)
{
    CGFloat forwardBounceValue = kMaxFrontBounceDistance * animationDuration / kFullSlideAnimataionDuration;    //cross multi
    CGFloat backwardBounceValue = kMaxBackBounceDistance * animationDuration / kFullSlideAnimataionDuration;    //cross multi

    return @[
                [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 1.0f)],
                [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(forwardBounceValue, 0.0f, 1.0f)],
                [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(backwardBounceValue, 0.0f, 1.0f)],
                [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 1.0f)]
            ];
}

#pragma mark - Private functions

- (void)prepareForAnimationOfChildViewController:(UIViewController*)childViewController
{
    UIView *childViewControllerView = childViewController.view;
    
    CGRect overlayViewFrame = {{0,0},self.view.frame.size};
    self.overlayView = [[UIView alloc] initWithFrame:overlayViewFrame];
    self.overlayView.backgroundColor = [UIColor blackColor];
    self.overlayView.alpha = 0;
    [self.view addSubview:self.overlayView];
    
    [self.view addSubview:childViewControllerView];
    CGPoint viewCenter = childViewControllerView.center;
    viewCenter.x = -CGRectGetWidth(childViewControllerView.bounds)/2;
    childViewControllerView.center = viewCenter;
}

- (void)performBounceAnimationWithAnimationDuration:(CGFloat)animationDuration onController:(UIViewController*)controller
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    bounceAnimation.fillMode = kCAFillModeBoth;
    bounceAnimation.values = bounceValuesForAnimationDuration(animationDuration);
    bounceAnimation.duration = animationDuration;
    bounceAnimation.keyTimes = @[@0.0f, @0.25f, @0.70f, @1.0f];
    bounceAnimation.timingFunctions = @[
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    bounceAnimation.removedOnCompletion = NO;
    [controller.view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (void)reinitializeConfigurationsForParentViewController:(UIViewController*)parentViewController
{
    parentViewController.overlayView = nil;
    [parentViewController.overlayView removeFromSuperview];
    parentViewController.isChildViewVisible = NO;
}

#pragma mark - Public functions

- (void)slideInChildViewController:(UIViewController*)childViewController
                     fromDirection:(SlideDirection)slideDirection
{
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;

    if (self.isChildViewVisible == NO)
    {
        [self prepareForAnimationOfChildViewController:childViewController];
    }

    CGPoint centerToMoveTo = self.view.center;
    centerToMoveTo.y -= statusBarHeight;
    CGFloat animationDuration = [self animationDurationForChildViewController:childViewController];

    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.overlayView.alpha = 0.4f;
        childViewController.view.center = centerToMoveTo;
    } completion:^(BOOL finished) {
        [self performBounceAnimationWithAnimationDuration:animationDuration
                                             onController:childViewController];
        self.isChildViewVisible = YES;
    }];
}

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
        [self removeFromParentViewController];
    }];
}

@end
