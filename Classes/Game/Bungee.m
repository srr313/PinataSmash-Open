//
//  Parachute.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/31/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "Bungee.h"
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "GameParameters.h"
#import "Particles.h"

@implementation Bungee

@synthesize position, velocity, angle, alpha, alive, cargoPosition;

-(id)initAt:(Vector2D)p forGame:(Game*)g {
    if (self == [super init]) {
        position = p;
        velocity = ZeroVector();
        cargoPosition = p;
        angularVelocity = 0.0f;
        game = g;
        alive = true;
        alpha = 1.0f;
    }
    return self;
}

-(Boolean)isInside:(CGPoint)p {
    return false;
}

-(void)tick:(float) timeElapsed {
    if (!alive) {
        return;
    }

    Vector2D delta = Vector2DSub(cargoPosition, position);
    float length = Vector2DMagnitude(delta);
    float offset = length / GetGLHeight();    
    Vector2DNormalize(&delta);
    
    if (length > 0.1f) {
        angle = atan2f(delta.y, delta.x) + M_PI_2;
    }

    Vector2D springForce = Vector2DMul(delta, -100.0f*offset);
    velocity = Vector2DAdd(velocity, springForce);
    
    Vector2D gravity = Vector2DMake(0.0f,-GAME_PARAMETERS.bungeeFallSpeed);
    velocity = Vector2DAdd(velocity, gravity);

    // clamp speed
    if (Vector2DMagnitude(velocity) > GAME_PARAMETERS.maxPinataSpeed+1.0f) {
        Vector2DNormalize(&velocity);
        velocity = Vector2DMul(velocity, GAME_PARAMETERS.maxPinataSpeed);
    }

    cargoPosition = Vector2DAdd(cargoPosition, Vector2DMul(velocity, timeElapsed));
}

-(Boolean)trigger {
    [cargo removeCord:self];
    alive = false;
    return true;
}

-(void)attatch:(id<BungeeCargo>)c {
    NSAssert(!cargo,@"Bungee::attatch - cargo already attatched!");
    cargo = c;
}

-(void)addForce:(Vector2D)force {
    velocity = Vector2DAdd(velocity, Vector2DMake(50.0f*force.x,0.0f));
}

-(void)render:(float)timeElapsed {
    if (!alive) {
        return;
    }

    glLoadIdentity();

    Vector2D delta = Vector2DSub(position, cargoPosition);
    float length = Vector2DMagnitude(delta);
    float offset = length / GetGLHeight();
    float stretchFade = 0.5f*(2.0f-offset);
                
    Texture2D* texture = GetTexture(kTexture_Bungee);

    float scaleX = 1.0;        
    float scaleY = 2.0f * length/ToGameScaleX(texture.pixelsHigh);
    
    if (IsGameShadowsEnabled()) {
        Vector2D shadowOffset = [ES1Renderer shadowOffset];
        Color3D shadowColor = [game shadowColor];        
    
        // render shadow
        glLoadIdentity();        
        glTranslatef(ToScreenScaleX(position.x+shadowOffset.x), ToScreenScaleY(position.y+shadowOffset.y), 0.0f);
        glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);
        glScalef(scaleX, scaleY, 1.0f);
        glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, alpha*shadowColor.alpha); 
        [texture drawWithTexScale:CGPointMake(1.0f, scaleY)];    
    }
    
    if (IsGameMotionBlurEnabled()) {
        float blurAlpha = 0.75f*Vector2DMagnitude(velocity)/GAME_PARAMETERS.maxPinataSpeed;
        if (blurAlpha > 0.1f) {
            // motion blur
            glLoadIdentity();
            glTranslatef(   ToScreenScaleX(position.x-0.3f*timeElapsed*velocity.x), 
                            ToScreenScaleY(position.y-0.3f*timeElapsed*velocity.y), 0.0f);
            glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);
            glScalef(scaleX, scaleY, 1.0f);
            glColor4f(1.0f, 1.0f, 1.0f, alpha*stretchFade*blurAlpha);
            [texture drawWithTexScale:CGPointMake(1.0f, scaleY)];          
        }
    }
    
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
    glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);
    glScalef(scaleX, scaleY, 1.0f);
    glColor4f(1.0f, 1.0f, 1.0f, alpha*stretchFade);
    [texture drawWithTexScale:CGPointMake(1.0f, scaleY)];         
}

@end
