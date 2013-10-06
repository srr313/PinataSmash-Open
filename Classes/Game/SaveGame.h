//
//  SaveGame.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/22/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameLevel.h"

#define HIGH_SCORES_KEY	@"highScores"
#define ID_KEY          @"name"
#define ACHIEVEMENT_KEY @"achievement"

@class MetagameManager;

@interface SaveGame : NSObject {
}
+(NSMutableArray*)getLevelStates;
+(NSMutableArray*)getEpisodeStates;
+(NSMutableArray*)getScoresList;
+(void)loadMetagame:(MetagameManager*)metagame;
+(void)saveMetagame:(MetagameManager*)metagame andUpdateCrystal:(Boolean)postCrystal;
+(void)saveLevelState:(GameLevel*)lvl;
+(void)saveEpisodeState:(eAchievement)state andName:(NSString*)name;
@end
