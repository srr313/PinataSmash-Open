//
//  LevelEndScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/25/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlowManager.h"
#import "Screen.h"

@class AchievementModal;
@class BankComponent;
@class Game;
@class ModalControl;

@interface LevelEndScreen : Screen {
@private
    Game* game;
    BankComponent* bank;
    ModalControl* bankTip;
    TextControl* metricCounter;
    TextControl* episodeEndText;
    ButtonControl* continueButton;
    ButtonControl* retryButton;
    ButtonControl* menuButton;
    AchievementModal* achievementModal;
    NSMutableArray* achievements;
    eAchievement medal;
    float metricCounterT;
    int currentMetricCount;
    int medalCash;
    int currentAchievementIndex;
}

-(id)initWithFlowManager:(id<FlowManager>)fm andGame:(Game*)g;
@end
