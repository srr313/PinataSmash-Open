//
//  Game.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

//#define USE_RUMBLE

#ifdef USE_RUMBLE
    #import <AudioToolbox/AudioToolbox.h>
#endif

#import "Game.h"
#import "Candy.h"
#import "CandyPile.h"
#import "EAGLView.h"
#import "ESRenderer.h"
#import "GameCommon.h"
#import "GameLevel.h"
#import "GameParameters.h"
#import "GameScreen.h"
#import "Kid.h"
#import "LevelEnvironment.h"
#import "LevelLoader.h"
#import "Localize.h"
#import "MetagameManager.h"
#import "Particles.h"
#import "Pinata.h"
#import "Powerup.h"
#import "PullCord.h"
#import "SaveGame.h"
#import "Sounds.h"
#import "Tool.h"
#import "WeatherCloud.h"

#ifdef DO_ANALYTICS
    #import "FlurryAPI.h"
#endif    

#define MULTIPLIER_MAX_TIME     2.0f

//#define CYCLE_GAME_SHADOW_COLOR

@interface Game()
-(void)onLevelVictory;
-(void)onLevelFail;
-(void)updateMultiplier:(float)timeElapsed;
-(void)updateSugarRush:(float)timeElapsed;
-(void)updateSugarHigh:(float)timeElapsed;
-(void)updateRain:(float)timeElapsed;
-(void)updateGameMessages;
-(void)updateLevelEnd:(float)timeElapsed;
-(Boolean)updateLevelState;
-(void)updatePinatas:(float)timeElapsed;
-(void)updatePowerups:(float)timeElapsed;
-(void)updateParachutes:(float)timeElapsed;
-(void)updateCandy:(float)timeElapsed;
-(void)updatePinataScale:(float)timeElapsed;
-(void)loadLevel;
-(void)incrementMultiplier;
-(Boolean)isPlaying;
-(Boolean)isSimulating;
-(void)endGameFlow;
-(void)sugarHighTrail:(TapEvent)tapEvent;
@end

@implementation Game

@synthesize labWidth, labHeight, totalCandyCollected, level, screen, levelEnvironment,
            gameLevel, episodePath, multiplier, multiplierColor, levelTime, metricBonusAwarded,
            tool, shadowColor, tutorialMode, levelEndDelay, sugarHighMode, sugarRushMode, sugarHighTime,
            cloud;

-(id)initWithWidth:(float)w andHeight:(float)h andView:(EAGLView*)v 
{
    if (self == [super init]) {    
        labWidth    = w;
        labHeight   = h;
                
        view = v;
        [v retain];
        
        totalCandyCollected = 0;
                        
        level = -1;
                
        [self resetMultiplier];
        pinataScale         = 1.0f;
        pinataScaleDuration = 0.0f;
        pinataScaleTarget   = 1.0f; 
        
        #ifndef CYCLE_GAME_SHADOW_COLOR
            shadowColor = Color3DMake(0.0f, 0.0f, 0.0f, 0.5f);
        #endif
    }
    return self;
}

-(void)setLevel:(int)lvl inEpisode:(NSString*)episode {
    level       = lvl;
    episodePath = episode;
    [self loadLevel];
    
    gameState = kGameState_Play;
}

-(void)setToolType:(eTool)t {
    [tool release];
    tool = [[Tool alloc] initType:t forGame:self];
    
    [screen setTool:t];
}

-(void)setPinataScale:(float)scale withPinataBehavior:(ePinataBehavior)behavior withDuration:(float)duration {
    pinataScaleTarget       = scale;
    pinataScaleDuration     = duration;
    pinataScaleBehavior     = behavior;    
    pinataScaleTimePassed   = 0.0f;
}

-(void)setSimulationSpeed:(float)speed withDuration:(float)duration {
    [view setSimulationSpeed:speed withDuration:duration];
}

