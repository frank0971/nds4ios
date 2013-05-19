//
//  ViewController.m
//  nds4ios
//
//  Created by rock88 on 11/12/2012.
//  Copyright (c) 2012 Homebrew. All rights reserved.
//

#import "AppDelegate.h"

#import "EmuViewController.h"
#import "UIButton+CTM.h"
#import "GLProgram.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>

#include "emu.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString *const kVertShader = SHADER_STRING
(
    attribute vec4 position;
    attribute vec2 inputTextureCoordinate;
    
    varying highp vec2 texCoord;
                                            
    void main()
    {
        texCoord = inputTextureCoordinate;
        gl_Position = position;
    }
);

NSString *const kFragShader = SHADER_STRING
(
    uniform sampler2D inputImageTexture;
    varying highp vec2 texCoord;
    
    void main()
    {
        highp vec4 color = texture2D(inputImageTexture, texCoord);
        gl_FragColor = color;
    }
);

const float positionVert[] =
{
    -1.0f, 1.0f,
    1.0f, 1.0f,
    -1.0f, -1.0f,
    1.0f, -1.0f
};

const float textureVert[] =
{
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f
};

@interface EmuViewController () <GLKViewDelegate>
{
    int fps;
    
    GLuint texHandle;
    GLint attribPos;
    GLint attribTexCoord;
    GLint texUniform;
    
}

@property (nonatomic,strong) UILabel* fpsLabel;
@property (nonatomic,strong) NSString* documentsPath;
@property (nonatomic,strong) NSString* rom;
@property (nonatomic,strong) NSArray* buttonsArray;
@property (nonatomic,strong) GLProgram* program;
@property (nonatomic,strong) EAGLContext* context;
@property (nonatomic,strong) GLKView* glkView;
@property (nonatomic,assign) BOOL initialize;

@end

@implementation EmuViewController
@synthesize fpsLabel,documentsPath,rom,initialize;
@synthesize program,context,glkView,buttonsArray;

- (id)initWithRom:(NSString*)_rom
{
    self = [super init];
    if (self) {
        self.documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        initialize = YES;
        self.rom = [NSString stringWithFormat:@"%@/%@",self.documentsPath,_rom];
    }
    return self;
}

- (void)killCurrentGame
{
    EMU_closeRom();
    [self shutdownGL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (initialize == YES)
    {
        EMU_closeRom();
    }
    
    self.view.multipleTouchEnabled = YES;
    
    self.fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, 100, 30)];
    self.fpsLabel.backgroundColor = [UIColor clearColor];
    self.fpsLabel.textColor = [UIColor greenColor];
    self.fpsLabel.shadowColor = [UIColor blackColor];
    self.fpsLabel.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.fpsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    [self.view addSubview:self.fpsLabel];
    
    [self addButtons];
    
    [self initRom];
    
    [self performSelector:@selector(emuLoop) withObject:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    //[self shutdownGL];
    [super viewDidUnload];
}

- (void)dealloc
{
    [self viewDidUnload];
}

- (void)initRom
{
    initialize = YES;
    EMU_setWorkingDir([self.documentsPath UTF8String]);
    EMU_init();
    EMU_loadRom([self.rom UTF8String]);
    EMU_change3D(1);
    EMU_changeSound(0);
    
    [self initGL];
}

- (void)initGL
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    self.glkView = [[GLKView alloc] initWithFrame:self.view.bounds context:self.context];//self.view.bounds
    self.glkView.delegate = self;
    [self.view insertSubview:self.glkView atIndex:0];
    
    self.program = [[GLProgram alloc] initWithVertexShaderString:kVertShader fragmentShaderString:kFragShader];
    
    [self.program addAttribute:@"position"];
	[self.program addAttribute:@"inputTextureCoordinate"];
    
    [self.program link];
    
    attribPos = [self.program attributeIndex:@"position"];
    attribTexCoord = [self.program attributeIndex:@"inputTextureCoordinate"];
    
    texUniform = [self.program uniformIndex:@"inputImageTexture"];
    
    glEnableVertexAttribArray(attribPos);
    glEnableVertexAttribArray(attribTexCoord);
    
    float scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(self.glkView.bounds.size.width * scale, self.glkView.bounds.size.height * scale);
    
    glViewport(0, 0, size.width, size.height);
    
    [self.program use];
    
    glGenTextures(1, &texHandle);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texHandle);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)shutdownGL
{
    glDeleteTextures(1, &texHandle);
    self.context = nil;
    self.program = nil;
    [EAGLContext setCurrentContext:nil];
}

