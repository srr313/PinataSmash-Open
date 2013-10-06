//
//  CandyPile.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/19/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameCommon.h"

@class Game;
@class JiggleAnimation;

@interface CandyPile : NSObject {
    int numCandy;
    int candyCollected;
    int targetAmount;
    float consumptionDelay;
    float consumptionAmount;
    float candyConsumed;
    float timeSinceLastConsumption;
    JiggleAnimation* addJiggler;
    JiggleAnimation* remJiggler;
    Game* game;
    Vector2D position;
}

@property (nonatomic) int numCandy;
@property (nonatomic) int candyCollected;
@property (nonatomic) float consumptionDelay;
@property (nonatomic) float consumptionAmount;
@property (nonatomic) float candyConsumed;
@property (nonatomic) Vector2D position;

-(id)initWithCandy:(int)candy 
        andTarget:(int)target
        andConsumptionDelay:(float)delay 
        andConsumptionAmount:(float)amount 
        forGame:(Game*)g;
-(void)addCandy:(int)amount;
-(int)getCandy;
-(float)getForegroundHeight;
-(float)getBaseScale;
-(float)getJiggleScale;
-(float)getConsumptionScale;
-(void)tick:(float)timeElapsed;
-(void)renderForeground:(float)timeElapsed;
-(void)renderBackground:(float)timeElapsed;
-(void)bounce;
@end