-(Boolean)updateLevelState {
    eAchievement ruleResult = [self getMedalEarned];

    if (candyPile.numCandy <= 0.0f) {
        gameState = kGameState_Loss;
        levelEndReason = kLevelEndReason_NoCandy;
        [self onLevelFail];
        return true;
    }

    if (ruleResult==kAchievement_Failed) {
        gameState = kGameState_Loss;        
        levelEndReason = (gameLevel.rule.metric==kGameRule_Time)
                            ? kLevelEndReason_NoTime
                            : kLevelEndReason_NoHits;
        [self onLevelFail];
        return true;    
    }

    if (candyPile.candyCollected >= gameLevel.candyRequired) {
        gameState = kGameState_Win;
        levelEndReason = kLevelEndReason_Win;
        [self onLevelVictory];
        return true;
    }
    return false;
}
         
-(void)updateMultiplier:(float)timeElapsed {  
    multiplierTime += timeElapsed;
    if (multiplierTime > MULTIPLIER_MAX_TIME) {
        [self resetMultiplier];
    }
}
 
-(void)updateSugarRush:(float)timeElapsed {
    if (sugarRushMode) {
        sugarRushTime += timeElapsed;
        if (sugarRushTime > GAME_PARAMETERS.sugarRushDuration) {
            [self setSugarRushMode:false];
        } 
    }
}

-(void)updateSugarHigh:(float)timeElapsed {
    if (sugarHighMode) {
        sugarHighTime += timeElapsed;
        if (sugarHighTime > GAME_PARAMETERS.sugarHighDuration) {
            [self setSugarHighMode:false];
        } 
    }
}

-(void)updateRain:(float)timeElapsed {
    if (sugarHighMode || !cloud) {
        return;
    }
    
    [cloud tick:timeElapsed];
    
    if (rainMode) {
        rainTime += timeElapsed;        
        if (rainTime > cloud.lifetime) {
            [self setRainMode:false];
        } 
    }
}

-(void)updateGameMessages {
    if ([gameLevel isNextTutorialMessageReady:levelTime]) {
        GameMessage* nextMessage = [gameLevel nextTutorialMessage];
        [screen displayTutorialMessage:nextMessage.text withImages:nextMessage.images];            
    }
    else if ([screen messageDone] && [gameLevel isNextMessageReady:levelTime]) {
        [screen displayMessage:[gameLevel nextMessage]];
    }
}

-(void)updateLevelEnd:(float)timeElapsed {
    if (levelEndDelay >= 0.0f && levelEndDelay <= LEVEL_END_DURATION) {
        levelEndDelay += timeElapsed;
        if (kid.alive && !kid.jumped && levelEndDelay > LEVEL_END_EXPLODE ) {
//            [kid nextStage];
            [kid                jump];
            [self               endGameFlow];
            [screen             hideMessages];
        }
        
        if (levelEndDelay > LEVEL_END_DURATION) {
            [view changeFlowState:kFlowState_LevelEnd];           
        }
    }  
}

-(void)updatePinataScale:(float)timeElapsed {
    if (pinataScaleDuration > 0.0f) {
        if (pinataScaleTimePassed > pinataScaleDuration) {
            pinataScale = 1.0f;
            pinataScaleDuration = 0.0f;
        }
        else {
            pinataScaleTimePassed += timeElapsed;
            float completion = pinataScaleTimePassed / pinataScaleDuration;
            pinataScale = 1.0f + (pinataScaleTarget-1.0f)*sinf(M_PI*completion);
        }
    }
}

-(void)updatePinatas:(float)timeElapsed {
    [self updatePinataScale:timeElapsed];

    NSMutableArray* removedPinatas = [NSMutableArray array];
    int index = 0;
    for (Pinata* pinata in pinatas) {
        [pinata tick:timeElapsed atIndex:index]; 
        if (pinata.numParts <= 0) {
            [removedPinatas addObject:pinata];
            [PINATA_MANAGER ReleasePinata:pinata];
        }
        else if ((pinataScaleBehavior&pinata.behavior)!=0) {
            pinata.scale = pinataScale;
        }
        else {
            pinata.scale = 1.0f;
        }
        ++index;
    }
    [pinatas removeObjectsInArray:removedPinatas];
}

-(void)updatePowerups:(float)timeElapsed {
    NSMutableArray* removedPowerups = [NSMutableArray array];
    for (Powerup* powerup in powerups) {
        [powerup tick:timeElapsed];
        if (!powerup.alive) {
            [removedPowerups addObject:powerup];
        }
    }
    [powerups removeObjectsInArray:removedPowerups];
}

