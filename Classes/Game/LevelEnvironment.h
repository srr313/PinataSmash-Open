//
//  LevelEnvironment.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/18/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESRenderer.h"
#import "GameCommon.h"
#import "JiggleAnimation.h"

typedef enum {
    kLevelEnvironment_Title = 0,
    kLevelEnvironment_Episode1,
    kLevelEnvironment_Episode2,
    kLevelEnvironment_Episode3,        
} eLevelEnvironment;

@class ParticleManager;

@interface LevelEnvironment : NSObject {
    eTexture            backLayer;
    eTexture            frontLayer;
    float               layerScrolling;
    ParticleManager*    particleManager;
    eLevelEnvironment   environment;
    float               happyLevel;
    float               timeForNextBalloon;
    float               timeForNextCandy;
    float               timeForNextExplosion;
    float               backgroundFlashT;
    Boolean             effectsEnabled;
    Color3D             flashColor;
    Game*               game;
    JiggleAnimation*    jiggler;
}

@property (nonatomic) float happyLevel;
@property (nonatomic) Boolean effectsEnabled;
@property (nonatomic,assign) Game* game;

-(id)initWithEnvironment:(eLevelEnvironment)env;
-(void)dealloc;
-(void)tick:(float)timeElapsed;
-(void)render:(float)timeElapsed;
-(void)jiggleBackground;
-(void)flashBackground:(Color3D)color;
-(void)resetFlash;

@end
