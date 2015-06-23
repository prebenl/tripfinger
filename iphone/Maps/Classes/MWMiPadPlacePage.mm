//
//  MWMiPadPlacePageView.m
//  Maps
//
//  Created by v.mikhaylenko on 18.05.15.
//  Copyright (c) 2015 MapsWithMe. All rights reserved.
//

#import "MWMiPadPlacePage.h"
#import "MWMPlacePageViewManager.h"
#import "MWMPlacePageActionBar.h"
#import "UIKitCategories.h"
#import "MWMBasePlacePageView.h"
#import "MWMBookmarkColorViewController.h"
#import "SelectSetVC.h"
#import "UIViewController+Navigation.h"
#import "MWMBookmarkDescriptionViewController.h"

extern CGFloat kBookmarkCellHeight;
static CGFloat const kLeftOffset = 12.;
static CGFloat const kTopOffset = 36.;

@interface MWMiPadNavigationController : UINavigationController

@end

@implementation MWMiPadNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
  self = [super initWithRootViewController:rootViewController];
  if (self)
  {
    [self setNavigationBarHidden:YES];
    [self.navigationBar setTranslucent:NO];
    self.view.autoresizingMask = UIViewAutoresizingNone;
  }
  return self;
}

- (void)backTap:(id)sender
{
  [self popViewControllerAnimated:YES];
}

@end

@interface MWMiPadPlacePageViewController : UIViewController

@end

@implementation MWMiPadPlacePageViewController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES];
  self.view.autoresizingMask = UIViewAutoresizingNone;
}

@end

@interface MWMiPadPlacePage ()

@property (strong, nonatomic) MWMiPadNavigationController * navigationController;
@property (strong, nonatomic) MWMiPadPlacePageViewController * viewController;

@end

@implementation MWMiPadPlacePage

- (void)configure
{
  [super configure];
  UIView * view = self.manager.ownerViewController.view;
  self.viewController = [[MWMiPadPlacePageViewController alloc] init];
  [self.navigationController.view removeFromSuperview];
  [self.navigationController removeFromParentViewController];
  self.navigationController = [[MWMiPadNavigationController alloc] initWithRootViewController:self.viewController];
  [self configureShadow];

  CGFloat const defaultWidth = 360.;
  CGFloat const actionBarHeight = 58.;
  CGFloat const defaultHeight = self.basePlacePageView.height + self.anchorImageView.height + actionBarHeight - 1;

  [self.manager.ownerViewController addChildViewController:self.navigationController];
  self.navigationController.view.frame = CGRectMake( - defaultWidth, kTopOffset, defaultWidth, defaultHeight);
  self.viewController.view.frame = CGRectMake(kLeftOffset, kTopOffset, defaultWidth, defaultHeight);
  [self.viewController.view addSubview:self.extendedPlacePageView];
  [self.viewController.view addSubview:self.actionBar];
  self.extendedPlacePageView.frame = CGRectMake(0., 0., defaultWidth, defaultHeight);
  self.anchorImageView.image = nil;
  self.anchorImageView.backgroundColor = [UIColor whiteColor];
  self.actionBar.width = defaultWidth;
  self.actionBar.origin = CGPointMake(0., defaultHeight - actionBarHeight);
  [view addSubview:self.navigationController.view];
}

- (void)configureShadow
{
  CALayer * layer = self.navigationController.view.layer;
  layer.masksToBounds = NO;
  layer.shadowColor = UIColor.blackColor.CGColor;
  layer.shadowRadius = 4.;
  layer.shadowOpacity = 0.24f;
  layer.shadowOffset = CGSizeMake(0., - 2.);
  layer.shouldRasterize = YES;
}

- (void)show
{
  [UIView animateWithDuration:0.2f animations:^
  {
    self.navigationController.view.center = CGPointMake(kLeftOffset + self.navigationController.view.width / 2., kTopOffset + self.navigationController.view.height / 2.);
  }];
}

