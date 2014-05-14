//
//  ChildViewControllerRight.m
//  SlidePresentVC
//
//  Created by Adithya H on 11/02/13.
//

#import "ChildViewControllerRight.h"
#import "UIViewController+SlideChildViewController.h"

@interface ChildViewControllerRight ()

@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *ibPanGestureRecognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *ibSwipeGestureRecognizer;
@property CGFloat previousTranslationValue;

- (IBAction)slideOutToRight:(id)sender;

- (IBAction)handlePan:(UIPanGestureRecognizer*)panGestureRecognizer;
- (IBAction)handleSwipe:(UISwipeGestureRecognizer*)swipeGestureRecognizer;

@end

@implementation ChildViewControllerRight

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.ibPanGestureRecognizer requireGestureRecognizerToFail:self.ibSwipeGestureRecognizer];
}

- (IBAction)slideOutToRight:(id)sender
{
    [self slideOutFromChildViewController:self.navigationController];
}

- (IBAction)handleSwipe:(UISwipeGestureRecognizer*)swipeGestureRecognizer
{
    if ([swipeGestureRecognizer direction] == UISwipeGestureRecognizerDirectionRight)
    {
        [self slideOutFromChildViewController:self.navigationController];
    }
}

- (IBAction)handlePan:(UIPanGestureRecognizer*)panGestureRecognizer
{
    CGFloat translationX = [panGestureRecognizer translationInView:self.view].x;
    if ([panGestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        CGFloat translationDx = translationX - self.previousTranslationValue;
        [self.navigationController translateOutChildViewController:self.navigationController
                                                           byValue:translationDx];
    }
    else if ([panGestureRecognizer state] == UIGestureRecognizerStateEnded)
    {
        [self handlePanEndOnChildViewController:self.navigationController];
    }
    self.previousTranslationValue = translationX;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)viewDidUnload
{
    [self setIbPanGestureRecognizer:nil];
    [self setIbSwipeGestureRecognizer:nil];
    [super viewDidUnload];
}

@end
