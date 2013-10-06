//
//  PullCord.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/25/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameEntity.h"
#import "GameCommon.h"

@class Pinata;

@interface PullCord : NSObject<GameEntity> {
    Vector2D position;
    Vector2D velocity;
    float angle;
    float angularVelocity;
    Pinata* pinata;
    Game* game;
    Boolean alive;
    Boolean locked;
    Boolean stretched;
}

@property (nonatomic) Vector2D position;
@property (nonatomic) Vector2D velocity;
@property (nonatomic) Boolean alive;
@property (nonatomic) Boolean locked;
@property (nonatomic, readonly) float angle;

-(id)initForPinata:(Pinata*)ent forGame:(Game*)g;
-(Boolean)isInside:(CGPoint)p;
-(void)tick:(float) timeElapsed;
-(void)render:(float)timeElapsed;
-(Boolean)trigger;
-(void)addForce:(Vector2D)force;

@end