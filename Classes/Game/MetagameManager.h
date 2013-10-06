//
//  MetagameManager.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/2/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameLevel.h"
#import "LevelLoader.h"
#import "Localize.h"
#import "Pinata.h"

#define METAGAME_MANAGER GetMetagameManager()

@class MetagameManager;

extern MetagameManager* GetMetagameManager();

@interface MetagameManager : NSObject {
    
    int totalBats;  
    
    int totalGoldMedalsCollected;
    int totalSilverMedalsCollected;
    int totalBronzeMedalsCollected;
    
    // leaderboards
    int totalPinatasDestroyed;
    int totalCandyCollected;
    int totalSugarHighs;
    
    int totalNormalPinatasDestroyed;
    int totalCannibalPinatasDestroyed;
    int totalTickPinatasDestroyed;  
    int totalTicksFreed;
    int totalHerosFreed;    
    int totalUFOsDestroyed;         
    int totalFairiesDestroyed;      
    int totalChameleonsDestroyed;   
    int totalTreasuresDestroyed;  
    int totalGoodGremlinsDestroyed;
            
    int totalVegetablesCollected;
    int totalBombsDestroyed;
    int money;
    
    Boolean giftMoneyAwarded;
    
    float totalTimePlayed;
    
    NSMutableArray* achievements;
    
    NSMutableArray* toolsOwned;
    
    Boolean justEarnedNewAchievement;
}

@property (nonatomic) int totalBats;
@property (nonatomic) int totalPinatasDestroyed;
@property (nonatomic) int totalCandyCollected;
@property (nonatomic) int totalSugarHighs;

@property (nonatomic) int totalVegetablesCollected;
@property (nonatomic) int totalBombsDestroyed;
@property (nonatomic) int totalGoldMedalsCollected;
@property (nonatomic) int totalSilverMedalsCollected;
@property (nonatomic) int totalBronzeMedalsCollected;
@property (nonatomic) int totalNormalPinatasDestroyed;
@property (nonatomic) int totalCannibalPinatasDestroyed;
@property (nonatomic) int totalTickPinatasDestroyed;
@property (nonatomic) int totalTicksFreed;
@property (nonatomic) int totalHerosFreed;
@property (nonatomic) int totalUFOsDestroyed;
@property (nonatomic) int totalFairiesDestroyed;
@property (nonatomic) int totalChameleonsDestroyed;
@property (nonatomic) int totalTreasuresDestroyed;
@property (nonatomic) int totalGoodGremlinsDestroyed;
@property (nonatomic) float totalTimePlayed;
@property (nonatomic) int money;
@property (nonatomic) Boolean giftMoneyAwarded;
@property (nonatomic, assign) NSMutableArray* achievements;
@property (nonatomic) Boolean justEarnedNewAchievement;
@property (nonatomic, assign) NSMutableArray* toolsOwned;

-(id)init;
-(void)dealloc;
-(void)awardMedal:(eAchievement)achievement previousAchievement:(eAchievement)previousAchievement;
-(void)addMoney:(int)amount;
-(void)spendMoney:(int)amount;
-(void)tick:(float)timeElapsed;
-(NSMutableArray*)getNewAchievements;
-(void)unlockTool:(eTool)tool;
-(Boolean)isToolLocked:(eTool)tool;
-(void)updateCrystalLeaderboards;
-(Boolean)wasItemGifted:(long)giftID;
-(void)awardMoneyGift;

@end