-(void)updateParachutes:(float)timeElapsed {
    NSMutableArray* removedParachutes = [NSMutableArray array];
    for (Parachute* parachute in parachutes) {
        [parachute tick:timeElapsed];
        if (!parachute.alive) {
            [removedParachutes addObject:parachute];
        }
    }
    [parachutes removeObjectsInArray:removedParachutes];
}

-(void)updateCandy:(float)timeElapsed {
    NSMutableArray* removedCandy = [NSMutableArray array];
    for (Candy* candy in candyPieces) {
        [candy tick:timeElapsed];
        if (!candy.alive) {
            [removedCandy addObject:candy];
            [Candy Recycle:candy];
        }
    }
    [candyPieces removeObjectsInArray:removedCandy];
}

-(eAchievement)getMedalEarned {
    GameRule* rule = gameLevel.rule;
    return ([rule evaluate:self]);
}

-(eAchievement)getMedalForMetric:(int)metricValue {
    GameRule* rule = gameLevel.rule;
    return ([rule getMedalForMetric:metricValue]);
}

-(int)getMedalCash {
    eAchievement lastMedal      = [self getMedalEarned];
    eAchievement previousMedal  = MAX(gameLevel.achievement, kAchievement_Bronze-1);
    return MAX(1, (int)(lastMedal-previousMedal));
}

-(void)awardMedal {
    eAchievement earned = [self getMedalEarned];
    if (earned > gameLevel.achievement) {
        [METAGAME_MANAGER awardMedal:earned previousAchievement:gameLevel.achievement];
        gameLevel.achievement = earned;
    }
    [SaveGame saveLevelState:gameLevel];
}

-(void)loadLevel {
    [self resetMultiplier];
    
    [pinatas release];
    pinatas = [[NSMutableArray alloc] init];    

    [parachutes release];
    parachutes = [[NSMutableArray alloc] init];

    [powerups release];
    powerups = [[NSMutableArray alloc] init];

    [candyPieces release];
    candyPieces = [[NSMutableArray alloc] init];
    
    pinataScale             = 1.0f;
    pinataScaleDuration     = 0.0f;
    pinataScaleTimePassed   = 1.0f;
    pinataScaleBehavior     = 0;
    
    gameLevel = [LevelLoader getLevel:level inEpisode:episodePath];
    NSAssert(gameLevel, @"Game::LoadLevel - level is nil");
    
    [gameLevel reset:self];

    bonusCount          = 0;
    metricBonusAwarded  = 0;
    
    [screen setToolCount:0];
    [screen setTimeCount:0];
    [screen setMetric:gameLevel.rule.metric];
    
    levelTime           = 0.0f;
    levelEndDelay       = -1.0f;
    
    tutorialMode    = false;
    sugarHighMode   = false;
    sugarHighTime   = 0.0f;
    sugarHighDistance = 0.0f;
    sugarRushMode   = false;
    rainTime        = 0.0f;
    rainMode        = false;
            
    [candyPile release];
    candyPile = [[CandyPile alloc] 
                    initWithCandy:          gameLevel.initialCandy
                    andTarget:              gameLevel.candyRequired
                    andConsumptionDelay:    gameLevel.consumeDelay
                    andConsumptionAmount:   gameLevel.consumeAmount
                    forGame:self ];

    [kid release];
    kid = [[Kid alloc] initForGame:self ];
    
    [cloud release];
    cloud = [[WeatherCloud alloc] initForGame:self ];
                                        
    levelEnvironment = [[LevelEnvironment alloc] initWithEnvironment:(kLevelEnvironment_Episode1+view.episodeIndex)];
    levelEnvironment.game = self;
    
    [self setSimulationSpeed:1.0f withDuration:FLT_MAX];
    
    [screen setLevelText:gameLevel.title];
    
    [Pinata resetComment];
}

-(void)onLevelFail {
#ifdef DO_ANALYTICS
    [FlurryAPI logEvent:@"GAMEOVER"];
#endif    

    [view changeFlowState:kFlowState_Gameover];
    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Gameover)];
    
    [self setSimulationSpeed:1.0f withDuration:FLT_MAX];
    [levelEnvironment   resetFlash];    
    sugarHighMode = false;    
}

