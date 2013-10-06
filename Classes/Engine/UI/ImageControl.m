//
//  ImageControl.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/14/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import "Screen.h"
#import "EAGLView.h"
#import "FlowManager.h"
#import "Localize.h"
#import "JiggleAnimation.h"
#import "Sounds.h"

@implementation ImageControl

@synthesize tiled;

-(Boolean)processEvent:(TapEvent)evt {
    return [super processEvent:evt];
}
-(id)initAt:(Vector2D)pos withTexture:(eTexture)tex {
    if (self == [super init]) {
        position = pos;
        basePosition = pos;
        dimensions = GetTextureDimensions(tex);
        texture = tex;
        jiggling = false;
        tiled = false;
        scrolling = 0.0f;
    }
    return self;
}

- (void)tick:(float)timeElapsed {
    if (!visible) {
        return;
    }

    [super tick:timeElapsed];
    if (tiled) {
        scrolling += 0.025f*timeElapsed;
    }
}

- (void)render:(float)timeElapsed {        
    if (!tiled) {
        [super render:timeElapsed];
    }
    else {
        if (!visible) {
            return;
        }

        Texture2D* renderTexture = [self getLocalTexture2D];
        if (renderTexture == nil && texture != kTexture_Null) {
            renderTexture = GetTexture(texture);
        }
    
        Color3D controlColor = [self color];

        if (renderTexture != nil) {                    
            glLoadIdentity();
            glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
            glScalef(scale, scale, 1.0f);
            glRotatef(angle, 0.0f, 0.0f, 1.0f);
            glColor4f(controlColor.red, controlColor.green, controlColor.blue, controlColor.alpha);
            [renderTexture drawWithTexOffset:CGPointMake(scrolling, 0.0f)];    
        }
            
        for (ScreenControl* child in children) {
            [child render:timeElapsed];
        }    
    }
}

@end
