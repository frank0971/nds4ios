//
//  ViewController.m
//  nds4ios
//
//  Created by Admin on 11/12/2012.
//  Copyright (c) 2012 Homebrew. All rights reserved.
//

#import "EmuViewController.h"
#include "emu.h"

@interface EmuViewController ()

@property (nonatomic,retain) UIImageView* imageView;
@property (nonatomic,retain) NSString* documentsPath;
@property (nonatomic,retain) NSString* rom;
@property (nonatomic,assign) BOOL initialize;

@end

@implementation EmuViewController
@synthesize imageView,documentsPath,rom,initialize;

- (id)initWithRom:(NSString*)_rom
{
    self = [super init];
    if (self) {
        initialize = NO;
        
        self.documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.rom = [NSString stringWithFormat:@"%@/%@",self.documentsPath,_rom];
        
        NSLog(@"rom = %@",self.rom);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)] autorelease];
    [self.view insertSubview:self.imageView atIndex:0];
    
    self.view.multipleTouchEnabled = YES;
    
    if (!initialize) {
        initialize = YES;
        EMU_setWorkingDir([self.documentsPath UTF8String]);
        EMU_init();
        EMU_loadRom([self.rom UTF8String]);
        EMU_change3D(2);
        EMU_changeSound(0);
    }
    
    //[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(onTimer:) userInfo:nil repeats:NO];
    [self performSelector:@selector(onTimer:) withObject:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    self.imageView = nil;
    [super viewDidUnload];
}

- (void)dealloc
{
    [self viewDidUnload];
    self.documentsPath = nil;
    self.rom = nil;
    [super dealloc];
}

- (void)onTimer:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (execute) {
            EMU_runCore();
            int fps = EMU_runOther();
            EMU_copyMasterBuffer();
            [self drawImage];
        }
    });
}

- (void)drawImage
{
    dispatch_async(dispatch_get_main_queue(), ^{
    CGColorSpaceRef color = CGColorSpaceCreateDeviceRGB();
#if 1
    CGContextRef context = CGBitmapContextCreate(video.buffer, 256, 384, 8, 512*2, color, kCGImageAlphaNoneSkipLast);
#else
    CGContextRef context = CGBitmapContextCreate(video.buffer, 256, 384, 5, 512, color, kCGImageAlphaNoneSkipFirst);
#endif
    CGImageRef cg_image = CGBitmapContextCreateImage(context);
    UIImage* image = [UIImage imageWithCGImage:cg_image];
    
    
        self.imageView.image = image;
    ;
    
    CGColorSpaceRelease(color);
    CGContextRelease(context);
    CGImageRelease(cg_image);
    });
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if (point.y < 240) return;
    
    point.x /= 1.33;
    point.y -= 240;
    point.y /= 1.33;
    
    EMU_touchScreenTouch(point.x, point.y);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if (point.y < 240) return;
    
    point.x /= 1.33;
    point.y -= 240;
    point.y /= 1.33;
    
    EMU_touchScreenTouch(point.x, point.y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    EMU_touchScreenRelease();
}

- (IBAction)buttonExitDown:(id)sender
{
    EMU_closeRom();
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)buttonPadDown:(UIButton*)button
{
    EMU_buttonDown((BUTTON_PAD)button.tag);
}

- (IBAction)buttonPadUp:(UIButton*)button
{
    EMU_buttonUp((BUTTON_PAD)button.tag);
}


@end


