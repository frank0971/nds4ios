//
//  Button.h
//  nds4ios
//
//  Created by rock88 on 12/05/2013.
//  Copyright (c) 2013 Homebrew. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "emu.h"

@interface UIButton (CTM)

@property (nonatomic,strong) NSNumber* buttonId;

+ (UIButton*)buttonWithId:(BUTTON_ID)_buttonId atCenter:(CGPoint)center;

@end
