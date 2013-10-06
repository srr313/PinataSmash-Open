//
//  PauseScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/3/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"
#import "Screen.h"

@interface PauseScreen : Screen {
    Game* game;
}

-(id)initWithFlowManager:(id<FlowManager>)fm andGame:(Game*)g;

@end