-(void)onLevelVictory {
#ifdef DO_ANALYTICS
    [FlurryAPI logEvent:[NSString stringWithFormat:@"MEDAL:%d", [self getMedalEarned]]];
#endif    
    levelEndDelay = 0.0f;
    [self setSimulationSpeed:1.0f withDuration:FLT_MAX];    
    [levelEnvironment   resetFlash];    
    sugarHighMode = false;
}

-(void)endGameFlow {
    GameLevel* nextLevel = [LevelLoader getLevel:level+1 inEpisode:episodePath];
    if (nextLevel && nextLevel.achievement == kAchievement_Locked) {
        nextLevel.achievement = kAchievement_Unlocked;
        [SaveGame saveLevelState:nextLevel];
    }
    
    [self setSimulationSpeed:1.0f withDuration:FLT_MAX];
}

-(Boolean)isPlaying {
    return (gameState == kGameState_Play && !tutorialMode);
}

-(Boolean)isSimulating {
    return ([self isPlaying] || levelEndDelay >= 0.0f);
}

-(void)simUpdate:(float)timeElapsed {
    if (tutorialMode) {
        return;
    }
    
    [METAGAME_MANAGER tick:timeElapsed];
    
    [self updateLevelEnd:timeElapsed]; 
    [kid tick:timeElapsed];
    [Pinata updateComment:timeElapsed];    
    
    if ([self isPlaying]) {
        if ([self updateLevelState]) {
            return;
        }
                      
        levelTime += timeElapsed;    
        [screen setTimeCount:(int)levelTime];        
        [screen setToolCount:tool.count];
        
        [levelEnvironment tick:timeElapsed];   
        [self updateMultiplier:timeElapsed];
        [self updateSugarRush:timeElapsed];
        [self updateSugarHigh:timeElapsed];
        [self updateRain:timeElapsed];
    
        [candyPile tick:timeElapsed];
        
        if (!sugarHighMode) {
            [gameLevel tick:timeElapsed];
            [self updatePinatas:timeElapsed];
            [self updateParachutes:timeElapsed];
            [self updatePowerups:timeElapsed];
        }
        
        [self updateCandy:timeElapsed];
        [self updateGameMessages];
        
        #ifdef CYCLE_GAME_SHADOW_COLOR
            shadowLerp = fminf(2.5f*timeElapsed+shadowLerp,1.0f);
            shadowColor.red = startShadowColor.red*(1.0f-shadowLerp)+endShadowColor.red*shadowLerp;
            shadowColor.green = startShadowColor.green*(1.0f-shadowLerp)+endShadowColor.green*shadowLerp;
            shadowColor.blue = startShadowColor.blue*(1.0f-shadowLerp)+endShadowColor.blue*shadowLerp;
            shadowColor.alpha = 0.6f;            
        #endif
    }
}

-(void)triggerAt:(TapEvent)tapEvent { 
    if ([self isPlaying]) {
        if (sugarHighMode) {
            [self sugarHighTrail:tapEvent];
        }
        else {
            [tool triggerAt:tapEvent];
        }
    }
}

-(void)sugarHighTrail:(TapEvent)tapEvent {
    static Vector2D lastPosition;
    Vector2D currentPosition = Vector2DMake(tapEvent.location.x,tapEvent.location.y);

    if (tapEvent.type==kTapEventType_Start || tapEvent.type==kTapEventType_End) {
        lastPosition = currentPosition;
    }
    else if (tapEvent.type==kTapEventType_Move) {
        sugarHighDistance += Vector2DDistance(lastPosition,currentPosition)/GetGLWidth();

        if (sugarHighDistance > GAME_PARAMETERS.sugarHighCandyDistance) {
            Particle* p = [PARTICLE_MANAGER
                    NewParticleAt:Vector2DMake(currentPosition.x,currentPosition.y)
                        andVelocity:Vector2DMake(0.0f,-150.0f) 
                        andAngle:TWO_PI*random()/RAND_MAX 
                        andScaleX:CANDY_MAX_SIZE 
                        andScaleY:CANDY_MAX_SIZE 
                        andColor:COLOR3D_WHITE 
                        andTotalLifetime:1.0f 
                        andType:kParticleType_Candy
                        andTexture:kTexture_CandyBegin+rand()%(kTexture_CandyEnd-kTexture_CandyBegin)]; 
            p.pulsing = true;
            [PARTICLE_MANAGER addParticle:p];
            [p release];
            
            [candyPile addCandy: GAME_PARAMETERS.sugarHighCandy];
            sugarHighDistance -= GAME_PARAMETERS.sugarHighCandyDistance;
            
            static int fallenCandies = 0;
            ++fallenCandies;
            
            if (fallenCandies > 5) {
                [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_SugarHighCandy)];                        
                fallenCandies = 0;
            }
        }
        lastPosition = currentPosition;
    }
}

