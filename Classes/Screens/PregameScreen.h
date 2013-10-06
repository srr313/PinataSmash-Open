//
//  PregameScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/17/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CrystalPlayer.h"
#import "Screen.h"

@class BankComponent;
@class Game;
@class ModalControl;
@class ToolButton;

@interface PregameScreen : Screen<CrystalPlayerDelegate> {
    Game* game;
    ToolButton* lastToolButtonPressed;
    ModalControl* purchaseOffer;
    ModalControl* bankTip;
    NSMutableArray* toolButtons;
    BankComponent* bank;
}

@end
