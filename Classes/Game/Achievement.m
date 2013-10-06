//
//  Achievement.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/14/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import "Achievement.h"
#import "CrystalSession.h"
#import "LevelLoader.h"
#import "MetagameManager.h"

@implementation Achievement

@synthesize uniqueID, description, imageName, earned, newAchievement;

-(void)evaluate {
    if (!earned) {
        float lhs = FLT_MAX;
        switch (field) {
        case kAchievementField_TotalCandy:
            lhs = (METAGAME_MANAGER.totalCandyCollected/100);
            break;
        case kAchievementField_TotalVegetables:
            lhs = METAGAME_MANAGER.totalVegetablesCollected/100;
            break;
        case kAchievementField_TotalBats:
            lhs = METAGAME_MANAGER.totalBats;
            break;
        case kAchievementField_TotalTime:
            lhs = METAGAME_MANAGER.totalTimePlayed;
            break;
        case kAchievementField_TotalBombsDestroyed:
            lhs = METAGAME_MANAGER.totalBombsDestroyed;
            break;
        case kAchievementField_GoldMedalsCollected:
            lhs = METAGAME_MANAGER.totalGoldMedalsCollected;
            break;
        case kAchievementField_SilverMedalsCollected:
            lhs = METAGAME_MANAGER.totalGoldMedalsCollected+METAGAME_MANAGER.totalSilverMedalsCollected;
            break;
        case kAchievementField_BronzeMedalsCollected:
            lhs = METAGAME_MANAGER.totalGoldMedalsCollected
                        + METAGAME_MANAGER.totalSilverMedalsCollected
                        + METAGAME_MANAGER.totalBronzeMedalsCollected;
            break;
        case kAchievementField_totalPinatasDestroyed:
            lhs = METAGAME_MANAGER.totalPinatasDestroyed;
            break;                
        case kAchievementField_totalNormalPinatasDestroyed:
            lhs = METAGAME_MANAGER.totalNormalPinatasDestroyed;
            break;
        case kAchievementField_totalCannibalPinatasDestroyed:
            lhs = METAGAME_MANAGER.totalCannibalPinatasDestroyed;
            break;
        case kAchievementField_totalTickPinatasDestroyed:
            lhs = METAGAME_MANAGER.totalTickPinatasDestroyed;
            break;
        case kAchievementField_totalTicksFreed:
            lhs = METAGAME_MANAGER.totalTicksFreed;
            break;
        case kAchievementField_totalHerosFreed:
            lhs = METAGAME_MANAGER.totalHerosFreed;
            break;
        case kAchievementField_totalUFOsDestroyed:
            lhs = METAGAME_MANAGER.totalUFOsDestroyed;
            break;
        case kAchievementField_totalFairiesDestroyed:
            lhs = METAGAME_MANAGER.totalFairiesDestroyed;
            break;               
        case kAchievementField_totalChameleonsDestroyed:
            lhs = METAGAME_MANAGER.totalChameleonsDestroyed;
            break;
        case kAchievementField_totalTreasuresDestroyed:
            lhs = METAGAME_MANAGER.totalTreasuresDestroyed;
            break;      
        case kAchievementField_totalGoodGremlinsDestroyed:
            lhs = METAGAME_MANAGER.totalGoodGremlinsDestroyed;
            break;                      
        }
        
        if (comparison==[[NSNumber numberWithFloat:lhs] compare:[NSNumber numberWithFloat:rhs]]) {
            earned = true;
            newAchievement = true;
            
            [CrystalSession postAchievement:crystalId 
                            wasObtained:    true 
                            withDescription:description 
                            alwaysPopup:    false];
        }
    }
}

-(id)initWithGroup:(GroupLoad*)group {
    if (self == [super init]) {
        uniqueID    = [[group getAttributeString:@"ID"] retain];
        description = [[group getAttributeString:@"DESCRIPTION"] retain];
        imageName   = [[group getAttributeString:@"IMAGE"] retain];
        crystalId   = [[group getAttributeString:@"CRYSTAL_ID"] retain];
        comparison  = [group getAttributeInt:@"COMPARISON"];
        field       = [group getAttributeInt:@"METRIC"];
        rhs         = [group getAttributeFloat:@"RHS"];
        newAchievement = false;
        earned = false;   
    }
    return self;
}

-(void)dealloc {
    [uniqueID release];
    [description release];
    [imageName release];
    [crystalId release];
    [super dealloc];
}

@end
