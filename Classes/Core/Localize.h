//
//  Localize.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/25/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString* eLocalizedString;

#define kLocalizedString_Play               @"LOC_PLAY"
#define kLocalizedString_HighScores         @"LOC_HIGHSCORES"   // no longer used
#define kLocalizedString_Achievement        @"LOC_ACHIEVEMENT"
#define kLocalizedString_FB_Achievement     @"LOC_FB_ACHIEVEMENT"
#define kLocalizedString_Achievements       @"LOC_ACHIEVEMENTS"
#define kLocalizedString_Redeem             @"LOC_REDEEM"
#define kLocalizedString_Tutorial           @"LOC_TUTORIAL"
#define kLocalizedString_TapToContinue      @"LOC_TAP_TO_CONTINUE"
#define kLocalizedString_Multiplier         @"LOC_MULTIPLIER"
#define kLocalizedString_Pause              @"LOC_PAUSE"
#define kLocalizedString_Resume             @"LOC_RESUME"
#define kLocalizedString_Gameover           @"LOC_GAMEOVER"
#define kLocalizedString_GameoverResult     @"LOC_GAMEOVER_RESULT"
#define kLocalizedString_GameoverHighscore  @"LOC_GAMEOVER_HIGHSCORE"
#define kLocalizedString_JustStartedPlaying @"LOC_JUST_STARTED"
#define kLocalizedString_Caption            @"LOC_CAPTION"
#define kLocalizedString_Description        @"LOC_DESCRIPTION"
#define kLocalizedString_MessagePrompt      @"LOC_MESSAGE_PROMPT"
#define kLocalizedString_Menu               @"LOC_MENU"
#define kLocalizedString_Back               @"LOC_BACK"
#define kLocalizedString_BankInfo           @"LOC_BANK_INFO"
#define kLocalizedString_RedeemInfo         @"LOC_REDEEM_INFO"
#define kLocalizedString_Retry              @"LOC_RETRY"
#define kLocalizedString_Level              @"LOC_LEVEL"
#define kLocalizedString_LevelStart         @"LOC_LEVEL_START"
#define kLocalizedString_LevelEndTime       @"LOC_LEVEL_END_TIME"
#define kLocalizedString_LevelEndTimeOne    @"LOC_LEVEL_END_TIME_ONE"
#define kLocalizedString_Episodes           @"LOC_EPISODE_SELECTION"
#define kLocalizedString_Episode1           @"LOC_EPISODE_1"
#define kLocalizedString_Episode2           @"LOC_EPISODE_2"
#define kLocalizedString_Episode3           @"LOC_EPISODE_3"
#define kLocalizedString_EpisodeCanPurchaseInfo @"LOC_PURCHASE_EPISODE"
#define kLocalizedString_EpisodeCannotPurchaseInfo @"LOC_CANNOT_PURCHASE_EPISODE"
#define kLocalizedString_LevelCanPurchaseInfo @"LOC_PURCHASE_LEVEL"
#define kLocalizedString_LevelCannotPurchaseInfo @"LOC_CANNOT_PURCHASE_LEVEL"
#define kLocalizedString_ToolCanPurchaseInfo    @"LOC_PURCHASE_TOOL"
#define kLocalizedString_ToolCannotPurchaseInfo @"LOC_CANNOT_PURCHASE_TOOL"
#define kLocalizedString_Buy                @"LOC_BUY"
#define kLocalizedString_BuyNextLevel       @"LOC_BUY_NEXT_LEVEL"
#define kLocalizedString_DefaultPlayer      @"LOC_DEFAULT_PLAYER"
#define kLocalizedString_Victory1           @"LOC_VICTORY1"
#define kLocalizedString_Victory2           @"LOC_VICTORY2"
#define kLocalizedString_Victory3           @"LOC_VICTORY3"
#define kLocalizedString_Victory4           @"LOC_VICTORY4"
#define kLocalizedString_Victory5           @"LOC_VICTORY5"
#define kLocalizedString_MultiplierCheer1   @"LOC_MULTIPLIER_CHEER1"
#define kLocalizedString_MultiplierCheer2   @"LOC_MULTIPLIER_CHEER2"
#define kLocalizedString_MultiplierCheer3   @"LOC_MULTIPLIER_CHEER3"
#define kLocalizedString_MultiplierCheer4   @"LOC_MULTIPLIER_CHEER4"
#define kLocalizedString_MultiplierCheer5   @"LOC_MULTIPLIER_CHEER5"
#define kLocalizedString_BronzeWon          @"LOC_BRONZE_WON"
#define kLocalizedString_SilverWon          @"LOC_SILVER_WON"
#define kLocalizedString_GoldWon            @"LOC_GOLD_WON"
#define kLocalizedString_Null               @"LOC_NULL"

typedef enum {
    kLanguage_English = 0,
    kLanguage_Count
} eLanguage;

NSString* LocalizeText(eLocalizedString stringId);
NSString* LocalizeTextArgs(eLocalizedString stringId, NSObject* firstParam, ...);
