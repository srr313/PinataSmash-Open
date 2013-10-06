//
//  Tool.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/14/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screen.h"

@class Game;
@class PullCord;

@interface Tool : NSObject {
    eTool       type;
    Game*       game;
    NSDate*     lastTrigger;
    float       triggerDelay;
    int         count;
    PullCord*   lockedPullCord;
    Boolean     started;
}

+(int)getPrice:(eTool)t;
+(eTexture)getTexture:(eTool)t;

@property (nonatomic) eTool type;
@property (nonatomic, readonly) int count;

-(id)initType:(eTool)t forGame:(Game*)g;
-(void)triggerAt:(TapEvent)tapEvent;
-(void)stop;

@end
