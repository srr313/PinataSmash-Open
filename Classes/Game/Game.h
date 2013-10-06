//
//  Game.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameCommon.h"
#import "GameLevel.h"
#import "OpenGLCommon.h"
#import "Screen.h"

#define MAX_ENERGY                  500.0f
#define CANDY_TO_VFX_RATIO          0.35f
#define VEGETABLE_TO_VFX_RATIO      0.35f

#define LEVEL_END_DURATION      3.5f
#define LEVEL_END_EXPLODE       1.5f

@class Candy;
@class CandyPile;
@class ESRenderer;
@class LevelEnvironment;
@class ParticleManager;
@class Pinata;
@class Powerup;
@class EAGLView;
@class Kid;
@class GameScreen;
@class GameLevel;
@class PullCord;
@class Tool;
@class WeatherCloud;

typedef enum {
    kGameState_Play,
    kGameState_Win,
    kGameState_Loss,
} eGameState;

typedef enum {
    kLevelEndReason_Win,
    kLevelEndReason_NoCandy,
    kLevelEndReason_NoTime,
    kLevelEndReason_NoHits,    
} eLevelEndReason;

@interface Game : NSObject {
@private
    NSMutableArray* pinatas;
    NSMutableArray* powerups;
    NSMutableArray* parachutes;      
    NSMutableArray* candyPieces;
    float           labWidth;
    float           labHeight;
    float           levelTime;
    GameLevel*      gameLevel;
    int             level;
    NSString*       episodePath;
    int             totalCandyCollected;
    CandyPile*      candyPile;
    EAGLView*       view;
    GameScreen*     screen;
    int             metricBonusAwarded;
    int             bonusCount;
    int             multiplier;
    Color3D         multiplierColor;
    float           multiplierTime;
    float           pinataScale;
    float           pinataScaleTarget;
    float           pinataScaleTimePassed;
    float           pinataScaleDuration;
    ePinataBehavior pinataScaleBehavior;
    eGameState      gameState;
    float           levelEndDelay;
    Boolean         sugarHighMode;
    float           sugarHighTime;
    float           sugarHighDistance;
    Boolean         sugarRushMode;
    float           sugarRushTime;
    Boolean         rainMode;
    float           rainTime;
    Tool*           tool;
    eLevelEndReason levelEndReason;
    LevelEnvironment* levelEnvironment;    
    float           shadowLerp;
    Color3D         shadowColor;
    Color3D         startShadowColor;
    Color3D         endShadowColor;
    Kid*            kid;
    WeatherCloud*   cloud;
}

@property (nonatomic) float labWidth;
@property (nonatomic) float labHeight;
@property (nonatomic,readonly) int totalCandyCollected;
@property (nonatomic, assign) GameScreen* screen;
@property (nonatomic) int level;
@property (nonatomic, assign) NSString* episodePath;
@property (nonatomic, assign) GameLevel* gameLevel;
@property (nonatomic) int multiplier;
@property (nonatomic) Color3D multiplierColor;
@property (nonatomic) float levelTime;
@property (nonatomic) int metricBonusAwarded;
@property (nonatomic,assign) Tool* tool;
@property (nonatomic, readonly) Color3D shadowColor;
@property (nonatomic, assign) LevelEnvironment* levelEnvironment;
@property (nonatomic) Boolean tutorialMode;
@property (nonatomic) float levelEndDelay;
@property (nonatomic) Boolean sugarHighMode;
@property (nonatomic) Boolean sugarRushMode;
@property (nonatomic) float sugarHighTime;
@property (nonatomic,assign) WeatherCloud* cloud;

-(id)initWithWidth:(float)w 
        andHeight:(float)h 
        andView:(EAGLView*)v;
-(NSMutableArray*)getPinatas;
-(NSMutableArray*)getPowerups;
-(NSMutableArray*)getParachutes;
-(NSMutableArray*)findPinatasNear:(Vector2D)v withinDistance:(float)d;
-(Pinata*)findNearestPinata:(Vector2D)v;
-(void)simUpdate:(float)timeElapsed;
-(void)triggerAt:(TapEvent)tapEvent;
-(Boolean)triggerGameEntsAt:(TapEvent)tapEvent andDealDamage:(int)damage;
-(void)triggerCandyAt:(TapEvent)tapEvent;
-(void)swooshAt:(Vector2D)v;
-(void)resetMultiplier;
-(void)explosionAt:(Vector2D)position andRadius:(float)radius andForce:(float)force;
-(void)repelAllGameEntsAt:(Vector2D)v withStrength:(float)strength;
-(void)repelGameEnts:(NSMutableArray*)ents at:(Vector2D)v withStrength:(float)strength;
-(CandyPile*)getCandyPile;
-(void)addCandy:(int)amount useMultiplier:(Boolean)useMult;
-(void)spawnCandyPieces:(int)n atPosition:(Vector2D)p;
-(void)setSimulationSpeed:(float)speed withDuration:(float)duration;
-(float)levelCompletion;
-(void)setPinataScale:(float)scale withPinataBehavior:(ePinataBehavior)behavior withDuration:(float)duration;
-(void)setLevel:(int)lvl inEpisode:(NSString*)episodePath;
-(void)setToolType:(eTool)t;
-(void)addMetricBonus:(int)amount atPosition:(Vector2D)position;
-(eAchievement)getMedalEarned;
-(eAchievement)getMedalForMetric:(int)metricValue;
-(int)getMedalCash;
-(void)awardMedal;
-(void)retryLevel;
-(void)nextLevel;
-(void)render:(float)timeElapsed;
-(eLevelEndReason)levelEndReason;
-(void)displayMessage:(NSString*)message;
-(void)setSugarHighMode:(Boolean)flag;
-(void)setSugarRushMode:(Boolean)flag;
-(PullCord*)getPullCordAt:(TapEvent)tapEvent;
-(void)shake;
-(void)setRainMode:(Boolean)flag;
-(int)gameTime;
-(void)vibrate;
@end
