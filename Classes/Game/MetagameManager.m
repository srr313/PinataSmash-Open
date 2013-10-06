//
//  MetagameManager.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/2/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "MetagameManager.h"
#import "Achievement.h"
#import "CrystalPlayer.h"
#import "CrystalSession.h"
#import "GameCommon.h"
#import "SaveGame.h"

////////////////////////////////////////////////

MetagameManager* GetMetagameManager() {
    static MetagameManager* sMetagameManager = nil;
    if (!sMetagameManager) {
        sMetagameManager = [[MetagameManager alloc] init];
    }
    return sMetagameManager;
}


@implementation MetagameManager

@synthesize totalCandyCollected, totalPinatasDestroyed, totalSugarHighs, totalBats,
            totalVegetablesCollected, totalBombsDestroyed, 
            totalGoldMedalsCollected, totalSilverMedalsCollected, totalBronzeMedalsCollected,
            totalNormalPinatasDestroyed, totalCannibalPinatasDestroyed, totalTickPinatasDestroyed,
            totalTicksFreed, totalHerosFreed, totalUFOsDestroyed, totalFairiesDestroyed, totalChameleonsDestroyed, totalTreasuresDestroyed, totalGoodGremlinsDestroyed,
totalTimePlayed, money, achievements, justEarnedNewAchievement, giftMoneyAwarded, 
            toolsOwned;

-(id)init {
    if (self == [super init]) {        
        justEarnedNewAchievement = false;
        achievements = [[NSMutableArray alloc] init];
        toolsOwned = [[NSMutableArray alloc] init];

        [self unlockTool:kTool_Bat];
        
        BodyLoad* body = [[BodyLoad alloc] initWithPath:@"Achievements"];
        for (GroupLoad* group in body.groups) {
            if ([group.typeName caseInsensitiveCompare:@"Achievement"]==NSOrderedSame) {
                Achievement* achievement = [[Achievement alloc] initWithGroup:group];        
                [achievements addObject:achievement];
            }
        }        
        
        [body release];
        [SaveGame loadMetagame:self];
    }
    return self;
}

-(void)dealloc {
    [achievements release];
    [toolsOwned release];
    [super dealloc];
}

-(void)awardMedal:(eAchievement)achievement previousAchievement:(eAchievement)previousAchievement {
    if (previousAchievement==kAchievement_Gold) {
        METAGAME_MANAGER.totalGoldMedalsCollected--;    
    }
    else if (previousAchievement==kAchievement_Silver) {
        METAGAME_MANAGER.totalSilverMedalsCollected--;
    }
    else if (previousAchievement==kAchievement_Bronze) {
        METAGAME_MANAGER.totalBronzeMedalsCollected--;
    }

    if (achievement==kAchievement_Gold) {
        METAGAME_MANAGER.totalGoldMedalsCollected++;
    }
    else if (achievement==kAchievement_Silver) {
        METAGAME_MANAGER.totalSilverMedalsCollected++;        
    }
    else if (achievement==kAchievement_Bronze) {
        METAGAME_MANAGER.totalBronzeMedalsCollected++;        
    }
}

-(void)addMoney:(int)amount {
    NSAssert(amount>=0,@"MetagameManager::addMoney - non-positive amount added");
    money += amount;
}

-(void)spendMoney:(int)amount {
    NSAssert(amount>=0,@"MetagameManager::spendMoney - non-positive amount spent");
    money = MAX(money-amount, 0);
}

-(void)tick:(float)timeElapsed {
    totalTimePlayed += timeElapsed;
    justEarnedNewAchievement = false;
    
    for (Achievement* achievement in achievements) {
        Boolean wasNewAchievement = achievement.newAchievement;
        [achievement evaluate];
        
        if (!wasNewAchievement && achievement.newAchievement) {
            justEarnedNewAchievement = true;
        }
    }
}

-(NSMutableArray*)getNewAchievements {
    NSMutableArray* newAchievements = [[NSMutableArray alloc] init];
    for (Achievement* achievement in achievements) {
        if (achievement.newAchievement) {
            [newAchievements addObject:achievement];
        }
    }
    return newAchievements;
}

-(void)unlockTool:(eTool)tool {
    if ([self isToolLocked:tool]) {
        [toolsOwned addObject:[NSNumber numberWithInt:tool]];
    }
}

-(Boolean)isToolLocked:(eTool)tool {
    return !([toolsOwned containsObject:[NSNumber numberWithInt:tool]]);
}

-(Boolean)wasItemGifted:(long)giftID {
    CrystalPlayer* player = [CrystalPlayer sharedInstance]; 
    const NSArray* gifts = player.gifts;
    if (gifts.count > 0) {
#ifdef DEBUG_BUILD        
        NSLog(@"%@", [gifts description]);
#endif
        for (NSNumber* gift in gifts) {
            if ([gift longValue] == giftID) {
                return true;
            }
        }
    }
    return false;
}

-(void)awardMoneyGift {    
    if (!giftMoneyAwarded) {
        [self addMoney:MONEY_GIFT_AMOUNT];
        giftMoneyAwarded = true;
    }
}

-(void)updateCrystalLeaderboards {
    [CrystalSession postLeaderboardResult:  totalPinatasDestroyed 
                         forLeaderboardId:       @"1680932663" 
                           lowestValFirst:         false];

    [CrystalSession postLeaderboardResult:  (totalCandyCollected/100)
                         forLeaderboardId:       @"1680920764" 
                           lowestValFirst:         false];

    [CrystalSession postLeaderboardResult:  totalSugarHighs 
                         forLeaderboardId:       @"1681553337" 
                           lowestValFirst:         false];
}

@end
