//
//  GameEntity.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenGLCommon.h"

@class Game;
@class JiggleAnimation;

@protocol GameEntity<NSObject>
-(Boolean)isInside:(CGPoint)p;
-(Boolean)trigger;
-(void)addForce:(Vector2D)force;
-(void)render:(float)timeElapsed;

@property (nonatomic) Vector2D position;
@end