-(void)triggerCandyAt:(TapEvent)tapEvent {
    for (Candy* candy in candyPieces) {
        if ([candy isInside:tapEvent.location]) {
            [candy trigger];
        }
    }    
}

-(Boolean)triggerGameEntsAt:(TapEvent)tapEvent andDealDamage:(int)damage {
    Vector2D v = Vector2DMake(tapEvent.location.x, tapEvent.location.y);

    for (Powerup* powerup in [powerups reverseObjectEnumerator]) {
        if ([powerup isInside:tapEvent.location] && [powerup trigger]) {
            return true;
        }
    }

    for (Parachute* parachute in [parachutes reverseObjectEnumerator]) {
        if ([parachute isInside:tapEvent.location] && [parachute trigger]) {
            return true;
        }
    }
        
    for (Pinata* pinata in [pinatas reverseObjectEnumerator]) {
        // close enough
        if (        [pinata isInside:tapEvent.location] 
                &&  ((pinata.behavior&kPinataBehavior_TriggersOnShake)==0)
                &&  [pinata triggerDamage:damage] )
                  
        {
            if (pinata.type != kPinataType_PileEater &&
                pinata.type != kPinataType_Pinhead   &&
                (pinata.behavior&kPinataBehavior_Negative)==0) 
            {    
                if (multiplier > 1) {
                    [screen showMultiplier:multiplier withColor:multiplierColor atPosition:v];
                }
                            
                bonusCount += multiplier;
                
                if (bonusCount >= GAME_PARAMETERS.metricBonusMultipliers) {
                    [self addMetricBonus:GAME_PARAMETERS.metricBonus atPosition:v];                
                    bonusCount = 0;
                }  
                
                [self incrementMultiplier];
            }                                            
            
            return true;
        }
    }
    
    if ([kid isInside:tapEvent.location]) {
        [kid trigger]; 
    }
    
    [self resetMultiplier];
    
    [screen showMissPenalty:-GAME_PARAMETERS.metricMissPenalty atPosition:v];
//    [levelEnvironment flashBackground:COLOR3D_RED];                                                
    
    metricBonusAwarded -= GAME_PARAMETERS.metricMissPenalty;
    [screen addMetricBuffer:-GAME_PARAMETERS.metricMissPenalty];
    
    return false;
}

-(void)addMetricBonus:(int)amount atPosition:(Vector2D)position {
    metricBonusAwarded += GAME_PARAMETERS.metricBonus;
    [screen setMetricBonus:GAME_PARAMETERS.metricBonus atPosition:position];
    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_MetricBonus)];                        
}

-(void)repelAllGameEntsAt:(Vector2D)v withStrength:(float)strength {
    [self repelGameEnts:pinatas at:v withStrength:strength];
    [self repelGameEnts:powerups at:v withStrength:strength];
    [self repelGameEnts:parachutes at:v withStrength:strength];    
}

-(void)swooshAt:(Vector2D)v {
    [PARTICLE_MANAGER createSwooshAt:v];
    [self repelAllGameEntsAt:v withStrength:1000000.0f];
    
    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Miss)];        
}
    
-(void)resetMultiplier {
    multiplier = 1;
    multiplierTime = 0.0f;
    multiplierColor = GetNextMultiplierColor(multiplier);
    levelEnvironment.happyLevel = 0.0f;
    
#ifdef CYCLE_GAME_SHADOW_COLOR
    shadowLerp = 0.0f;
    startShadowColor = shadowColor;
    endShadowColor = COLOR3D_BLACK;        
#endif
}

