//
//  Candy.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/13/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameEntity.h"

@class Game;

typedef enum {
    kCandyState_Floating = 0,
    kCandyState_Collected,
} eCandyState;

@interface Candy : NSObject<GameEntity> {
    Vector2D position;
    Vector2D fallStartPosition;
    Vector2D velocity;
    Color3D color;
    JiggleAnimation* animation;
    Boolean alive;
    Game* game;
    float angle;
    float timeFloating;
    float fallingT;
    eCandyState state;
    int particleType;
}

+(Candy*)CreateCandyAt:(Vector2D)p andVelocity:(Vector2D)v forGame:(Game*)g;
+(void)Recycle:(Candy*)c;

-(id)initAtPosition:(Vector2D)p andVelocity:(Vector2D)v forGame:(Game*)g;
-(Boolean)isInside:(CGPoint)p;
-(Boolean)trigger;
-(Boolean)alive;
-(void)tick:(float)timeElapsed;
-(void)addForce:(Vector2D)force;
-(void)render:(float)timeElapsed;

@property (nonatomic) Vector2D position;
@property (nonatomic) Boolean alive;

@end
