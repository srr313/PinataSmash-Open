//
//  GameParameters.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/7/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import "GameParameters.h"
#import "LevelLoader.h"

static GameParameters* sGameParameters = nil;

@implementation GameParameters

@synthesize metricBonusMultipliers, metricBonus, metricMissPenalty,
            mergeSpeed, splitSpeed, pinataPartCandy, pinataDrag, maxPinataSpeed, weakPinataCandy, gremlinCandy,
            strongPinataCandy, healthyPinataVegetables, pinataEaterSpeed, pinataEaterDelay,
            pileEaterEatDelay, pileEaterEatAmount, ufoEatDelay, ufoEatAmount, 
            motherPileEaterBirthWait, pinataHeroSpeed, 
            pinataHeroAttackDelay, pinheadSpikeLifetime, pinheadSpikes, 
            pinheadDestroyRadius, pinheadMaxSpeed, treasureCandy, 
            osmosChaseSpeed, planeCandy, planeVegetables, pinataShortLifetime, 
            ghostCandyMultiplier, growerExpansion, growerDuration,
            bombForce, bombRadius, slowMotionDuration, slowMotionSpeed, 
            shrinkScale, shrinkDuration, shrinkSpeed,
            bazookaRadius, bazookaForce, fallSpeed, parachuteFallSpeed, bungeeFallSpeed,
            sugarHighDuration, sugarHighMultiples, sugarHighCandy, sugarHighCandyDistance,
            sugarRushDuration, sugarRushSpeedup, pileShakeForce; 

+(void)initSingleton {
    NSAssert(sGameParameters==nil, @"GameParameters already initialized");
    if (!sGameParameters) {
        sGameParameters = [[GameParameters alloc] init];
    }
}
            
+(GameParameters*)getGameParameters {
    return sGameParameters;
}

-(id)init {
    if (self = [super init]) {        
        BodyLoad* body = [[BodyLoad alloc] initWithPath:@"GameParameters"];
        for (GroupLoad* group in body.groups) {
            if ([group.typeName caseInsensitiveCompare:@"GAME_PARAMETERS"]==NSOrderedSame) {
                metricBonusMultipliers  = [group getAttributeInt:@"METRIC_BONUS_MULTIPLIERS"];
                metricBonus             = [group getAttributeInt:@"METRIC_BONUS"]; 
                metricMissPenalty       = [group getAttributeInt:@"METRIC_MISS_PENALTY"];
                mergeSpeed              = [group getAttributeFloat:@"MERGE_SPEED"];
                splitSpeed              = [group getAttributeFloat:@"SPLIT_SPEED"];
                pinataPartCandy         = [group getAttributeFloat:@"PINATA_PART_CANDY"];
                pinataDrag              = [group getAttributeFloat:@"PINATA_DRAG"];                 
                maxPinataSpeed          = [group getAttributeFloat:@"MAX_PINATA_SPEED"];                
                weakPinataCandy         = [group getAttributeFloat:@"WEAK_PINATA_CANDY"];
                gremlinCandy            = [group getAttributeFloat:@"GREMLIN_CANDY"];                
                strongPinataCandy       = [group getAttributeFloat:@"STRONG_PINATA_CANDY"];
                healthyPinataVegetables = [group getAttributeFloat:@"HEALTHY_PINATA_VEGETABLES"];
                pinataEaterSpeed        = [group getAttributeFloat:@"PINATA_EATER_SPEED"];
                pinataEaterSpeed        = [group getAttributeFloat:@"PINATA_EATER_DELAY"];                
                pileEaterEatDelay       = [group getAttributeFloat:@"PILE_EATER_EAT_DELAY"];
                pileEaterEatAmount      = [group getAttributeFloat:@"PILE_EATER_EAT_AMOUNT"];
                ufoEatDelay             = [group getAttributeFloat:@"UFO_EAT_DELAY"];
                ufoEatAmount            = [group getAttributeFloat:@"UFO_EAT_AMOUNT"];                
                motherPileEaterBirthWait = [group getAttributeFloat:@"MOTHER_PILE_EATER_BIRTH_WAIT"];
                pinataHeroSpeed         = [group getAttributeFloat:@"PINATA_HERO_SPEED"];
                pinataHeroAttackDelay   = [group getAttributeFloat:@"PINATA_HERO_ATTACK_DELAY"];
                pinheadSpikeLifetime    = [group getAttributeFloat:@"PINHEAD_SPIKE_LIFETIME"];                
                pinheadSpikes           = [group getAttributeInt:@"PINHEAD_SPIKES"];          
                pinheadDestroyRadius    = [group getAttributeFloat:@"PINHEAD_DESTROY_RADIUS"];                                                                      
                pinheadMaxSpeed         = [group getAttributeFloat:@"PINHEAD_MAX_SPEED"];                                                                      
                osmosChaseSpeed         = [group getAttributeFloat:@"OSMOS_CHASE_SPEED"];                  
                planeCandy              = [group getAttributeFloat:@"PLANE_CANDY"];                  
                planeVegetables         = [group getAttributeFloat:@"PLANE_VEGETABLES"];                  
                treasureCandy           = [group getAttributeFloat:@"TREASURE_CANDY"];                                                                  
                pinataShortLifetime     = [group getAttributeFloat:@"PINATA_SHORT_LIFETIME"];  
                ghostCandyMultiplier    = [group getAttributeFloat:@"GHOST_CANDY_MULTIPLIER"];
                growerExpansion         = [group getAttributeFloat:@"GROWER_EXPANSION"];
                growerDuration          = [group getAttributeFloat:@"GROWER_DURATION"];                                
                bombForce               = [group getAttributeFloat:@"BOMB_FORCE"];                
                bombRadius              = [group getAttributeFloat:@"BOMB_RADIUS"];
                slowMotionSpeed         = [group getAttributeFloat:@"SLOW_MOTION_SPEED"];                    
                slowMotionDuration      = [group getAttributeFloat:@"SLOW_MOTION_DURATION"];               
                shrinkScale             = [group getAttributeFloat:@"SHRINK_SCALE"];               
                shrinkSpeed             = [group getAttributeFloat:@"SHRINK_SPEED"];                 
                shrinkDuration          = [group getAttributeFloat:@"SHRINK_DURATION"];                               
                bazookaForce            = [group getAttributeFloat:@"BAZOOKA_FORCE"];                  
                bazookaRadius           = [group getAttributeFloat:@"BAZOOKA_RADIUS"];               
                fallSpeed               = [group getAttributeFloat:@"FALL_SPEED"];               
                parachuteFallSpeed      = [group getAttributeFloat:@"PARACHUTE_FALL_SPEED"];               
                bungeeFallSpeed         = [group getAttributeFloat:@"BUNGEE_FALL_SPEED"];    
                sugarHighDuration       = [group getAttributeFloat:@"SUGAR_HIGH_DURATION"];    
                sugarHighMultiples      = [group getAttributeInt:@"SUGAR_HIGH_MULTIPLES"];    
                sugarHighCandy          = [group getAttributeInt:@"SUGAR_HIGH_CANDY"];  
                sugarHighCandyDistance  = [group getAttributeFloat:@"SUGAR_HIGH_CANDY_DISTANCE"];                                     
                sugarRushDuration       = [group getAttributeFloat:@"SUGAR_RUSH_DURATION"];  
                sugarRushSpeedup        = [group getAttributeFloat:@"SUGAR_RUSH_SPEEDUP"];   
                pileShakeForce          = [group getAttributeFloat:@"PILE_SHAKE_FORCE"]; 
            }
        }                
    }
    return self;
}

@end