-(void)incrementMultiplier {
    ++multiplier;
    multiplierTime = 0.0f;
    multiplierColor = GetNextMultiplierColor(multiplier);
    levelEnvironment.happyLevel = fminf(multiplier/8.0f, 0.9f);
    
    if (multiplier > GAME_PARAMETERS.sugarHighMultiples) {
        [self setSugarHighMode:true];
    }
        
#ifdef CYCLE_GAME_SHADOW_COLOR    
    shadowLerp = 0.0f;
    startShadowColor = shadowColor;
    endShadowColor = multiplierColor;    
#endif
}

-(void)explosionAt:(Vector2D)position andRadius:(float)radius andForce:(float)force {
    NSMutableArray* nearPinatas = [self findPinatasNear:position withinDistance:radius];
//    [self repelAllGameEntsAt:position withStrength:force];           

    for (Pinata* p in nearPinatas) {
        if ((p.behavior&kPinataBehavior_TriggersOnShake)==0) {
            [p trigger];
        }
    }                    
    
    [nearPinatas release];

    Boolean isLarge     = false;
    float textureSize   = 1.0f;
    if (radius > 256.0f) {
        isLarge     = true;
        textureSize = GetImageDimensions(kTexture_LargeExplosion).x;                                     
    }
    else {
        isLarge     = false;
        textureSize = GetImageDimensions(kTexture_SmallExplosion).x;                                    
    }
    
    [PARTICLE_MANAGER createExplosionAt:position 
                        withScale:fminf(2*radius/textureSize,1.0f) 
                        withLarge:isLarge 
                        withLayer:kLayer_Game]; 
}
 
-(void)repelGameEnts:(NSMutableArray*)ents at:(Vector2D)v withStrength:(float)strength {
    for (id<GameEntity> ent in ents) {
        float distance = fmaxf(Vector2DDistance(ent.position,v), 1.0f);
        if (distance < 300.0f) {
            Vector2D dir = Vector2DSub(ent.position, v);
            Vector2DNormalize(&dir);
            
            Vector2D repulsion = Vector2DMul(dir, strength/(distance*distance));
            [ent addForce:repulsion];
        }
    }
}

-(NSMutableArray*)findPinatasNear:(Vector2D)v withinDistance:(float)d {
    NSMutableArray* pinatasInRange = [[NSMutableArray alloc] init];
    for (Pinata* pinata in pinatas) {
        if (Vector2DDistance(pinata.position,v) < d && !pinata.consumed) {
            [pinatasInRange addObject:pinata];
        }
    }
    return pinatasInRange;
}

-(Pinata*)findNearestPinata:(Vector2D)v {
    float nearest = FLT_MAX;
    Pinata* retPinata = nil;
    for (Pinata* pinata in pinatas) {
        if (pinata.type == kPinataType_Normal   ||
            pinata.type == kPinataType_Spike    ||
            pinata.type == kPinataType_Treasure ||
            pinata.numParts <= 0) {
            continue;
        }
        
        float distance = Vector2DDistance(pinata.position,v);
        if (distance < nearest) {
            nearest = distance;
            retPinata  = pinata;
        }
    }
    return retPinata;    
}

-(NSMutableArray*)getPinatas {
    return pinatas;
}

-(NSMutableArray*)getPowerups {
    return powerups;
}

-(NSMutableArray*)getParachutes {
    return parachutes;
}

-(CandyPile*)getCandyPile {
    return candyPile;
}

-(void)addCandy:(int)amount useMultiplier:(Boolean)useMult {
    int amountAdded = amount;
    if (useMult) {
        amountAdded *= sqrtf(multiplier);
    }
    
    [candyPile addCandy:amountAdded];
    totalCandyCollected += amountAdded;

    int fatStage = (int)( KID_STAGES*[self levelCompletion] );
    if (fatStage > kid.currentStage && fatStage < KID_STAGES-1) {
        [kid nextStage];
    }
    
    if (amountAdded > 0) {
        METAGAME_MANAGER.totalCandyCollected += amount;
    }
}

-(void)spawnCandyPieces:(int)n atPosition:(Vector2D)p {
    for (int i = 0; i < n; ++i) {
        Candy* candy = [Candy CreateCandyAt:p andVelocity:MakeRandVector2D(400.0f) forGame:self];
        [candyPieces addObject:candy];
    }
}

-(float)levelCompletion {
    return candyPile.candyCollected/(float)(gameLevel.candyRequired);
}

