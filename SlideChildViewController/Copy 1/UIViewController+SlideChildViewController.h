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
    SlideDirectionLeft,
    SlideDirectionRight
} SlideDirection;

@interface UIViewController (SlideChildViewController)

@property BOOL isChildViewVisible;
@property (strong) UIView *overlayView;

- (void)slideInChildViewController:(UIViewController*)childViewController
                      fromDirection:(SlideDirection)slideDirection;

- (void)slideOutFromParentController:(UIViewController*)parentViewController
                          toDirection:(SlideDirection)slideDirection;

@end
