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

@class Bungee;

@protocol BungeeCargo
-(void)attachCord:(Bungee*)bungee;
-(void)removeCord:(Bungee*)bungee;
@end

@interface Bungee : NSObject<GameEntity> {
    Vector2D    position;
    Vector2D    velocity;
    Vector2D    cargoPosition;
    float       angle;
    float       angularVelocity;
    float       alpha;
    id<BungeeCargo> cargo;
    Game*       game;
    Boolean     alive;
}

@property (nonatomic) Vector2D position;
@property (nonatomic) Vector2D velocity;
@property (nonatomic) Boolean alive;
@property (nonatomic) float alpha;
@property (nonatomic, readonly) float angle;
@property (nonatomic, readonly) Vector2D cargoPosition;

-(id)initAt:(Vector2D)p forGame:(Game*)g;
-(Boolean)isInside:(CGPoint)p;
-(void)tick:(float) timeElapsed;
-(void)render:(float)timeElapsed;
-(Boolean)trigger;
-(void)attatch:(id<BungeeCargo>)c;
-(void)addForce:(Vector2D)force;

@end
