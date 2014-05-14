//
//  UIViewController+SlideChildViewController.m
//  SlidePresentVC
//
//  Created by Adithya H on 06/02/13.
//

#import "UIViewController+SlideChildViewController.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char kIsParentConfiguredForAnimation;
static char kOverlayViewIdentifier;
static char kChildViewController;
static char kSlideDirection;
static char kIsChildViewDisplayed;

static const CGFloat kReductionRate = 0.05;             //This value is used in the exponential reduction function.
static const CGFloat kMaxOverlayViewAlpha = 0.5f;
static const CGFloat kMaxAnimataionDuration = 0.70f;
static const CGFloat kMinAnimataionDuration = 0.50f;
static const CGFloat kMaxFrontBounceDistance = 40.0f;
static const CGFloat kMaxBackBounceDistance = -10.0f;

@implementation UIViewController (SlideChildViewController)

#pragma mark - Associative Referencing

//isParentConfiguredForAnimation
- (BOOL)isParentConfiguredForAnimation
{
    return [objc_getAssociatedObject(self, &kIsParentConfiguredForAnimation) boolValue];
}

- (void)setIsParentConfiguredForAnimation:(BOOL)value
{
    objc_setAssociatedObject(self,
                             &kIsParentConfiguredForAnimation,
                             [NSNumber numberWithBool:value],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


//isChildViewDisplayed
- (BOOL)isChildViewDisplayed
{
    return [objc_getAssociatedObject(self, &kIsChildViewDisplayed) boolValue];
}

- (void)setIsChildViewDisplayed:(BOOL)value
{
    objc_setAssociatedObject(self,
                             &kIsChildViewDisplayed,
                             [NSNumber numberWithBool:value],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


//slideDirection
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


//overlayView
- (UIView*)overlayView
{
    return objc_getAssociatedObject(self, &kOverlayViewIdentifier);
}

- (void)setOverlayView:(UIView *)view
{
    objc_setAssociatedObject(self, &kOverlayViewIdentifier, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


//childViewController
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
    return fabs(centerXValue(parent) - centerXValue(child));
}

BOOL translateReachedLimit (UIViewController *parent, UIViewController *child, SlideDirection slideDirection)
{
    CGFloat centerDifference = centerXValue(parent) - centerXValue(child);
    BOOL returnVal = (slideDirection == SlideDirectionFromLeft && centerDifference < -10) ||
                     (slideDirection == SlideDirectionFromRight && centerDifference > 10);  //translate limit set to 10.
    return returnVal;
}

NSArray* bounceAnimationValues (UIViewController* parent, UIViewController *child, SlideDirection slideDirection)
{
    CGFloat maxDistanceBetweenCenters = CGRectGetWidth(parent.view.bounds)/2 + CGRectGetWidth(child.view.bounds)/2;   //Max distance  between center of the parent and child view controller
    CGFloat distaceBetweenCenters = distanceBetweenCentersOfParentAndChildController(parent, child);
    CGFloat forwardBounceValue = kMaxFrontBounceDistance;
    CGFloat backwardBounceValue = kMaxBackBounceDistance;
    
    if (distaceBetweenCenters != 0)
    {
        forwardBounceValue = kMaxFrontBounceDistance * distaceBetweenCenters / maxDistanceBetweenCenters;    //cross multi
        backwardBounceValue = kMaxBackBounceDistance * distaceBetweenCenters / maxDistanceBetweenCenters;    //cross multi
    }
    return @[
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation((distaceBetweenCenters + forwardBounceValue) * slideDirection, 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation((distaceBetweenCenters + backwardBounceValue) * slideDirection, 0.0f, 1.0f)],
    [NSValue valueWithCATransform3D:CATransform3DMakeTranslation((distaceBetweenCenters * slideDirection), 0.0f, 1.0f)]
    ];
}

- (CGFloat)animationDuration
{
    CGFloat duration = 0.0f;
    if (centerXValue(self.childViewController) != centerXValue(self))
    {
        CGFloat distanceBetweenCenters = distanceBetweenCentersOfParentAndChildController(self, self.childViewController);
        
        duration = MAX((kMaxAnimataionDuration * distanceBetweenCenters)/CGRectGetWidth(self.childViewController.view.bounds), kMinAnimataionDuration); //Cross Multiplication - If animation duration for child view controller width is kMaxAnimataionDuration, then what is the animation duration for distanceBetweenCenters.
    }
    return duration;
}

- (void)setOverlayViewAlphaForUpdatedPositionOfChildController
{
    CGFloat centerX = centerXValue(self.childViewController);
    
    CGFloat maxDistanceBetweenCenters = CGRectGetWidth(self.view.bounds)/2 + CGRectGetWidth(self.childViewController.view.bounds)/2;   //Max distance  between center of the parent and child view controller
    
    CGFloat alphaPerDistance = kMaxOverlayViewAlpha/maxDistanceBetweenCenters;
    
    //The method to find distance covered depends on the slideDirection.
    //eg: Slide direction From Left - distanceCovered = (-140 - (-160)) = -140+160 = 20;
    //eg: Slide direction From Right - distanceCovered = (440 - 480)*(-1) = -440+480 = 20;
    CGFloat distanceCovered = (centerX - [self defaultCenterOfChildViewController].x) * self.slideDirection;

    self.overlayView.alpha =  distanceCovered * alphaPerDistance;
}

//Default center implies the center point value where the child view controller is not visible or the position at the start of the animation.
- (CGPoint)defaultCenterOfChildViewController
{
    CGFloat xValueOfCenterToMoveTo;
    if (self.slideDirection == SlideDirectionFromLeft)
    {
        xValueOfCenterToMoveTo = -CGRectGetWidth(self.childViewController.view.bounds)/2;   //Placing to the left side of the parent view
    }
    else if (self.slideDirection == SlideDirectionFromRight)
    {
        xValueOfCenterToMoveTo = CGRectGetWidth(self.view.window.bounds) + CGRectGetWidth(self.childViewController.view.bounds)/2;  //Placing to the right side of the parent view
    }
    return CGPointMake(xValueOfCenterToMoveTo, self.childViewController.view.center.y);
}

#pragma mark - Private functions

- (void)prepareForAnimation
{
    UIView *childViewControllerView = self.childViewController.view;
    
    //Adding an overlay view in between the parent view and the child view
    CGRect overlayViewFrame = {{0,0},self.view.frame.size};
    self.overlayView = [[UIView alloc] initWithFrame:overlayViewFrame];
    self.overlayView.backgroundColor = [UIColor blackColor];
    self.overlayView.alpha = 0;
    [self.view addSubview:self.overlayView];
    
    [self.view addSubview:childViewControllerView];
    childViewControllerView.center = [self defaultCenterOfChildViewController];
    
    self.isParentConfiguredForAnimation = YES;
}

- (void)performBounceAnimationWithAnimationDuration:(CGFloat)animationDuration slideDirection:(SlideDirection)slideDirection
{
    [UIView animateWithDuration:animationDuration animations:^{
        self.overlayView.alpha = kMaxOverlayViewAlpha;
        CAKeyframeAnimation *slideAnimationWithBounce = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        slideAnimationWithBounce.fillMode = kCAFillModeBoth;
        slideAnimationWithBounce.values = bounceAnimationValues(self, self.childViewController, slideDirection);
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
        
    } completion:^(BOOL finished) {
        CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        CGPoint centerToMoveTo = self.view.center;
        centerToMoveTo.y -= statusBarHeight;
        self.childViewController.view.center = centerToMoveTo;
        [self.childViewController.view.layer removeAllAnimations];
        self.isChildViewDisplayed = YES;
    }];
}

- (void)reinitializeConfigurationsForParentViewController:(UIViewController*)viewController
{
    viewController.overlayView = nil;
    [viewController.overlayView removeFromSuperview];
    viewController.childViewController = nil;
    viewController.slideDirection = SlideDirectionNone;
    viewController.isParentConfiguredForAnimation = NO;
    viewController.isChildViewDisplayed = NO;
}

#pragma mark - Public functions

- (void)slideInChildViewController:(UIViewController*)childViewController
                     fromDirection:(SlideDirection)slideDirection
{
    if (childViewController != nil)
    {
        if (self.isParentConfiguredForAnimation == NO)
        {
            self.childViewController = childViewController;
            self.slideDirection = slideDirection;
            [self prepareForAnimation];
        }
        CGFloat animationDuration = [self animationDuration];
        [self performBounceAnimationWithAnimationDuration:animationDuration slideDirection:self.slideDirection];
    }
}

- (void)translateInChildViewController:(UIViewController*)childViewController
                               byValue:(CGFloat)value
                         fromDirection:(SlideDirection)slideDirection
{
   if (childViewController != nil)
   {
       if (self.isParentConfiguredForAnimation == NO)
       {
           self.slideDirection = slideDirection;
           self.childViewController = childViewController;
           [self prepareForAnimation];
       }
       CGPoint viewCenter = childViewController.view.center;
       viewCenter.x += value;
       childViewController.view.center = viewCenter;
       
       [self setOverlayViewAlphaForUpdatedPositionOfChildController];
   }
}

- (void)slideOutFromChildViewController:(UIViewController*)childViewController
{
    if (nil != childViewController)
    {
        UIViewController *parentViewController = childViewController.parentViewController;
        CGPoint centerToMoveTo = [parentViewController defaultCenterOfChildViewController];
        
        [UIView animateWithDuration:0.3f animations:^{
            parentViewController.overlayView.alpha = 0;
            childViewController.view.center = centerToMoveTo;
        } completion:^(BOOL finished) {
            [childViewController reinitializeConfigurationsForParentViewController:parentViewController];
            [childViewController.view removeFromSuperview];
        }];
    }
}

- (void)translateOutChildViewController:(UIViewController*)childViewController
                                byValue:(CGFloat)value
{
    if (nil != childViewController)
    {
        UIViewController *parentViewController = childViewController.parentViewController;
        CGPoint viewCenter = childViewController.view.center;
        if (YES == translateReachedLimit(parentViewController, childViewController, parentViewController.slideDirection))
        {
            CGFloat centerDifference = fabs(centerXValue(parentViewController) - centerXValue(childViewController));
            CGFloat valueReduceFactor = pow((1-kReductionRate), centerDifference);  //Exponential function. Referred http://goo.gl/50pfI
            value *= valueReduceFactor;
            viewCenter.x += value;
        }
        viewCenter.x += value;
        childViewController.view.center = viewCenter;
        [parentViewController setOverlayViewAlphaForUpdatedPositionOfChildController];
    }
}

- (void)handlePanEndOnChildViewController:(UIViewController*)childViewController
{
    if (nil != childViewController)
    {
        UIViewController *parentViewController = childViewController.parentViewController;
        CGFloat animationDuration = [parentViewController animationDuration];

        if (NO == parentViewController.isChildViewDisplayed)
        {
            //The child view is not displayed yet.
            
            CGFloat currentEdgePosition = centerXValue(childViewController) + (parentViewController.slideDirection * CGRectGetWidth(childViewController.view.bounds)/2);    //Right edge X value in case of sliding from the left and Left edge X Value in case of sliding from the right
            
            if (((currentEdgePosition - centerXValue(parentViewController)) * parentViewController.slideDirection) >= 0)
            {
                [parentViewController performBounceAnimationWithAnimationDuration:animationDuration
                                                                   slideDirection:parentViewController.slideDirection];
            }
            else
            {
                [parentViewController slideOutFromChildViewController:childViewController];
            }
        }
        else
        {
            //The child view is already displayed. Now either child view can be made to slide out or bounce back
            switch (parentViewController.slideDirection)
            {
                case SlideDirectionFromLeft:
                    if (centerXValue(childViewController) < 0) //View is moved to the left
                    {
                        [parentViewController slideOutFromChildViewController:childViewController];
                    }
                    else if (centerXValue(childViewController) > centerXValue(parentViewController))
                    {
                        [parentViewController performBounceAnimationWithAnimationDuration:animationDuration
                                                                           slideDirection:SlideDirectionFromRight];
                    }
                    else    //View is moved to right, hence pull back from right and bounce
                    {
                        [parentViewController performBounceAnimationWithAnimationDuration:animationDuration
                                                                           slideDirection:parentViewController.slideDirection];
                    }
                    break;
                    
                case SlideDirectionFromRight:
                    if (centerXValue(childViewController) > CGRectGetWidth(parentViewController.view.bounds))
                    {
                        [parentViewController slideOutFromChildViewController:childViewController];
                    }
                    else if (centerXValue(childViewController) < centerXValue(parentViewController))
                    {
                        [parentViewController performBounceAnimationWithAnimationDuration:animationDuration
                                                                           slideDirection:SlideDirectionFromLeft];
                    }
                    else
                    {
                        [parentViewController performBounceAnimationWithAnimationDuration:animationDuration
                                                                           slideDirection:parentViewController.slideDirection];
                    }
                    break;
                    
                default:
                    break;
            }
        }
    }
}

@end
