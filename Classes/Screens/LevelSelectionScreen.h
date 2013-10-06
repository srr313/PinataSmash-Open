//
//  LevelSelectionScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/15/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CrystalPlayer.h"
#import "GameCommon.h"
#import "Screen.h"

@class BankComponent;
@class LevelButton;
@class ModalControl;
@class ToolButton;

@interface LevelSelectionScreen : Screen<CrystalPlayerDelegate> {
    NSString* episodePath;
    BankComponent*  bank;
    ModalControl*   bankTip;
    ModalControl*   purchaseOffer;
    LevelButton*    lastLevelButtonPressed;
    ButtonControl*  moneyGiftButton;
    NSMutableArray* levelButtons;
    float           totalTimeElapsed;
    int             currentLevelIndex;
}

-(id)initWithFlowManager:(id<FlowManager>) fm andEpisodePath:(NSString*)path;

@end
