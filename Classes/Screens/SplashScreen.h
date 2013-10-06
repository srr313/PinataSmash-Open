//
//  SplashScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/21/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screen.h"

@interface SplashScreen : Screen {
    float   totalTimeElapsed;
    float   delay;
    SEL     selector;   
    id      responder;
    ImageControl* splashImage;
    eTexture texture;
}

-(id)initWithFlowManager:(id<FlowManager>)fm andImage:(eTexture)tex andDelay:(float)d;
-(void)setResponder:(id)resp andSelector:(SEL)sel;

@end