-(void)retryLevel {
    [PARTICLE_MANAGER clear];
    [view setLevel:level];
    [view setTool:tool.type];
    [view changeFlowState:kFlowState_Pregame]; 
}

-(void)nextLevel {
    [PARTICLE_MANAGER clear];
    
    int nextLevel = level+1;
    [view setLevel:nextLevel];
    [view setTool:tool.type];
    
    if (nextLevel >= [LevelLoader getNumLevelsInEpisode:episodePath]) {
        [view changeFlowState:kFlowState_LevelSelection];
    }
    else {
        [view changeFlowState:kFlowState_Pregame];  
    }
}

-(void)render:(float)timeElapsed {
    [levelEnvironment render:timeElapsed];
    
    if (view.flowState == kFlowState_Game) {    
        [candyPile renderBackground:timeElapsed];
        [kid render:timeElapsed];
        [candyPile renderForeground:timeElapsed];    
            
        for (Candy* candy in candyPieces) {
            [candy render:timeElapsed];
        }
                                                                                                
        for (Pinata* pinata in pinatas) {
            if (!pinata.consumed && !pinata.attachmentPinata) {
                [pinata render:timeElapsed];
            }
        }
        
        [Pinata renderComment:timeElapsed];
        
        for (Parachute* parachute in parachutes) {
            [parachute render:timeElapsed];
        } 
                
        for (Powerup* powerup in powerups) {
            [powerup render:timeElapsed];
        }
                
        [cloud render:timeElapsed];
    }
}    

-(eLevelEndReason)levelEndReason {
    return levelEndReason;
}

-(void)displayMessage:(NSString*)message {
    [screen displayMessage:message];
}

-(void)setSugarHighMode:(Boolean)flag {
    sugarHighMode = flag;
    [kid setSugarHigh:flag];
    sugarHighTime = 0.0f;
    sugarHighDistance = 0.0f;
    
    if (sugarHighMode) {
        [tool stop];
        [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_SugarHigh)];  
        ++METAGAME_MANAGER.totalSugarHighs;
    }
}

-(void)setRainMode:(Boolean)flag {
    rainMode = flag;
    rainTime = 0.0f;    
    [cloud setRain:flag];
}

-(void)setSugarRushMode:(Boolean)flag {
    if (flag && !sugarRushMode) {
        candyPile.consumptionDelay  = gameLevel.consumeDelay / GAME_PARAMETERS.sugarRushSpeedup;
    }
    else if (!flag && sugarRushMode) {
        candyPile.consumptionDelay  = gameLevel.consumeDelay;
    }

    sugarRushMode = flag;
    [kid setSugarRush:flag];    
    sugarRushTime = 0.0f;    
}

-(PullCord*)getPullCordAt:(TapEvent)tapEvent {
    for (Parachute* parachute in [parachutes reverseObjectEnumerator]) {
        if ([parachute isInside:tapEvent.location]) {
            return nil;
        }
    }
        
    for (Powerup* powerup in [powerups reverseObjectEnumerator]) {
        if ([powerup isInside:tapEvent.location]) {
            return nil;
        }
    }
        
    for (Pinata* pinata in [pinatas reverseObjectEnumerator]) {
        // close enough
        if ([pinata isInside:tapEvent.location]) {
            if (pinata.pullCord) {
                return pinata.pullCord;
            }
            else {
                return nil;
            }
        }
    }

    return nil;
}

-(void)shake {
    if ([self isPlaying]) {
        for (Pinata* pinata in pinatas) {
            [pinata shake];
        }
        [candyPile bounce];
    }
}

-(int)gameTime {
    return ( levelTime - metricBonusAwarded );
}

- (void)vibrate {
#ifdef USE_RUMBLE    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
#endif
}

-(void)dealloc {
    [levelEnvironment release];
    [screen release];
    [view release];
    
    for (Pinata* p in pinatas) {
        [PINATA_MANAGER ReleasePinata:p];
    }
    [pinatas release];
    
    for (Candy* c in candyPieces) {
        [Candy Recycle:c];
    }
    [candyPieces release];
    [parachutes release];    
    [powerups release];
    [kid release];
    [candyPile release];
    [tool release];
    [cloud release];
    [super dealloc];
}

@end