//
//  Achievement.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/14/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Localize.h"

@class GroupLoad;

typedef enum {
    kAchievementField_TotalCandy = 0,               //0
    kAchievementField_TotalVegetables,              //1
    kAchievementField_TotalBats,                    //2
    kAchievementField_TotalTime,                    //3
    kAchievementField_TotalBombsDestroyed,          //4
    kAchievementField_GoldMedalsCollected,          //5
    kAchievementField_SilverMedalsCollected,        //6
    kAchievementField_BronzeMedalsCollected,        //7
    kAchievementField_totalPinatasDestroyed,        //8
    kAchievementField_totalNormalPinatasDestroyed,  //9
    kAchievementField_totalCannibalPinatasDestroyed,//10
    kAchievementField_totalTickPinatasDestroyed,    //11
    kAchievementField_totalTicksFreed,              //12
    kAchievementField_totalHerosFreed,              //13
    kAchievementField_totalUFOsDestroyed,           //14
    kAchievementField_totalFairiesDestroyed,        //15
    kAchievementField_totalChameleonsDestroyed,     //16
    kAchievementField_totalTreasuresDestroyed,      //17
    kAchievementField_totalGoodGremlinsDestroyed,   //18
} eAchievementField;

@interface Achievement : NSObject
{
    NSString*           uniqueID;
    NSComparisonResult  comparison;
    eAchievementField   field;
    float               rhs;
    eLocalizedString    description;
    NSString*           imageName;
    NSString*           crystalId;
    Boolean             earned;
    Boolean             newAchievement;
}
@property (nonatomic, readonly) NSString*           uniqueID;
@property (nonatomic, readonly) eLocalizedString    description;
@property (nonatomic, readonly) NSString*           imageName;
@property (nonatomic)           Boolean             earned;
@property (nonatomic)           Boolean             newAchievement;
-(void)evaluate;
-(id)initWithGroup:(GroupLoad*)group;

@end
