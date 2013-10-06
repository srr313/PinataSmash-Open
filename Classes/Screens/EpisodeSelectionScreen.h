//
//  EpisodeSelectionScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/19/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.


#import <Foundation/Foundation.h>
#import "CrystalPlayer.h"
#import "Screen.h"

@class BankComponent;
@class EpisodeButton;
@class ModalControl;
@class ScrollComponent;

@interface EpisodeSelectionScreen : Screen<CrystalPlayerDelegate> {
    BankComponent*      bank;
    ScrollComponent*    episodeList;
    ModalControl*       bankTip;
    ModalControl*       purchaseOffer;
    EpisodeButton*      lastEpisodeButtonPressed;
    ButtonControl*      moneyGiftButton;
}

-(id)initWithFlowManager:(id<FlowManager>) fm;

@end

