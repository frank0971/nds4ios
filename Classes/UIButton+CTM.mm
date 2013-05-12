//
//  Button.m
//  nds4ios
//
//  Created by rock88 on 12/05/2013.
//  Copyright (c) 2013 Homebrew. All rights reserved.
//

#import "UIButton+CTM.h"
#import <objc/runtime.h>

static char UIB_BUTTIN_ID;

@implementation UIButton (CTM)
@dynamic buttonId;

+ (UIButton*)buttonWithId:(BUTTON_ID)_buttonId atCenter:(CGPoint)center
{
    NSArray* array = @[@"Right",@"Left",@"Down",@"Up",@"Select",@"Start",@"B",@"A",@"Y",@"X",@"L",@"R"];
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    if (_buttonId != -1) {
        [button setTitle:array[_buttonId] forState:UIControlStateNormal];
    } else {
        [button setTitle:@"Exit" forState:UIControlStateNormal];
    }
    
    if (_buttonId == -1  || _buttonId == BUTTON_START || _buttonId == BUTTON_SELECT) {
        button.frame = CGRectMake(0, 0, 50, 25);
    } else {
        button.frame = CGRectMake(0, 0, 40, 40);
    }
    button.center = center;
    
    button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10.0f];
    button.alpha = 0.6f;
    button.buttonId = [NSNumber numberWithInt:_buttonId];
    
    if (_buttonId != -1)
    {
        [button addTarget:button action:@selector(onButtonUp:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:button action:@selector(onButtonDown:) forControlEvents:UIControlEventTouchDown];
    }
    
    return button;
}

- (void)setButtonId:(NSNumber *)_buttonId
{
    objc_setAssociatedObject(self, &UIB_BUTTIN_ID, _buttonId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber*)buttonId
{
    return (NSNumber*)objc_getAssociatedObject(self, &UIB_BUTTIN_ID);
}

- (void)onButtonUp:(id)sender
{
    EMU_buttonUp((BUTTON_ID)[self.buttonId intValue]);
}

- (void)onButtonDown:(id)sender
{
    EMU_buttonDown((BUTTON_ID)[self.buttonId intValue]);
}

- (void)shift
{
    if (self.center.y < 240.0f) {
        self.center = CGPointMake(self.center.x, self.center.y + 240.0f);
    } else {
        self.center = CGPointMake(self.center.x, self.center.y - 240.0f);
    }
}

@end
