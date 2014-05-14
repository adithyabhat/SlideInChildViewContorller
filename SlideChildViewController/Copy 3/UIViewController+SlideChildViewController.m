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

//static const CGFloat kFullSlideAnimataionDuration = 0.30f;
static const CGFloat kFullSlideAnimataionDuration = 0.75f;
static const CGFloat kMaxFrontBounceDistance = 40.0f;
static const CGFloat kMaxBackBounceDistance = -10.0f;
static const CGFloat kMaxOverlayViewAlpha = 0.4f;

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

- (CGFloat)animationDuration
{
    CGFloat duration = 0.0f;
    if (centerXValue(self.childViewController) < centerXValue(self))
    {
        CGFloat distanceBetweenCenters = distanceBetweenCentersOfParentAndChildController(self, self.childViewController);
        duration = (kFullSlideAnimataionDuration * distanceBetweenCenters)/CGRectGetWidth(self.childViewController.view.bounds); //cross multi
    }
    return duration;
}

//NSArray* bounceValuesForAnimationDuration (CGFloat animationDuration)
//{
//    CGFloat forwardBounceValue = kMaxFrontBounceDistance * animationDuration / kFullSlideAnimataionDuration;    //cross multi
//    CGFloat backwardBounceValue = kMaxBackBounceDistance * animationDuration / kFullSlideAnimataionDuration;    //cross multi
//
//    return @[
//                [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 1.0f)],
//                [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(forwardBounceValue, 0.0f, 1.0f)],
//                [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(backwardBounceValue, 0.0f, 1.0f)],
//                [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 1.0f)]
//            ];
//}

NSArray* bounceAnimationValues (UIViewController* parent, UIViewController *child)
{
    CGFloat maxDistanceBetweenCenters = CGRectGetWidth(parent.view.bounds)/2 + CGRectGetWidth(child.view.bounds)/2;   //Max distance  between center of the parent and child view controller
    CGFloat currentDistaceBetweenCenters = centerXValue(parent) - centerXValue(child);
    CGFloat forwardBounceValue = kMaxFrontBounceDistance;
    CGFloat backwardBounceValue = kMaxBackBounceDistance;
    
    if (currentDistaceBetweenCenters != 0)
    {
        forwardBounceValue = kMaxFrontBounceDistance * currentDistaceBetweenCenters / maxDistanceBetweenCenters;    //cross multi
        backwardBounceValue = kMaxBackBounceDistance * currentDistaceBetweenCenters / maxDistanceBetweenCenters;    //cross multi
    }
    return @[
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(currentDistaceBetweenCenters + forwardBounceValue, 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(maxDistanceBetweenCenters + backwardBounceValue, 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(maxDistanceBetweenCenters, 0.0f, 1.0f)]
    ];
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

//- (void)performBounceAnimationWithAnimationDuration:(CGFloat)animationDuration onController:(UIViewController*)controller
//{
//    CAKeyframeAnimation *slideAnimationWithBounce = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
//    slideAnimationWithBounce.fillMode = kCAFillModeBoth;
//    slideAnimationWithBounce.values = bounceAnimationValues(self, controller);
//    slideAnimationWithBounce.duration = animationDuration;
//    slideAnimationWithBounce.keyTimes = @[@0.0f, @0.25f, @0.70f, @1.0f];
//    slideAnimationWithBounce.timingFunctions = @[
//        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
//        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
//        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]
//    ];
//    slideAnimationWithBounce.removedOnCompletion = NO;
//    [controller.view.layer addAnimation:slideAnimationWithBounce forKey:@"slideWithBounce"];
//}

- (void)performBounceAnimationWithAnimationDuration:(CGFloat)animationDuration
{
    CAKeyframeAnimation *slideAnimationWithBounce = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    slideAnimationWithBounce.fillMode = kCAFillModeBoth;
    slideAnimationWithBounce.values = bounceAnimationValues(self, self.childViewController);
    slideAnimationWithBounce.duration = animationDuration;
    slideAnimationWithBounce.keyTimes = @[@0.0f, @0.60f, @0.90f, @1.0f];
    slideAnimationWithBounce.timingFunctions = @[
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
        //    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        //        self.overlayView.alpha = kMaxOverlayViewAlpha;
        //        childViewController.view.center = centerToMoveTo;
        //    } completion:^(BOOL finished) {
        //        [self performBounceAnimationWithAnimationDuration:animationDuration
        //                                             onController:childViewController];
        //        self.isChildViewVisible = YES;
        //    }];
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

- (void)translateChildViewController:(UIViewController*)childViewController byValue:(CGFloat)value
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

@end
