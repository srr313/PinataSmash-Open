//
//  GameCommon.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/5/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#include "OpenGLCommon.h"

//#define DO_ANALYTICS          

#define FACEBOOK_API_KEY        @"ENTER FB API KEY HERE"
#define FACEBOOK_APP_URL        @"ENTER APP URL HERE"
#define TWITTER_APP_URL         @"ENTER TWITTER URL HERE"
#define LEVEL_PURCHASE_PRICE    3
#define RAND_CANDY_PIECES_PER_RELEASE 0.125f
#define NUM_EPISODES            3
#define MONEY_GIFT_AMOUNT       20

#define SUPER_BAT_GIFT_ID       1734940442
#define MONEY_20_GIFT_ID        1743750784

#define ENABLE_ACHIEVEMENTS

//#define DEBUG_BUILD             1

#define COLOR3D_WHITE           (Color3DMake(1.0f, 1.0f, 1.0f, 1.0f))
#define COLOR3D_BLACK           (Color3DMake(0.0f, 0.0f, 0.0f, 1.0f))
#define COLOR3D_RED             (Color3DMake(1.0f, 0.0f, 0.0f, 1.0f))
#define COLOR3D_GREEN           (Color3DMake(0.0f, 1.0f, 0.0f, 1.0f))
#define COLOR3D_BLUE            (Color3DMake(0.0f, 0.0f, 1.0f, 1.0f))
#define COLOR3D_YELLOW          (Color3DMake(1.0f, 1.0f, 0.0f, 1.0f))

#define TWO_PI                  2.0f*M_PI

typedef enum {
    kTool_Bat = 0,
    kTool_SuperBat,    
    kTool_Bazooka,
    kTool_AutoFire,
    kTool_Count,
} eTool;

typedef enum {
    kAchievement_Locked = 0,
    kAchievement_Unlocked,
    kAchievement_Failed,
    kAchievement_Bronze,
    kAchievement_Silver,
    kAchievement_Gold,
    kAchievement_Count,
} eAchievement;

extern Color3D GetAchievementColor(eAchievement achievement);
extern NSString* GetWebPath(NSString* filename);
extern NSString* GetGameTimeFormat(int timeValue, bool showEntireClock);
extern Boolean IsGameShadowsEnabled();
extern Boolean IsGameMotionBlurEnabled();

