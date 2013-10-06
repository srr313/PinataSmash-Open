//
//  SplashScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/21/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "SplashScreen.h"
#import "EAGLView.h"
#import "JiggleAnimation.h"
#import "Sounds.h"

#define SPLASH_DURATION 3.0f

@implementation SplashScreen

-(id)initWithFlowManager:(id<FlowManager>)fm andImage:(eTexture)tex andDelay:(float)d; {
    if (self == [super initWithFlowManager:fm]) {
        totalTimeElapsed    = 0.0f;
        delay               = d; 
        texture             = tex;
    }
    return self;    
}

-(void)dealloc {
    [splashImage release];
    [super dealloc];
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    totalTimeElapsed += timeElapsed;
    if (totalTimeElapsed >= SPLASH_DURATION) {
        [responder performSelector:selector withObject:self];        
        [flowManager changeFlowState:kFlowState_Title];
    }
    else if (totalTimeElapsed >= delay && !splashImage) {
        [splashImage bounce];
        splashImage.visible     = true;
        splashImage.jiggling    = true;
        
        splashImage = [[ImageControl alloc] 
                        initAt:Vector2DMul(GetGLDimensions(), 0.5f) 
                        withTexture:texture]; 
        splashImage.jiggling = true;
        [splashImage bounce];
        [self addControl:splashImage];   
        
        [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Slurp)];                    
    }
}

-(void)setResponder:(id)resp andSelector:(SEL)sel {
    responder   = resp;
    selector    = sel;
}

@end
