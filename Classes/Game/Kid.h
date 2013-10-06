//
//  Kid.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/5/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameEntity.h"

#define KID_STAGES          5

@class Game;
@class JiggleAnimation;

@class ImageControl;
@class TextControl;

@interface Kid : NSObject<GameEntity> {
    Vector2D position;
    float   scale;
    
    int     currentStage;
    int     currentFramesElapsed;
    int     currentFrameDuration;
    int     currentKidFrame;
    int     targetFrame;
    
    Boolean alive;
    JiggleAnimation* hitJiggle;
    float   lastHitTime;
    float   timeSinceWarning;
    float   timeSinceCheer;
    Boolean postedRuleMessage;
    Boolean startedExpansion;
    float   lastCandy;
    Boolean sugarRush;
    Boolean sugarHigh;
    float   sugarHighPulse;
    float   spinTime;
    float   velocity;
    float   acceleration;
    float   jumpHeight;
    Boolean jumped;
    Boolean startAnimation;
    Game*   game;
    
    TextControl*    simpleText;
    ImageControl*   simpleTextBackground;    
}

@property (nonatomic) Boolean alive;
@property (nonatomic,readonly) int currentStage;
@property (nonatomic,readonly) Boolean jumped;

-(id)initForGame:(Game*)g;
-(void)tick:(float)timeElapsed;
-(void)render:(float)timeElapsed;
-(Boolean)isInside:(CGPoint)p;
-(Boolean)trigger;
-(void)addForce:(Vector2D)force;
-(void)explode;
-(void)setSugarRush:(Boolean)flag;
-(void)setSugarHigh:(Boolean)flag;
-(void)nextStage;
-(void)jump;

@end
