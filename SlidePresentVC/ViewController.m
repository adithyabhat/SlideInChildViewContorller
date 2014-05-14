//
//  ViewController.m
//  SlidePresentVC
//
//  Created by Adithya H on 06/02/13.
//

#import "ViewController.h"
#import "ChildViewControllerLeft.h"
#import "ChildViewControllerRight.h"
#import "UIViewController+SlideChildViewController.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *ibPanGestureRecognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *ibSwipeGestureRight;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *ibSwipeGestureLeft;

@property (strong) UIViewController *childControllerLeft;
@property (strong) UIViewController *childControllerRight;
@property (assign) CGFloat previousTranslationValue;

-(IBAction)showFromLeft:(id)sender;
-(IBAction)showFromRight:(id)sender;

- (IBAction)handlePan:(UIPanGestureRecognizer*)panGestureRecognizer;
-(IBAction)handleSwipeRight:(UISwipeGestureRecognizer*)swipeGestureRecognizer;
-(IBAction)handleSwipeLeft:(UISwipeGestureRecognizer*)swipeGestureRecognizer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    ChildViewControllerLeft *childControllerLeft = [[ChildViewControllerLeft alloc] init];
    UINavigationController *navController1 = [[UINavigationController alloc] initWithRootViewController:childControllerLeft];
    self.childControllerLeft = navController1;
    [self addChildViewController:self.childControllerLeft];
    
    ChildViewControllerRight *childControllerRight = [[ChildViewControllerRight alloc] init];
    UINavigationController *navController2 = [[UINavigationController alloc] initWithRootViewController:childControllerRight];
    self.childControllerRight = navController2;
    [self addChildViewController:self.childControllerRight];
    
    [self.ibPanGestureRecognizer requireGestureRecognizerToFail:self.ibSwipeGestureRight];
    [self.ibPanGestureRecognizer requireGestureRecognizerToFail:self.ibSwipeGestureLeft];
}

-(IBAction)showFromLeft:(id)sender
{
    [self slideInChildViewController:self.childControllerLeft fromDirection:SlideDirectionFromLeft];
}

-(IBAction)showFromRight:(id)sender
{
    [self slideInChildViewController:self.childControllerRight fromDirection:SlideDirectionFromRight];
}

-(IBAction)handleSwipeRight:(UISwipeGestureRecognizer*)swipeGestureRecognizer
{
    if ([swipeGestureRecognizer direction] == UISwipeGestureRecognizerDirectionRight)
    {
        [self slideInChildViewController:self.childControllerLeft fromDirection:SlideDirectionFromLeft];
    }
}

-(IBAction)handleSwipeLeft:(UISwipeGestureRecognizer*)swipeGestureRecognizer
{
    if ([swipeGestureRecognizer direction] == UISwipeGestureRecognizerDirectionLeft)
    {
        [self slideInChildViewController:self.childControllerRight fromDirection:SlideDirectionFromRight];
    }
}

- (IBAction)handlePan:(UIPanGestureRecognizer*)panGestureRecognizer
{
    CGFloat translationX = [panGestureRecognizer translationInView:self.view].x;
    static SlideDirection slideDir;
    if ([panGestureRecognizer state] == UIGestureRecognizerStateBegan)
    {
        if (translationX > 0)
            slideDir = SlideDirectionFromLeft;
        else
            slideDir = SlideDirectionFromRight;
    }
    else if ([panGestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        CGFloat translationDx = translationX - self.previousTranslationValue;
        if (slideDir == SlideDirectionFromLeft)
        {
            [self translateInChildViewController:self.childControllerLeft
                                         byValue:translationDx
                                   fromDirection:SlideDirectionFromLeft];
        }
        else
        {
            [self translateInChildViewController:self.childControllerRight
                                         byValue:translationDx
                                   fromDirection:SlideDirectionFromRight];
        }
    }
    else if ([panGestureRecognizer state] == UIGestureRecognizerStateEnded)
    {
        [self handlePanEndOnChildViewController:self.childViewController];
    }
    self.previousTranslationValue = translationX;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)viewDidUnload {
    [self setIbPanGestureRecognizer:nil];
    [self setIbSwipeGestureRight:nil];
    [self setIbSwipeGestureLeft:nil];
    [super viewDidUnload];
}
@end
