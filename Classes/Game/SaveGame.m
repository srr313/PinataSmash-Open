//
//  SaveGame.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/22/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "SaveGame.h"
#import "Achievement.h"
#import "GameLevel.h"
#import "Localize.h"
#import "MetagameManager.h"

#define LEVEL_KEY @"LVLS"
#define EPISODE_KEY @"EPSDS"

@implementation SaveGame

+(NSMutableArray*)getLevelStates {
    NSUserDefaults*	defaults = [NSUserDefaults standardUserDefaults];                     
    NSMutableArray* levels = [[NSMutableArray alloc] initWithArray:[defaults arrayForKey:LEVEL_KEY]];
    return levels;    
}

+(NSMutableArray*)getEpisodeStates {
    NSUserDefaults*	defaults = [NSUserDefaults standardUserDefaults];                     
    NSMutableArray* episodes = [[NSMutableArray alloc] initWithArray:[defaults arrayForKey:EPISODE_KEY]];
    return episodes;    
}

+(NSMutableArray*)getScoresList {
    NSUserDefaults*	defaults = [NSUserDefaults standardUserDefaults];                     
    NSMutableArray* scores = [[NSMutableArray alloc] initWithArray:[defaults arrayForKey:HIGH_SCORES_KEY]];
    return scores;
}

+(void)loadMetagame:(MetagameManager*)metagame {
    
    // todo additional metrics tracked!    
    
    NSUserDefaults*	defaults = [NSUserDefaults standardUserDefaults];   
    metagame.money                      = [defaults integerForKey:@"MONEY"];
    metagame.giftMoneyAwarded           = [defaults boolForKey:@"GIFT_MONEY_AWARDED"];    
    metagame.totalTimePlayed            = [defaults integerForKey:@"TIME_PLAYED"];
    metagame.totalVegetablesCollected   = [defaults integerForKey:@"VEGES_COLLECTED"];
    metagame.totalBombsDestroyed        = [defaults integerForKey:@"BOMBS_DESTROYED"];
    metagame.totalGoldMedalsCollected   = [defaults integerForKey:@"GOLD_MEDALS"];
    metagame.totalSilverMedalsCollected = [defaults integerForKey:@"SILVER_MEDALS"];
    metagame.totalBronzeMedalsCollected = [defaults integerForKey:@"BRONZE_MEDALS"];
    metagame.totalNormalPinatasDestroyed = [defaults integerForKey:@"NORMAL_PINATAS"];
    metagame.totalCannibalPinatasDestroyed = [defaults integerForKey:@"CANNIBAL_PINATAS"];
    metagame.totalTickPinatasDestroyed  = [defaults integerForKey:@"TICK_PINATAS"];
    metagame.totalTicksFreed            = [defaults integerForKey:@"TICKS_FREED"];
    metagame.totalHerosFreed            = [defaults integerForKey:@"HEROS_FREED"];
    
    metagame.totalUFOsDestroyed         = [defaults integerForKey:@"UFOS"];
    metagame.totalFairiesDestroyed      = [defaults integerForKey:@"FAIRIES"];
    metagame.totalChameleonsDestroyed   = [defaults integerForKey:@"CHAMELEONS"];
    metagame.totalTreasuresDestroyed    = [defaults integerForKey:@"TREASURES"]; 
    metagame.totalGoodGremlinsDestroyed = [defaults integerForKey:@"GOOD_GREMLINS"];     
    
    metagame.totalBats                  = [defaults integerForKey:@"TOTAL_BATS"]; 
    
    metagame.totalPinatasDestroyed      = [defaults integerForKey:@"PINATAS_DESTROYED"]; 
    metagame.totalCandyCollected        = [defaults integerForKey:@"CANDY_COLLECTED"];
    metagame.totalSugarHighs            = [defaults integerForKey:@"SUGAR_HIGHS"];    
    
    for (Achievement* achievement in metagame.achievements) {
        achievement.earned = [defaults boolForKey:achievement.uniqueID];
    }
    
    for (int i = 0; i < kTool_Count; ++i) {
        NSString* toolStr = [NSString stringWithFormat:@"tool%d",i];
        if ( [defaults objectForKey:toolStr]!=nil && [metagame isToolLocked:i] ) {
            [metagame.toolsOwned addObject:[NSNumber numberWithInt:i]];
        }
    }
}

