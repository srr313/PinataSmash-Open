//
//  GameoverScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/21/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlowManager.h"
#import "Game.h"
#import "Screen.h"

@class Game;
@class ModalControl;

@interface GameoverScreen : Screen {
@private
    Game* game;
    ModalControl* purchaseModal;
}

-(id)initWithFlowManager:(id<FlowManager>)fm andGame:(Game*)g;
-(void)dealloc;

@end
