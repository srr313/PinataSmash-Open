//
//  GameLevel.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/14/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameCommon.h"
#import "OpenGLCommon.h"
#import "Localize.h"
#import "Pinata.h"
#import "Powerup.h"

@class Game;
@class GroupLoad;
@class Spawner;

//////////////////////////////////////

typedef enum {
    kGameRule_Time,
    kGameRule_Shots,
} eGameMetric;

@interface GameRule : NSObject
{
    NSComparisonResult comparison;
    eGameMetric metric;
    int gold;
    int silver;  
    int bronze;
}
@property (nonatomic, readonly) int gold;
@property (nonatomic, readonly) int silver;
@property (nonatomic, readonly) int bronze;
@property (nonatomic, readonly) eGameMetric metric;
-(id)initWithGroup:(GroupLoad*)group;
-(eAchievement)evaluate:(Game*)game;
-(eAchievement)getMedalForMetric:(int)metricValue;
@end

//////////////////////////////////////

@interface GameMessage : NSObject {
    eLocalizedString    text;
    NSMutableArray*     images;
    float               delay;
}
-(id)initText:(eLocalizedString)t andDelay:(float)d;
@property (nonatomic, assign) eLocalizedString text;
@property (nonatomic, assign) NSMutableArray* images;
@property (nonatomic) float delay;
@end

//////////////////////////////////////

@interface GameLevel : NSObject {
    Game* game;
    NSMutableArray* spawners;
    NSMutableArray* messages;
    NSMutableArray* tutorials;
    int initialCandy;
    float consumeAmount;
    float consumeDelay;
    Boolean displayCurrencyTip;
    int candyRequired;
    int currentMessage; 
    int currentTutorial; 
    eAchievement achievement;
    NSString* uniqueID;
    NSString* title;
    GameRule* rule;
}

@property (nonatomic) int initialCandy;
@property (nonatomic) int candyRequired;
@property (nonatomic) float consumeAmount;
@property (nonatomic) float consumeDelay;
@property (nonatomic) Boolean displayCurrencyTip;
@property (nonatomic) eAchievement achievement;
@property (nonatomic, copy) NSString* uniqueID;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, assign) GameRule* rule;

+(GameLevel*)loadLevel:(NSString*)levelStr;

-(id)initWithGame:(Game*)game;
-(void)tick:(float)timeElapsed;
-(void)addSpawner:(Spawner*)spawner;
-(void)addMessage:(GameMessage*)message;
-(eLocalizedString)nextMessage;
-(Boolean)isNextMessageReady:(float)timeElapsed;
-(void)addTutorialMessage:(GameMessage*)message;
-(Boolean)isNextTutorialMessageReady:(float)timeElapsed;
-(GameMessage*)nextTutorialMessage;
-(void)reset:(Game*)g;
-(void)dealloc;
@end

