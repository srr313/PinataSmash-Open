//
//  GameParameters.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/7/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GAME_PARAMETERS ([GameParameters getGameParameters])

@interface GameParameters : NSObject {
    int   metricBonusMultipliers;
    int   metricBonus;
    int   metricMissPenalty;
    float mergeSpeed;
    float splitSpeed;
    float pinataPartCandy;
    float pinataDrag;
    float maxPinataSpeed;
    float weakPinataCandy;
    float gremlinCandy;    
    float strongPinataCandy;
    float healthyPinataVegetables;
    float pinataEaterSpeed;
    float pinataEaterDelay;
    float pileEaterEatDelay;
    float pileEaterEatAmount;
    float ufoEatDelay;    
    float ufoEatAmount;
    float motherPileEaterBirthWait;
    float pinataHeroSpeed;
    float pinataHeroAttackDelay;
    float pinheadDestroyRadius;
    float pinheadSpikeLifetime;
    float pinheadSpikes;
    float pinheadMaxSpeed;       
    float treasureCandy;  
    float osmosChaseSpeed;
    float planeCandy;
    float planeVegetables;   
    float pinataShortLifetime;
    float ghostCandyMultiplier;
    float growerExpansion;
    float growerDuration;
    float bombForce;    
    float bombRadius;
    float slowMotionDuration;
    float slowMotionSpeed;
    float shrinkDuration;
    float shrinkSpeed;
    float shrinkScale;
    float bazookaRadius;
    float bazookaForce;
    float fallSpeed;
    float parachuteFallSpeed;
    float bungeeFallSpeed;
    float sugarHighDuration;  
    int   sugarHighMultiples;
    int   sugarHighCandy;    
    float sugarHighCandyDistance;
    float sugarRushDuration;
    float sugarRushSpeedup;
    float pileShakeForce;  
}

@property (nonatomic,readonly) int   metricBonusMultipliers;
@property (nonatomic,readonly) int   metricBonus;
@property (nonatomic,readonly) int   metricMissPenalty;
@property (nonatomic,readonly) float mergeSpeed;
@property (nonatomic,readonly) float splitSpeed;
@property (nonatomic,readonly) float pinataPartCandy;
@property (nonatomic,readonly) float pinataDrag;
@property (nonatomic,readonly) float maxPinataSpeed;
@property (nonatomic,readonly) float weakPinataCandy;
@property (nonatomic,readonly) float gremlinCandy;
@property (nonatomic,readonly) float strongPinataCandy;
@property (nonatomic,readonly) float healthyPinataVegetables;
@property (nonatomic,readonly) float pinataEaterSpeed;
@property (nonatomic,readonly) float pinataEaterDelay;
@property (nonatomic,readonly) float pileEaterEatDelay;
@property (nonatomic,readonly) float pileEaterEatAmount;
@property (nonatomic,readonly) float ufoEatDelay;
@property (nonatomic,readonly) float ufoEatAmount;
@property (nonatomic,readonly) float motherPileEaterBirthWait;
@property (nonatomic,readonly) float pinataHeroSpeed;
@property (nonatomic,readonly) float pinataHeroAttackDelay;
@property (nonatomic,readonly) float pinheadSpikeLifetime;
@property (nonatomic,readonly) float pinheadSpikes;
@property (nonatomic,readonly) float pinheadDestroyRadius;
@property (nonatomic,readonly) float pinheadMaxSpeed;
@property (nonatomic,readonly) float treasureCandy;
@property (nonatomic,readonly) float osmosChaseSpeed;
@property (nonatomic,readonly) float planeCandy;
@property (nonatomic,readonly) float planeVegetables; 
@property (nonatomic,readonly) float pinataShortLifetime;
@property (nonatomic,readonly) float ghostCandyMultiplier;
@property (nonatomic,readonly) float growerExpansion;
@property (nonatomic,readonly) float growerDuration;
@property (nonatomic,readonly) float bombForce;
@property (nonatomic,readonly) float bombRadius;
@property (nonatomic,readonly) float slowMotionDuration;
@property (nonatomic,readonly) float slowMotionSpeed;
@property (nonatomic,readonly) float shrinkScale;
@property (nonatomic,readonly) float shrinkSpeed;
@property (nonatomic,readonly) float shrinkDuration;
@property (nonatomic,readonly) float bazookaRadius;
@property (nonatomic,readonly) float bazookaForce;
@property (nonatomic,readonly) float fallSpeed;
@property (nonatomic,readonly) float parachuteFallSpeed;
@property (nonatomic,readonly) float bungeeFallSpeed;
@property (nonatomic,readonly) float sugarHighDuration;
@property (nonatomic,readonly) int   sugarHighMultiples;
@property (nonatomic,readonly) int   sugarHighCandy;
@property (nonatomic,readonly) float sugarHighCandyDistance;
@property (nonatomic,readonly) float sugarRushDuration;
@property (nonatomic,readonly) float sugarRushSpeedup;
@property (nonatomic,readonly) float pileShakeForce;

+(GameParameters*)getGameParameters;
+(void)initSingleton;
-(id)init;

@end
