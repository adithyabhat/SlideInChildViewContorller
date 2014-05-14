//
//  UIViewController+SlideChildViewController.h
//  SlidePresentVC
//
//  Created by Adithya H on 06/02/13.
//

/*****************************************************************
 This category enables to present view controllers in a sliding
 manner from the left and right direction.
 *****************************************************************/

#import <UIKit/UIKit.h>

typedef enum
{
    SlideDirectionFromRight = -1,
    SlideDirectionNone = 0,
    SlideDirectionFromLeft = 1
} SlideDirection;

@interface UIViewController (SlideChildViewController)

@property BOOL isParentConfiguredForAnimation;
@property BOOL isChildViewDisplayed;
@property SlideDirection slideDirection;
@property (strong) UIView *overlayView;
@property (weak) UIViewController *childViewController;

/**
 This function slides in the child view controller, should be called from the 
 parent view controller.
 */
- (void)slideInChildViewController:(UIViewController*)childViewController
                      fromDirection:(SlideDirection)slideDirection;

/**
 Function translates the child view controller by the value passed in the 
 specified direction.
 */
- (void)translateInChildViewController:(UIViewController*)childViewController
                               byValue:(CGFloat)value
                         fromDirection:(SlideDirection)slideDirection;

/**
 This function slides out the child view controller, can be called from parent or
 child view controller
 */
- (void)slideOutFromChildViewController:(UIViewController*)childViewController;

/**
 Function translates the child view controller by the value passed in the
 specified direction.
 */
- (void)translateOutChildViewController:(UIViewController*)childViewController
                                byValue:(CGFloat)value;

/**
 Function should be called when the panning of the child view conrtoller ends.
 Function performs the necessary animation effects, either slide out the child 
 controller or perform a bounce animation.
 */
- (void)handlePanEndOnChildViewController:(UIViewController*)childViewController;

@end
