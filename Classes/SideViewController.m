//
//  SideViewController.m
//  nds4ios
//
//  Created by Brian Tung on 5/15/13.
//  Copyright (c) 2013 Homebrew. All rights reserved.
//

#import "AppDelegate.h"
#import "SideViewController.h"
#import "MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "UIViewController+MMDrawerController.h"
#import "SettingsViewController.h"
#import "RomsViewController.h"
#import "EmuViewController.h"

@interface SideViewController ()

@end

@implementation SideViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    fullWidth = false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)currentGame:(id)sender
{
    [[AppDelegate sharedInstance] bringBackEmuVC];
}

- (IBAction)roms:(id)sender
{
    RomsViewController *romsVC = [[RomsViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:romsVC];
    [self.mm_drawerController setCenterViewController:navController withFullCloseAnimation:YES completion:nil];
}

- (IBAction)fileBrowser:(id)sender
{
    //nothing yet
}

- (IBAction)settings:(id)sender
{
    SettingsViewController *settingsVC = [[SettingsViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self.mm_drawerController setCenterViewController:navController withFullCloseAnimation:YES completion:nil];
}

- (IBAction)credits:(id)sender
{
    if (fullWidth == false)
    {
        [self.mm_drawerController setMaximumLeftDrawerWidth:320 animated:YES completion:nil];
        fullWidth = true;
    } else if (fullWidth == true)
    {
        [self.mm_drawerController setMaximumLeftDrawerWidth:160 animated:YES completion:nil];
        fullWidth = false;
    }
}

@end
