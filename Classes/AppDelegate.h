//
//  AppDelegate.h
//  nds4ios
//
//  Created by rock88 on 11/12/2012.
//  Copyright (c) 2012 Homebrew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EmuViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    EmuViewController *emuVC;
}

@property (strong, nonatomic) UIWindow *window;

+ (AppDelegate *)sharedInstance;

- (void)initRomsVCWithRom:(NSString *)rom;
- (void)bringBackEmuVC;

@end
