//
//  PullCord.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/25/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import "PullCord.h"
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "GameParameters.h"
#import "Particles.h"

#define PULL_CORD_GRAB_PADDING 16.0f

@implementation PullCord

@synthesize position, velocity, angle, alive, locked;

-(id)initForPinata:(Pinata*)ent forGame:(Game*)g {
    if (self == [super init]) {
        pinata = ent;
        [pinata retain];
        
        position    = ent.position;
        velocity    = ZeroVector();
        game        = g;
        alive       = true;
        stretched   = false;
    }
    return self;
}

-(void)dealloc {
    [pinata release];
    [super dealloc];
}

-(Boolean)isInside:(CGPoint)p {
    Vector2D dim = GetImageDimensions(kTexture_PullCordHandle);    
    return fabsf(p.x-position.x) <= dim.x/2+PULL_CORD_GRAB_PADDING &&
           fabsf(p.y-position.y) <= dim.y/2+PULL_CORD_GRAB_PADDING;    
}

-(void)tick:(float) timeElapsed {
    if (!alive) {
        return;
    }
    
    Vector2D delta = Vector2DSub(pinata.position, position);    
    if (!locked) {
        float handleOffset = 32.0f;
        float length = Vector2DMagnitude(delta);
        float offset = length-handleOffset;    
        Vector2DNormalize(&delta);
        
        Vector2D springForce = Vector2DMul(delta, 25.0f*offset);
        velocity = Vector2DAdd(velocity, springForce);
        position = Vector2DAdd(position, Vector2DMul(velocity, timeElapsed));
        
        if (stretched && length < 2.0f*handleOffset) {
            
            pinata.triggeredByPullCord = true;        
            [pinata addForce:Vector2DMul(velocity, 10.0f)];
            [pinata bounce];                        
            stretched = false;
            
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_BungeeHit)];                                                                    
        }
        
        // dampen to control movement
        velocity = Vector2DMul(velocity, -0.25f);
    }
    
    angle = atan2f(delta.y,delta.x) + M_PI_2;
}

-(Boolean)trigger {
//    alive = false;
    return true;
}

-(void)setLocked:(Boolean)flag {
    locked = flag;
    
    if (locked) {
        [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_BungeePull)];    
    }
    
    stretched = (!locked && Vector2DDistance(pinata.position, position)>96.0f);                              
}

-(void)addForce:(Vector2D)force {
}

-(void)render:(float)timeElapsed {
    if (!alive) {
        return;
    }
    
    Vector2D delta = Vector2DSub(position, pinata.position);
    Vector2D center = Vector2DAdd(pinata.position, Vector2DMul(delta, 0.5f));
    float length = Vector2DMagnitude(delta);
    float offset = length / GetGLHeight();
    float stretchFade = 0.5f*(2.0f-offset);
                
    Texture2D* bungeeTexture = GetTexture(kTexture_Bungee);
    Texture2D* handleTexture = GetTexture(kTexture_PullCordHandle);

    float scaleX = 1.0f;        
    float scaleY = length/ToGameScaleX(bungeeTexture.pixelsHigh);
    
    if (IsGameShadowsEnabled()) {
        Vector2D shadowOffset = [ES1Renderer shadowOffset];
        Color3D shadowColor = [game shadowColor]; 

        glLoadIdentity();        
        glTranslatef(ToScreenScaleX(center.x+shadowOffset.x), ToScreenScaleY(center.y+shadowOffset.y), 0.0f);
        glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);        
        glScalef(scaleX, scaleY, 1.0f);
        glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, shadowColor.alpha); 
        [bungeeTexture drawWithTexScale:CGPointMake(1.0f, scaleY)];    
        
        glLoadIdentity();        
        glTranslatef(ToScreenScaleX(position.x+shadowOffset.x), ToScreenScaleY(position.y+shadowOffset.y), 0.0f);
        glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);
        glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, shadowColor.alpha); 
        [handleTexture draw];    
    }
    
    if (IsGameMotionBlurEnabled()) {
        float blurAlpha = 0.75f*Vector2DMagnitude(velocity)/GAME_PARAMETERS.maxPinataSpeed;
        if (blurAlpha > 0.1f) {
            glLoadIdentity();
            glTranslatef(   ToScreenScaleX(center.x-0.3f*timeElapsed*velocity.x), 
                            ToScreenScaleY(center.y-0.3f*timeElapsed*velocity.y), 0.0f);
            glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);            
            glScalef(scaleX, scaleY, 1.0f);          
            glColor4f(1.0f, 1.0f, 1.0f, stretchFade*blurAlpha);
            [bungeeTexture drawWithTexScale:CGPointMake(1.0f, scaleY)];          

            glLoadIdentity();
            glTranslatef(   ToScreenScaleX(position.x-0.3f*timeElapsed*velocity.x), 
                            ToScreenScaleY(position.y-0.3f*timeElapsed*velocity.y), 0.0f);
            glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);
            glColor4f(1.0f, 1.0f, 1.0f, blurAlpha);
            [handleTexture draw];  
        }
    }
    
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(center.x), ToScreenScaleY(center.y), 0.0f);
    glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);    
    glScalef(scaleX, scaleY, 1.0f);
    glColor4f(1.0f, 1.0f, 1.0f, stretchFade);
    [bungeeTexture drawWithTexScale:CGPointMake(1.0f, scaleY)];         
    
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
    glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    [handleTexture draw];     
}

@end