+(void)saveMetagame:(MetagameManager*)metagame andUpdateCrystal:(Boolean)postCrystal {
    
    
    // todo additional metrics tracked!
    
    
    NSUserDefaults*	defaults = [NSUserDefaults standardUserDefaults];                     
    [defaults setObject:[NSNumber numberWithInt:metagame.money]                         forKey:@"MONEY"];
    [defaults setObject:[NSNumber numberWithBool:metagame.giftMoneyAwarded]              forKey:@"GIFT_MONEY_AWARDED"];    
    [defaults setObject:[NSNumber numberWithInt:metagame.totalTimePlayed]               forKey:@"TIME_PLAYED"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalVegetablesCollected]      forKey:@"VEGES_COLLECTED"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalBombsDestroyed]           forKey:@"BOMBS_DESTROYED"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalGoldMedalsCollected]      forKey:@"GOLD_MEDALS"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalSilverMedalsCollected]    forKey:@"SILVER_MEDALS"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalBronzeMedalsCollected]    forKey:@"BRONZE_MEDALS"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalNormalPinatasDestroyed]   forKey:@"NORMAL_PINATAS"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalCannibalPinatasDestroyed] forKey:@"CANNIBAL_PINATAS"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalTickPinatasDestroyed]     forKey:@"TICK_PINATAS"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalTicksFreed]               forKey:@"TICKS_FREED"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalHerosFreed]               forKey:@"HEROS_FREED"];
    
    [defaults setObject:[NSNumber numberWithInt:metagame.totalUFOsDestroyed]            forKey:@"UFOS"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalFairiesDestroyed]         forKey:@"FAIRIES"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalChameleonsDestroyed]      forKey:@"CHAMELEONS"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalTreasuresDestroyed]       forKey:@"TREASURES"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalGoodGremlinsDestroyed]    forKey:@"GOOD_GREMLINS"];    

    [defaults setObject:[NSNumber numberWithInt:metagame.totalBats]                     forKey:@"TOTAL_BATS"];
    
    // leaderboards
    [defaults setObject:[NSNumber numberWithInt:metagame.totalPinatasDestroyed]         forKey:@"PINATAS_DESTROYED"];
    [defaults setObject:[NSNumber numberWithInt:metagame.totalCandyCollected]           forKey:@"CANDY_COLLECTED"];    
    [defaults setObject:[NSNumber numberWithInt:metagame.totalSugarHighs]               forKey:@"SUGAR_HIGHS"];        

    for (Achievement* achievement in metagame.achievements) {
        [defaults setObject:[NSNumber numberWithBool:achievement.earned] forKey:achievement.uniqueID];
    }
    
    for (NSNumber* toolId in metagame.toolsOwned) {
        NSString* toolStr = [NSString stringWithFormat:@"tool%d",[toolId intValue]];
        [defaults setObject:[NSNumber numberWithBool:true] forKey:toolStr];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    if (postCrystal) {
        [metagame updateCrystalLeaderboards];        
    }
}

+(void)saveLevelState:(GameLevel*)lvl {
	NSUserDefaults*		defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray*		levels = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:LEVEL_KEY]];
    for (NSDictionary* d in levels) {
        NSString* levelID = [d objectForKey:ID_KEY];
        if ( [levelID compare:lvl.uniqueID]==NSOrderedSame ) {
            [levels removeObject:d];
            break;
        }
    }

    NSDictionary* levelDict = [[NSDictionary alloc] 
                                initWithObjectsAndKeys:
                                    lvl.uniqueID, ID_KEY, 
                                    [NSNumber numberWithInt:lvl.achievement], ACHIEVEMENT_KEY, nil];
    
	[levels addObject: levelDict];
	[defaults setObject:levels forKey:LEVEL_KEY];
    
    [levelDict release];
    [levels release];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)saveEpisodeState:(eAchievement)state andName:(NSString*)name {
	NSUserDefaults*		defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray*		episodes = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:EPISODE_KEY]];
    
    for (NSDictionary* d in episodes) {
        NSString* episodeID = [d objectForKey:ID_KEY];
        if ( [episodeID compare:name]==NSOrderedSame ) {
            [episodes removeObject:d];
            break;
        }
    }
    
    NSDictionary* episodeDict = [[NSDictionary alloc] 
                                    initWithObjectsAndKeys: 
                                        name, ID_KEY, 
                                        [NSNumber numberWithInt:state], ACHIEVEMENT_KEY, nil];    
	[episodes addObject:episodeDict];
	[defaults setObject:episodes forKey:EPISODE_KEY];
    
    [episodeDict release];
    [episodes release];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//+(void)saveScore:(int)score {
//	NSUserDefaults*		defaults = [NSUserDefaults standardUserDefaults];
//	NSString*			name = [defaults stringForKey:HIGH_SCORES_KEY];
//	NSDate*				date = [NSDate date];
//	NSMutableArray*		scores;
//		
//	//Make sure a player name exists, if only the default
//	if(![name length]) {
//		name = LocalizeText(kLocalizedString_DefaultPlayer);
//    }
//	
//	//Update the high-scores in the preferences
//	scores = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:HIGH_SCORES_KEY]];
//	[scores addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//                        name, @"name", 
//                        [NSNumber numberWithInt:score], @"score", 
//                        date, @"date", nil]];
//	[scores sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO] autorelease]]];
//	[defaults setObject:scores forKey:HIGH_SCORES_KEY];
//  [scores release];
//}

@end
