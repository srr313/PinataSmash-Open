//
//  Parachute.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/31/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "Parachute.h"
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "GameParameters.h"
#import "Particles.h"
#import "Sounds.h"

#define PARACHUTE_RISE_ACCEL             400.0f
#define PARACHUTE_MIN_ANGULAR_VELOCITY   5.0f
#define PARACHUTE_MAX_ANGULAR_VELOCITY   15.0f

@implementation Parachute

@synthesize position, velocity, angle, alive, cargoOffset;

-(id)initAt:(Vector2D)p withTexture:(eTexture)tx forGame:(Game*)g {
    if (self == [super init]) {
        tex = tx;
        position = p;
        velocity = Vector2DMake(0.0f,-GAME_PARAMETERS.parachuteFallSpeed);
        cargoOffset = 0.65f*GetImageDimensions(tex).y;
        angularVelocity = PARACHUTE_MIN_ANGULAR_VELOCITY;
        alive = true;
        game = g;
    }
    return self;
}

-(Boolean)isInside:(CGPoint)p {
    Vector2D dim = GetImageDimensions(tex);
    return fabsf(p.x-position.x) <= dim.x/2 &&
           fabsf(p.y-position.y) <= dim.y/2;
}

-(void)tick:(float) timeElapsed {
    if (!alive) {
        return;
    }
    
    angularVelocity -= timeElapsed;
    angularVelocity = fminf( fmaxf(angularVelocity, PARACHUTE_MIN_ANGULAR_VELOCITY), PARACHUTE_MAX_ANGULAR_VELOCITY);
    t += angularVelocity*timeElapsed;
    angle = 0.15f*M_PI*sinf(t)-M_PI;
    
    if (!cargo) {
        velocity.y += PARACHUTE_RISE_ACCEL * timeElapsed;
        alive = (position.y < 1.1f*GetGLHeight());
    }
    
    position = Vector2DAdd(position, Vector2DMul(velocity, timeElapsed));
}

-(Boolean)trigger {
    [PARTICLE_MANAGER createHitAt:position];
    [PARTICLE_MANAGER createConfettiAt:position
                                withAmount:15 
                                withLayer:kLayer_Game]; 
                                
    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_BalloonPop)];       
                                                        
    [cargo remove:self];
    alive = false;
    return true;
}

-(void)attatch:(id<ParachuteCargo>)c {
    NSAssert(!cargo,@"Parachute::attatch - cargo already attatched!");
    cargo = c;
}

-(void)releaseCargo {
    cargo = nil;
    velocity.y = 0.0f;
}

-(void)addForce:(Vector2D)force {
    float strength = Vector2DMagnitude(force);
    float torque = 0.3f*strength;
    angularVelocity = torque;
    velocity = Vector2DAdd(velocity, Vector2DMake(force.x,0.0f));
}

-(void)render:(float)timeElapsed {
    if (!alive) {
        return;
    }

    Texture2D* texture = GetTexture(tex);
    
    if (IsGameShadowsEnabled()) {
        Vector2D shadowOffset = [ES1Renderer shadowOffset];
        Color3D shadowColor = [game shadowColor];
    
        // render shadow
        glLoadIdentity();        
        glTranslatef(   ToScreenScaleX(position.x+shadowOffset.x), 
                        ToScreenScaleY(position.y+shadowOffset.y), 0.0f);
        glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, shadowColor.alpha); 
        [texture draw];        
    }
    
    if (IsGameMotionBlurEnabled()) {
        // motion blur
        glLoadIdentity();
        glTranslatef(   ToScreenScaleX(position.x-2.0f*timeElapsed*velocity.x), 
                        ToScreenScaleY(position.y-2.0f*timeElapsed*velocity.y), 0.0f);
        glColor4f(1.0f, 1.0f, 1.0f, 0.75f*Vector2DMagnitude(velocity)/GAME_PARAMETERS.maxPinataSpeed);
        [texture draw];    
    }

    
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);      
    glColor4f(1.0f,1.0f,1.0f,1.0f); 
    [texture draw]; 
}

@end
