//
//  Parachute.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/31/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameEntity.h"
#import "GameCommon.h"
#import "ESRenderer.h"

@class Game;
@class Parachute;

@protocol ParachuteCargo
-(void)attach:(Parachute*)parachute;
-(void)remove:(Parachute*)parachute;
@end

@interface Parachute : NSObject<GameEntity> {
    Vector2D position;
    Vector2D velocity;
    float cargoOffset;
    float angle;
    float angularVelocity;
    id<ParachuteCargo> cargo;
    Game* game;
    Boolean alive;
    float t;
    eTexture tex;
}

@property (nonatomic) Vector2D position;
@property (nonatomic) Vector2D velocity;
@property (nonatomic) Boolean alive;
@property (nonatomic, readonly) float angle;
@property (nonatomic, readonly) float cargoOffset;

-(id)initAt:(Vector2D)p withTexture:(eTexture)tx forGame:(Game*)g;
-(Boolean)isInside:(CGPoint)p;
-(void)tick:(float) timeElapsed;
-(void)render:(float)timeElapsed;
-(Boolean)trigger;
-(void)attatch:(id<ParachuteCargo>)c;
-(void)addForce:(Vector2D)force;
-(void)releaseCargo;

@end