- (void)emuLoop
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (execute) {
            EMU_runCore();
            fps = EMU_runOther();
            EMU_copyMasterBuffer();
            
            [self updateDisplay];
        }
    });
}

- (void)updateDisplay
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.fpsLabel.text = [NSString stringWithFormat:@"FPS: %d",fps];
        
        glBindTexture(GL_TEXTURE_2D, texHandle);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 384, 0, GL_RGBA, GL_UNSIGNED_BYTE, &video.buffer);
        
        [self.glkView display];
        
    });
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texHandle);
    glUniform1i(texUniform, 1);
    
    glVertexAttribPointer(attribPos, 2, GL_FLOAT, 0, 0, (const GLfloat*)&positionVert);
    glVertexAttribPointer(attribTexCoord, 2, GL_FLOAT, 0, 0, (const GLfloat*)&textureVert);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)addButtons
{
    UIButton* buttonUp = [UIButton buttonWithId:BUTTON_UP atCenter:CGPointMake(60, 132)];
    [self.view addSubview:buttonUp];
    
    UIButton* buttonDown = [UIButton buttonWithId:BUTTON_DOWN atCenter:CGPointMake(60, 211)];
    [self.view addSubview:buttonDown];
    
    UIButton* buttonLeft = [UIButton buttonWithId:BUTTON_LEFT atCenter:CGPointMake(20, 172)];
    [self.view addSubview:buttonLeft];
    
    UIButton* buttonRight = [UIButton buttonWithId:BUTTON_RIGHT atCenter:CGPointMake(100, 172)];
    [self.view addSubview:buttonRight];
    
    UIButton* buttonX = [UIButton buttonWithId:BUTTON_X atCenter:CGPointMake(219, 173)];
    [self.view addSubview:buttonX];
    
    UIButton* buttonY = [UIButton buttonWithId:BUTTON_Y atCenter:CGPointMake(259, 132)];
    [self.view addSubview:buttonY];
    
    UIButton* buttonA = [UIButton buttonWithId:BUTTON_A atCenter:CGPointMake(259, 211)];
    [self.view addSubview:buttonA];
    
    UIButton* buttonB = [UIButton buttonWithId:BUTTON_B atCenter:CGPointMake(299, 173)];
    [self.view addSubview:buttonB];
    
    UIButton* buttonSelect = [UIButton buttonWithId:BUTTON_SELECT atCenter:CGPointMake(132, 228)];
    [self.view addSubview:buttonSelect];
    
    UIButton* buttonStart = [UIButton buttonWithId:BUTTON_START atCenter:CGPointMake(186, 228)];
    [self.view addSubview:buttonStart];
    
    UIButton* buttonExit = [UIButton buttonWithId:(BUTTON_ID)-1 atCenter:CGPointMake(160, 20)];
    [buttonExit addTarget:self action:@selector(buttonExitDown:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonExit];
    
    UIButton *buttonLT = [UIButton buttonWithId:BUTTON_L atCenter:CGPointMake(20, 70)];
    [self.view addSubview:buttonLT];
    
    UIButton *buttonRT = [UIButton buttonWithId:BUTTON_R atCenter:CGPointMake(self.view.frame.size.width - 20, 70)];
    [self.view addSubview:buttonRT];
    
    UIButton* buttonShift = [UIButton buttonWithId:(BUTTON_ID)-1 atCenter:CGPointMake(290, 20)];
    [buttonShift addTarget:self action:@selector(shiftButtons:) forControlEvents:UIControlEventTouchUpInside];
    [buttonShift setTitle:@"Shift Pad" forState:UIControlStateNormal];
    [self.view addSubview:buttonShift];
    
    self.buttonsArray = @[buttonUp,buttonDown,buttonLeft,buttonRight,
                          buttonX,buttonY,buttonA,buttonB,
                          buttonSelect,buttonStart, buttonRT, buttonLT];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if (point.y < 240.0f) return;
    
    point.x /= 1.33f;
    point.y -= 240.0f;
    point.y /= 1.33f;
    
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

- (void)shiftButtons:(id)sender
{
    [self.buttonsArray makeObjectsPerformSelector:@selector(shift)];
}

- (void)buttonExitDown:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Background or Kill?\nBackgrounding keeps the current game alive for later, whereas killing it will completely close it." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Kill" otherButtonTitles:@"Background", nil];
    [sheet showInView:self.view];
}

#pragma mark UIActionSheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [self killCurrentGame];
        [[AppDelegate sharedInstance] killVC:self];
        NSLog(@"killed");
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (buttonIndex == 1) {
        NSLog(@"backgrounded");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}
@end

