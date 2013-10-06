//
//  LevelEnvironment.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/18/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "LevelEnvironment.h"
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "Particles.h"
#import "Sounds.h"

#define BACKGROUND_JIGGLE_AMP 0.05f
//#define DRAW_BACKGROUND_SHADOW
//#define USE_FOREGROUND_LAYER

@implementation LevelEnvironment

@synthesize happyLevel, game, effectsEnabled;

-(id)initWithEnvironment:(eLevelEnvironment)env {
    if (self = [super init]) {
        environment = env;
        switch (environment) {
        case kLevelEnvironment_Episode1:
            backLayer = kTexture_PlaygroundBack;
//            frontLayer = kTexture_OutdoorsFront;
            break;
        case kLevelEnvironment_Episode2:
            backLayer = kTexture_ZooBack;
//            frontLayer = kTexture_OutdoorsFront;
            break;
        case kLevelEnvironment_Episode3:
            backLayer = kTexture_CircusBack;
//            frontLayer = kTexture_OutdoorsFront;
            break;        
        default:
        case kLevelEnvironment_Title:
            backLayer = kTexture_TitleBackground;
//            frontLayer = kTexture_OutdoorsFront;
            break;
        }

        effectsEnabled = false;
        happyLevel = 0.0f;
        layerScrolling = 0.0f;
        backgroundFlashT = 0.0f;
        particleManager = [[ParticleManager alloc] init];
        jiggler = [[JiggleAnimation alloc] init];
    }
        
    return self;
}

-(void)tick:(float)timeElapsed {
    [particleManager tick:timeElapsed];
    [jiggler tick:timeElapsed];
    
    if (effectsEnabled) {
        timeForNextCandy -= timeElapsed;
        if (timeForNextCandy <= 0.0f) {
            timeForNextCandy = 1.0f-happyLevel;
            
            Particle* p = [particleManager
                                NewParticleAt:Vector2DMake( GetGLWidth()*rand()/(float)RAND_MAX,
                                                            GetGLHeight()+32.0f)
                                    andVelocity:Vector2DMake(0.0f,-30.0f) 
                                    andAngle:TWO_PI*random()/RAND_MAX 
                                    andScaleX:0.5f 
                                    andScaleY:0.5f 
                                    andColor:COLOR3D_WHITE
                                    andTotalLifetime:1.0f+rand()/(float)RAND_MAX 
                                    andType:kParticleType_Candy
                                    andTexture:kTexture_CandyBegin+rand()%(kTexture_CandyEnd-kTexture_CandyBegin)];
            p.layer = kLayer_Game;
            [particleManager addParticle:p];
            [p release];
        }     
        
        timeForNextBalloon -= timeElapsed;
        if (timeForNextBalloon <= 0.0f && happyLevel > 0.0f) {
            timeForNextBalloon = 1.0f-happyLevel;
            
            Particle* p = [particleManager
                                NewParticleAt:Vector2DMake( GetGLWidth()*rand()/(float)RAND_MAX,
                                                            0.5f*GetGLHeight()*rand()/(float)RAND_MAX)
                                    andVelocity:Vector2DMake(0.0f,150.0f) 
                                    andAngle:0.0f
                                    andScaleX:0.5f 
                                    andScaleY:0.5f 
                                    andColor:Color3DMake(1.0f,1.0f,1.0f, 0.0f)
                                    andTotalLifetime:3.0f 
                                    andType:kParticleType_Balloon
                                    andTexture:kTexture_BalloonBegin+rand()%(kTexture_BalloonEnd-kTexture_BalloonBegin)];
            p.layer = kLayer_Game;
            [particleManager addParticle:p];
            [p release];
        } 
        
        timeForNextExplosion -= timeElapsed;
        if (timeForNextExplosion <= 0.0f && happyLevel > 0.0f) {            
            timeForNextExplosion = 1.0f-happyLevel;
            
            Vector2D fireworkPosition = 
                Vector2DMake(   GetGLWidth()*rand()/(float)RAND_MAX,
                                GetGLHeight()*rand()/(float)RAND_MAX);                
                                
            [particleManager createSparkAt:fireworkPosition
                            withAmount:8 
                            withColor:Color3DMake(rand()/(float)RAND_MAX, rand()/(float)RAND_MAX, rand()/(float)RAND_MAX, 0.0f)
                            withSpeed:40.0f 
                            withScale:1.0 
                            withLayer:kLayer_Game];
        } 
    }
    
    if (backgroundFlashT > 0.0f) {
        backgroundFlashT += 4.0f*timeElapsed;
        if (backgroundFlashT > 1.0f) {
            backgroundFlashT = 0.0f;
        }
    }
    
    #ifdef USE_FOREGROUND_LAYER
        layerScrolling += 0.025f*timeElapsed;
    #endif
}

