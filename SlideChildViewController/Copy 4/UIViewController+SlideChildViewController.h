//
//  UIViewController+SlideChildViewController.h
//  SlidePresentVC
//
//  Created by Adithya H on 06/02/13.
//  Copyright (c) 2013 Robosoft Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    SlideDirectionFromRight = -1,
    SlideDirectionFromLeft = 1
} SlideDirection;

@interface UIViewController (SlideChildViewController)

@property BOOL isChildViewVisible;
@property (strong) UIView *overlayView;
@property (weak) UIViewController *childViewController;
@property (assign) SlideDirection slideDirection;

- (void)slideInChildViewController:(UIViewController*)childViewController
                      fromDirection:(SlideDirection)slideDirection;

- (void)slideOutFromParentController:(UIViewController*)parentViewController
                          toDirection:(SlideDirection)slideDirection;

- (void)translateInChildViewController:(UIViewController*)childViewController byValue:(CGFloat)value;

- (void)translateOutFromParentViewController:(UIViewController*)parentViewController byValue:(CGFloat)value;

@end
