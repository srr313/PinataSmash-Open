//
//  Localize.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/25/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "Localize.h"

static NSMutableDictionary* localizationTable = nil;

void MaybeInitLocalizationTable() {
    if (!localizationTable) {
        localizationTable = [[NSMutableDictionary alloc] init];
        [localizationTable setValue:@"Play" forKey:@"LOC_PLAY"];
        [localizationTable setValue:@"High Scores" forKey:@"LOC_HIGHSCORES"];
        [localizationTable setValue:@"Special Achievement!" forKey:@"LOC_ACHIEVEMENT"];
        [localizationTable setValue:@"Achievement: %@" forKey:@"LOC_FB_ACHIEVEMENT"];
        [localizationTable setValue:@"Achievements" forKey:@"LOC_ACHIEVEMENTS"];
        [localizationTable setValue:@"Claim Reward" forKey:@"LOC_REDEEM"];
        [localizationTable setValue:@"Tutorial" forKey:@"LOC_TUTORIAL"];
        [localizationTable setValue:@"Tap to Continue" forKey:@"LOC_TAP_TO_CONTINUE"];
        [localizationTable setValue:@"%@x" forKey:@"LOC_MULTIPLIER"];
        [localizationTable setValue:@"Paused" forKey:@"LOC_PAUSE"];
        [localizationTable setValue:@"Continue" forKey:@"LOC_RESUME"];
        [localizationTable setValue:@"Nice Try" forKey:@"LOC_GAMEOVER"];
        [localizationTable setValue:@"%@ Candies Collected" forKey:@"LOC_GAMEOVER_RESULT"];
        [localizationTable setValue:@"%@ is your best." forKey:@"LOC_GAMEOVER_HIGHSCORE"];
        [localizationTable setValue:@"I just started playing Piñata Smash.  Check it out!" forKey:@"LOC_JUST_STARTED"];
        [localizationTable setValue:@"This game is AWESOME!" forKey:@"LOC_CAPTION"];
        [localizationTable setValue:@"Piñata Smash for iPhone" forKey:@"LOC_DESCRIPTION"];
        [localizationTable setValue:@"Share tips with friends" forKey:@"LOC_MESSAGE_PROMPT"];
        [localizationTable setValue:@"Menu" forKey:@"LOC_MENU"];
        [localizationTable setValue:@"Back" forKey:@"LOC_BACK"];
        [localizationTable setValue:@"Spend candy to unlock levels, episodes, and weapons!  "
                                        "Win medals to earn more candy!" forKey:@"LOC_BANK_INFO"];
        [localizationTable setValue:@"Pssst!  Want more candy!?  "
                                        "Let your friends know about "
                                        "Piñata Smash and we will give you %@ candies!" 
                                        forKey:@"LOC_REDEEM_INFO"];
        [localizationTable setValue:@"Retry" forKey:@"LOC_RETRY"];
        [localizationTable setValue:@"Level %@" forKey:@"LOC_LEVEL"];
        [localizationTable setValue:@"%@ Seconds" forKey:@"LOC_LEVEL_END_TIME"];
        [localizationTable setValue:@"%@ Second" forKey:@"LOC_LEVEL_END_TIME_ONE"];
        [localizationTable setValue:@"GO!" forKey:@"LOC_LEVEL_START"];
        [localizationTable setValue:@"Episodes" forKey:@"LOC_EPISODE_SELECTION"];
        [localizationTable setValue:@"The Piñata Smasher" forKey:@"LOC_EPISODE_1"];
        [localizationTable setValue:@"The Piñatas Bounce Back" forKey:@"LOC_EPISODE_2"];
        [localizationTable setValue:@"The Piñata Smasher Returns" forKey:@"LOC_EPISODE_3"];
        [localizationTable setValue:@"Would you like\nto purchase this episode\nfor %@ candies?" forKey:@"LOC_PURCHASE_EPISODE"];
        [localizationTable setValue:@"You do not have\n%@ candies\nto purchase\nthis episode." forKey:@"LOC_CANNOT_PURCHASE_EPISODE"];
        [localizationTable setValue:@"Would you like\nto purchase this level\nfor %@ candies?" forKey:@"LOC_PURCHASE_LEVEL"];
        [localizationTable setValue:@"You do not have\n%@ candies\nto purchase\nthis level." forKey:@"LOC_CANNOT_PURCHASE_LEVEL"];
        [localizationTable setValue:@"Would you like\nto purchase this weapon\nfor %@ candies?" forKey:@"LOC_PURCHASE_TOOL"];
        [localizationTable setValue:@"You do not have\n%@ candies\nto purchase\nthis weapon." forKey:@"LOC_CANNOT_PURCHASE_TOOL"];
        [localizationTable setValue:@"Buy" forKey:@"LOC_BUY"];
        [localizationTable setValue:@"Would you like to spend %@ candies to skip to the next level?" forKey:@"LOC_BUY_NEXT_LEVEL"];
        [localizationTable setValue:@"Player" forKey:@"LOC_DEFAULT_PLAYER"];
        [localizationTable setValue:@"Awesome!" forKey:@"LOC_VICTORY1"];
        [localizationTable setValue:@"Radical!" forKey:@"LOC_VICTORY2"];
        [localizationTable setValue:@"Super!" forKey:@"LOC_VICTORY3"];
        [localizationTable setValue:@"Cool!" forKey:@"LOC_VICTORY4"];
        [localizationTable setValue:@"Great!" forKey:@"LOC_VICTORY5"];
        [localizationTable setValue:@"Destructive!" forKey:@"LOC_MULTIPLIER_CHEER1"];
        [localizationTable setValue:@"Smashing!" forKey:@"LOC_MULTIPLIER_CHEER2"];
        [localizationTable setValue:@"Rampage!" forKey:@"LOC_MULTIPLIER_CHEER3"];
        [localizationTable setValue:@"Frenzy!" forKey:@"LOC_MULTIPLIER_CHEER4"];
        [localizationTable setValue:@"Out of Control!" forKey:@"LOC_MULTIPLIER_CHEER5"];        
        [localizationTable setValue:@"Bronze Medal!" forKey:@"LOC_BRONZE_WON"];
        [localizationTable setValue:@"Silver Medal!" forKey:@"LOC_SILVER_WON"];
        [localizationTable setValue:@"Gold Medal!" forKey:@"LOC_GOLD_WON"];
        [localizationTable setValue:@"NULL" forKey:@"LOC_NULL"];
    }
}

NSString* LocalizeText(eLocalizedString stringId) {
    MaybeInitLocalizationTable();

    if ([stringId caseInsensitiveCompare: kLocalizedString_Null]==NSOrderedSame) {
        return nil;
    }
    
    id value = [localizationTable valueForKey:stringId];
    if (!value) {
        return stringId;
    }
    
    return value;
}

NSString* LocalizeTextArgs(eLocalizedString stringId, NSObject* firstParam, ...) {
    MaybeInitLocalizationTable();
    
    if ([stringId caseInsensitiveCompare: kLocalizedString_Null]==NSOrderedSame) {
        return nil;
    }
    
    id value = [localizationTable valueForKey:stringId];
    if (!value) {
        return stringId;
    }
    
//    va_list args;
//    va_start(args, firstParam);
    return [NSString stringWithFormat:value, firstParam];
}