- (void)dismiss
{
  [UIView animateWithDuration:0.2f animations:^
  {
    self.navigationController.view.center = CGPointMake( - self.navigationController.view.width / 2. - kLeftOffset , kTopOffset);
  }
  completion:^(BOOL finished)
  {
    [self.navigationController.view removeFromSuperview];
    [self.navigationController removeFromParentViewController];
    [super dismiss];
  }];
}

- (void)willFinishEditingBookmarkTitle:(NSString *)title
{
  [super willFinishEditingBookmarkTitle:title];
  CGFloat const actionBarHeight = self.actionBar.height;
  CGFloat const defaultHeight = self.basePlacePageView.height + self.anchorImageView.height + actionBarHeight - 1;
  self.actionBar.origin = CGPointMake(0., defaultHeight - actionBarHeight);
  self.navigationController.view.height = defaultHeight;
}

- (void)addBookmark
{
  [super addBookmark];
  self.navigationController.view.height += kBookmarkCellHeight;
  self.viewController.view.height += kBookmarkCellHeight;
  self.extendedPlacePageView.height += kBookmarkCellHeight;
  self.actionBar.minY += kBookmarkCellHeight;
}

- (void)removeBookmark
{
  [super removeBookmark];
  self.navigationController.view.height -= kBookmarkCellHeight;
  self.viewController.view.height -= kBookmarkCellHeight;
  self.extendedPlacePageView.height -= kBookmarkCellHeight;
  self.actionBar.minY -= kBookmarkCellHeight;
}

- (void)changeBookmarkColor
{
  MWMBookmarkColorViewController * controller = [[MWMBookmarkColorViewController alloc] initWithNibName:[MWMBookmarkColorViewController className] bundle:nil];
  controller.iPadOwnerNavigationController = self.navigationController;
  controller.placePageManager = self.manager;
  controller.view.frame = self.viewController.view.frame;
  [self.viewController.navigationController pushViewController:controller animated:YES];
}

- (void)changeBookmarkCategory
{
  SelectSetVC * controller = [[SelectSetVC alloc] initWithPlacePageManager:self.manager];
  controller.iPadOwnerNavigationController = self.navigationController;
  controller.view.frame = self.viewController.view.frame;
  [self.viewController.navigationController pushViewController:controller animated:YES];
}

- (void)changeBookmarkDescription
{
  MWMBookmarkDescriptionViewController * controller = [[MWMBookmarkDescriptionViewController alloc] initWithPlacePageManager:self.manager];
  controller.iPadOwnerNavigationController = self.navigationController;
  [self.viewController.navigationController pushViewController:controller animated:YES];
}

- (IBAction)didPan:(UIPanGestureRecognizer *)sender
{
  UIView * navigationControllerView = self.navigationController.view;
  UIView * superview = navigationControllerView.superview;

  navigationControllerView.minX += [sender translationInView:superview].x;
  navigationControllerView.minX = MIN(navigationControllerView.minX, kLeftOffset);
  [sender setTranslation:CGPointZero inView:superview];
  navigationControllerView.alpha = self.currentAlpha;
  UIGestureRecognizerState const state = sender.state;
  if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
  {
    if (navigationControllerView.minX < ( - navigationControllerView.width / 8.))
    {
      [UIView animateWithDuration:0.2f animations:^
      {
        navigationControllerView.minX = - kLeftOffset - navigationControllerView.width;
        navigationControllerView.alpha = self.currentAlpha;
      }
      completion:^(BOOL finished)
      {
        [self.manager dismissPlacePage];
      }];
    }
    else
    {
      [UIView animateWithDuration:0.2f animations:^
      {
        navigationControllerView.minX = kLeftOffset;
        navigationControllerView.alpha = self.currentAlpha;
      }];
    }
  }
}

- (CGFloat)currentAlpha
{
  UIView * view = self.navigationController.view;
  CGFloat const maxX = MAX(0., view.maxX);
  return maxX / (view.width + kLeftOffset);
}

@end