-(void)render:(float)timeElapsed {
    float halfWidth = ToScreenScaleX(GetGLWidth()/2);
    float halfHeight = ToScreenScaleY(GetGLHeight()/2); 

    {
        glDisable(GL_BLEND);    
        glLoadIdentity();    
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
        glTranslatef(halfWidth, halfHeight,0.0f);
        
        glScalef(1.0f+fabsf(jiggler.scale-1.0f), 1.0f+fabsf(jiggler.scale-1.0f), 1.0f);        
        
        [GetTexture(backLayer) drawWithTexOffset:CGPointMake(layerScrolling, 0.0f)];    
        glEnable(GL_BLEND);                                        
    }
    
    [particleManager renderParticles:timeElapsed inLayer:kLayer_Game];
        
    if (backgroundFlashT > 0.0f) {    
        glLoadIdentity();    
        glColor4f(flashColor.red, flashColor.green, flashColor.blue, sinf(M_PI*backgroundFlashT));
        glTranslatef(halfWidth, halfHeight,0.0f);        
        glScalef( 2.0f*halfWidth/GetTextureDimensions(kTexture_White).x
                , 2.0f*halfHeight/GetTextureDimensions(kTexture_White).y
                , 1.0f);
        [GetTexture(kTexture_White) draw];                              
    }
           
    #ifdef DRAW_BACKGROUND_SHADOW AND USE_FOREGROUND_LAYER
        if (!IsDeviceIPad() && GetDisplayMode() != kRetina) {
            #define BACKGROUND_DEPTH 2.0f
            Vector2D shadowOffset = [ES1Renderer shadowOffset];
            Color3D shadowColor = game ? [game shadowColor] : Color3DMake(0.0f, 0.0f, 0.0f, 0.4f);
        
            // render shadow
            glLoadIdentity();        
            glTranslatef(BACKGROUND_DEPTH*shadowOffset.x, BACKGROUND_DEPTH*shadowOffset.y, 0.0f);
            glScalef(jiggler.scale+BACKGROUND_JIGGLE_AMP, jiggler.scale+BACKGROUND_JIGGLE_AMP, 1.0f);        
            glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, shadowColor.alpha); 
            glTranslatef(halfWidth, halfHeight,0.0f);                                
            [GetTexture(frontLayer) draw];     
        }
    #endif

    #ifdef USE_FOREGROUND_LAYER
        glLoadIdentity();    
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
        glScalef(jiggler.scale+BACKGROUND_JIGGLE_AMP, jiggler.scale+BACKGROUND_JIGGLE_AMP, 1.0f);
        glTranslatef(halfWidth, halfHeight,0.0f);                        
        [GetTexture(frontLayer) draw];    
    #endif
}

-(void)jiggleBackground {
    [jiggler stop];
    [jiggler jiggleFreq:7.5f andAmplitude:BACKGROUND_JIGGLE_AMP andDuration:1.0f];
}

-(void)flashBackground:(Color3D)color {
    backgroundFlashT = 0.001f;
    flashColor = color;
}

-(void)resetFlash {
    backgroundFlashT = 0.0f;
}

-(void)dealloc { 
    [jiggler release];
    [particleManager release];
    [super dealloc];
}

@end
