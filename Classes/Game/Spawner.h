//
//  Spawner.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/14/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameCommon.h"
#import "OpenGLCommon.h"
#import "Localize.h"
#import "Pinata.h"
#import "Powerup.h"

@class Game;
@class GroupLoad;

@interface Spawner : NSObject {
@public
    Vector2D position;
    float   timeBetween;
    float   initialDelay;
    float   randomDelay;
    float   timeToSpawn;
    Game*   game;
    int     amount;
    int     amountSpawned;
    int     limit;
    float   lifetime;   
}

@property (nonatomic,assign) Game* game;

-(void)tick:(float)timeElapsed;
-(void)trigger;
-(void)reset;

@end

//////////////////////////////////////

@interface PinataSpawner : Spawner {
    Vector2D        velocity;
    float           radius; 
    NSMutableArray* types;
    Boolean         ghosting;
    Boolean         veggies;
}
-(id)initWithGroup:(GroupLoad*)group;
-(void)trigger;
-(void)addType:(ePinataType)t;
@end

//////////////////////////////////////

@interface PowerupSpawner : Spawner {
    NSMutableArray* types;
    ePinataType     pinataType;
    int             numPinatas;
    Boolean         useParachute;
    Boolean         useBungee;
    Boolean         pinataGhosting;
    Boolean         pinataVeggies;
    float           pinataLifetime;
}
-(id)initWithGroup:(GroupLoad*)group;
-(void)trigger;
-(void)addType:(ePowerupType)t;
@end

//////////////////////////////////////

@interface CloudSpawner : Spawner {
    float fractionDogs;
    float fallSpeed;
    float spawnDelay;
}
-(id)initWithGroup:(GroupLoad*)group;
-(void)trigger;
@end


