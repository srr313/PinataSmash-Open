//
//  PauseScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/3/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "PauseScreen.h"
#import "EAGLView.h"
#import "Localize.h"

@interface PauseScreen()
-(void)resumeAction:(ButtonControl*)owner;
-(void)menuAction:(ButtonControl*)owner;
-(void)playAgainAction:(ButtonControl*)owner;
@end

@implementation PauseScreen

-(id)initWithFlowManager:(id<FlowManager>)fm andGame:(Game*)g {
    if (self = [super initWithFlowManager:fm]) {
        game = g;
    
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:Vector2DMul(GetGLDimensions(), 0.5f) withTexture:kTexture_GamePanel];
        bgImage.jiggling    = true;
        bgImage.baseAlpha   = 0.75f;
        [bgImage bounce];
        [self addControl:bgImage]; 
        [bgImage release];
        bgImage = nil;     
    
        Vector2D pos = Vector2DMul(GetGLDimensions(), 0.5f);
        pos.y = 400.0f;
        TextControl* pauseText = [[TextControl alloc] 
            initAt: pos
            withText:kLocalizedString_Pause
            andArg:nil
            andDimensions:Vector2DMake(256.0f,72.0f) 
            andAlignment:UITextAlignmentCenter 
            andFontName:DEFAULT_FONT andFontSize:72];
        pauseText.tilting = true;
        pauseText.hasShadow = true;
        pauseText.jiggling = true;
        [pauseText setFade:kFade_In];
        [pauseText bounce:1.0f];
        [self addControl:pauseText];
        [pauseText release];
        pauseText = nil;
        
        pos.y = 0.5f*GetGLHeight();
        ButtonControl* playButton = [[ButtonControl alloc] 
            initAt:pos withTexture:kTexture_PlayButton andString:nil];
        [playButton setResponder:self andSelector:@selector(resumeAction:)];
        [playButton setFade:kFade_In];
        [playButton bounce];
        [self addControl:playButton];
        [playButton release];
        playButton = nil;
        
        pos.x = 240.0f;
        pos.y -= 75.0f;
        ButtonControl* retryButton = [[ButtonControl alloc] 
            initAt:pos withTexture:kTexture_RetryButton andString:nil];
        [retryButton setResponder:self andSelector:@selector(playAgainAction:)];
        [retryButton setFade:kFade_In];
        [retryButton bounce];
        [self addControl:retryButton];
        [retryButton release];
        retryButton = nil;           
        
        pos.x = 80.0f;
        ButtonControl* menuButton = [[ButtonControl alloc] 
            initAt:pos withTexture:kTexture_MenuButton andString:nil];
        [menuButton setResponder:self andSelector:@selector(menuAction:)];
        [menuButton setFade:kFade_In];
        [menuButton bounce];
        [self addControl:menuButton];
        [menuButton release];
        menuButton = nil;        
    }
    return self;    
}

-(void)resumeAction:(ButtonControl *)owner {
    [flowManager changeFlowState:kFlowState_GameResume];
}

-(void)menuAction:(ButtonControl *)owner {
    [flowManager changeFlowState:kFlowState_LevelSelection]; 
}

-(void)playAgainAction:(ButtonControl*)owner {
    [game retryLevel];
}


@end
