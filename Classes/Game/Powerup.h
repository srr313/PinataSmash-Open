//
//  Powerup.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/20/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bungee.h"
#import "GameEntity.h"
#import "OpenGLCommon.h"
#import "Pinata.h"
#import "Parachute.h"

@class Game;
@class JiggleAnimation;

typedef enum {
    kPowerupType_Bomb = 0,  //0
    kPowerupType_Candy,     //1
    kPowerupType_Negative,  //2
    kPowerupType_SlowMotion,//3
    kPowerupType_Shrink,    //4
    kPowerupType_Pinatas,   //5
    kPowerupType_MetricBonus,//6
    kPowerupType_Random,    //7 SHOULD BE AFTER POWERUPS RANDOMLY SELECTED!
    kPowerupType_Count,
} ePowerupType;

@interface Powerup : NSObject<GameEntity, BungeeCargo, ParachuteCargo> {
    Game*           game;
    Vector2D        position;
    Vector2D        velocity;
    float           spawnTime;
    float           lifetime;
    Color3D         color;
    ePowerupType    type;
    ePowerupType    subtype;
    Boolean         alive;    
    float           timeOnState;
    float           angle;
    int             numPinatas;
    ePinataType     pinataType;
    Parachute*      parachute;
    Bungee*         bungee;
    Boolean         pointInsideParachute;
    JiggleAnimation* jiggler;
    Boolean         pinataGhosting;
    Boolean         pinataVeggies;
    float           pinataLifetime;
}

@property (nonatomic) Vector2D position;
@property (nonatomic) Vector2D velocity;
@property (nonatomic) Color3D color;
@property (nonatomic) Boolean alive;
@property (nonatomic,readonly) ePowerupType type;
@property (nonatomic,readonly) ePowerupType subtype;
@property (nonatomic, readonly) float angle;
@property (nonatomic) ePinataType pinataType;
@property (nonatomic,assign) Parachute* parachute;
@property (nonatomic,assign) Bungee* bungee;

-(id)initForGame:(Game*)g at:(Vector2D)p 
                withVelocity:(Vector2D)v 
                andType:(ePowerupType)t 
                andLifetime:(float)lt;
-(id)initPinataTypeForGame:(Game*)g at:(Vector2D)p withVelocity:(Vector2D)v 
                            andLifetime:(float)lt 
                            andPinataType:(ePinataType)t 
                            andNumPinatas:(int)n
                            andPinataGhosting:(Boolean)ghost
                            andPinataVeggies:(Boolean)veggies
                            andPinataLifetime:(float)lifetime;
-(Boolean)isInside:(CGPoint)p;
-(void)tick:(float) timeElapsed;
- (void)render:(float)timeElapsed;
-(Boolean)trigger;
-(void)attach:(Parachute *)chute;
-(void)remove:(Parachute *)chute;
-(void)attachCord:(Bungee *)b;
-(void)removeCord:(Bungee *)b;
-(void)addForce:(Vector2D)force;

@end

