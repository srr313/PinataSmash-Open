//
//  Spawner.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/14/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import "Spawner.h"
#import "EAGLView.h"
#import "Game.h"
#import "GameLevel.h"
#import "LevelLoader.h"
#import "Particles.h"
#import "SaveGame.h"
#import "WeatherCloud.h"

@interface Spawner()
-(void)resetSpawnTime;
@end


@implementation Spawner

@synthesize game;

-(void)tick:(float)timeElapsed {
    if (amountSpawned < amount) {
        timeToSpawn -= timeElapsed;
        if (timeToSpawn < 0.0f) {
            [self resetSpawnTime];
            [self trigger];
            ++amountSpawned;
        }
    }
}

-(void)reset {
    amountSpawned = 0.0f;
    timeToSpawn = initialDelay;
}

-(void)resetSpawnTime {
    timeToSpawn = timeBetween+randomDelay*random()/(float)RAND_MAX;
}

-(void)trigger {}

@end

//////////////////////////////////////

@implementation PinataSpawner

-(id)initWithGroup:(GroupLoad*)group {
    if (self = [super init]) {
        position        = ([group hasAttribute:@"POSITION"]) 
                            ? [group getAttributePosition:@"POSITION"] : InfVector();
        velocity        = ([group hasAttribute:@"VELOCITY"]) 
                            ? [group getAttributeVector2D:@"VELOCITY"] : InfVector();
        radius          = [group getAttributeFloat:@"RADIUS"] * M_PI / 180.0f;
        timeBetween     = [group getAttributeFloat:@"TIME_BETWEEN"];
        initialDelay    = [group getAttributeFloat:@"INITIAL_DELAY"];
        randomDelay     = [group getAttributeFloat:@"RANDOM_DELAY"];
        amount          = [group getAttributeInt:@"AMOUNT"];
        limit           = [group getAttributeInt:@"LIMIT"];
        ghosting        = [group getAttributeBool:@"GHOSTING"];
        veggies         = [group getAttributeBool:@"VEGGIES"];
        lifetime        = [group getAttributeFloat:@"LIFETIME"];         
        
        types = [[NSMutableArray alloc] init];
        int type = [group getAttributeInt:@"TYPE"];
        [self addType:type];
    }
    return self;
}

-(void)addType:(ePinataType)t {
    [types addObject:[NSNumber numberWithInt:t]];
}

-(void)trigger {
    Vector2D screenDimensions = GetGLDimensions();
    Vector2D screenCenter = Vector2DMul(screenDimensions,0.5f);
    Vector2D toCenter = Vector2DSub(screenCenter, position);
    Vector2DNormalize(&toCenter);
    Vector2D v = velocity;
    
    Vector2D spawnLocation =
        (position.x == FLT_MAX) 
            ? MakeRandScreenVector()
            : position;
    
    if (velocity.x == FLT_MAX) { 
        v = (spawnLocation.x < 0.0f || spawnLocation.x > screenDimensions.x 
                || spawnLocation.y < 0 || spawnLocation.y > screenDimensions.y)
            ? Vector2DMul(toCenter, 400.0f) 
            : ZeroVector();
    }
    
    if (radius > 0.0f && !IsZeroVector(v)) {
        // direct randomly within cone
        float angle = atan2f(v.y, v.x) + radius*(random()/(float)RAND_MAX-0.5f);
        v = Vector2DMul(Vector2DMake(cosf(angle),sinf(angle)), Vector2DMagnitude(v));
    }
    
    int randIndex = random()%types.count;
    NSNumber* obj = [types objectAtIndex:randIndex];
    ePinataType type = (ePinataType)[obj intValue];
    
    NSMutableArray* pinatas = [game getPinatas];
    int pinataCount = 0;
    
    for (Pinata* p in pinatas) {
        if (p.type == type && p.veggies == veggies) {
            ++pinataCount;
        }
    }
    
    if (limit <= 0 || pinataCount+1 <= limit) {
        // todo use random position if inf Vector
    
        Pinata* spawned =
            [PINATA_MANAGER NewPinata:      game 
                            at:             spawnLocation 
                            withVelocity:   v
                            withType:       type
                            withGhosting:   ghosting
                            withVeggies:    veggies
                            withLifetime:   lifetime];                
        [spawned addAllParts];

        [pinatas addObject:spawned];
        [spawned release];
        
        [PARTICLE_MANAGER createMistAt: spawnLocation 
                            withColor:  COLOR3D_YELLOW
                            withScale:  1.0f]; 
    }
}

-(void)dealloc {
    [types release];
    [super dealloc];
}

@end

//////////////////////////////////////

@implementation PowerupSpawner

-(id)initWithGroup:(GroupLoad*)group {
    if (self = [super init]) {
        position        = [group getAttributePosition:@"POSITION"];
        timeBetween     = [group getAttributeFloat:@"TIME_BETWEEN"];
        initialDelay    = [group getAttributeFloat:@"INITIAL_DELAY"];
        randomDelay     = [group getAttributeFloat:@"RANDOM_DELAY"];
        amount          = [group getAttributeInt:@"AMOUNT"];
        limit           = [group getAttributeInt:@"LIMIT"];
        lifetime        = [group getAttributeFloat:@"LIFETIME"];
        numPinatas      = [group getAttributeInt:@"PINATA_AMOUNT"];
        pinataType      = [group getAttributeInt:@"PINATA_TYPE"];
        pinataGhosting  = [group getAttributeBool:@"PINATA_GHOSTING"];
        pinataVeggies   = [group getAttributeBool:@"PINATA_VEGGIES"];    
        pinataLifetime  = [group getAttributeFloat:@"PINATA_LIFETIME"];        
        useParachute    = [group getAttributeBool:@"USE_PARACHUTE"];
        useBungee       = [group getAttributeBool:@"USE_BUNGEE"];

        types = [[NSMutableArray alloc] init];
        int type = [group getAttributeInt:@"TYPE"];    
        [self addType:type];
    }
    return self;
}

-(void)addType:(ePowerupType)t {
    [types addObject:[NSNumber numberWithInt:t]];
}

-(void)trigger {
    Vector2D screenCenter = Vector2DMul(GetGLDimensions(),0.5f);
    Vector2D toCenter = Vector2DSub(screenCenter, position);
    Vector2DNormalize(&toCenter);
    Vector2D velocity = Vector2DMul(toCenter, 600.0f);
    
    int randIndex = random()%types.count;
    NSNumber* obj = [types objectAtIndex:randIndex];
    ePowerupType type = (ePowerupType)[obj intValue];

    Parachute* parachute = nil;
    if (useParachute) {
        parachute = [[Parachute alloc]  initAt:         position 
                                        withTexture:    kTexture_BalloonBegin+rand()%(kTexture_BalloonEnd-kTexture_BalloonBegin)
                                        forGame:        game];
    }

    Bungee* bungee = nil;
    if (useBungee) {
        bungee = [[Bungee alloc] initAt:position forGame:game];
    }
    
    NSMutableArray* powerups = [game getPowerups];
    int powerupCount = 0;

    for (Powerup* p in powerups) {
        if (p.type == type) {
            ++powerupCount;
        }
    }
    
    if (limit <= 0 || powerupCount+1 <= limit) {
        Powerup* spawned;
        if (type == kPowerupType_Pinatas) {
            spawned = [[Powerup alloc]
                        initPinataTypeForGame:  game
                        at:                     position
                        withVelocity:           velocity
                        andLifetime:            lifetime
                        andPinataType:          pinataType
                        andNumPinatas:          numPinatas
                        andPinataGhosting:      pinataGhosting
                        andPinataVeggies:       pinataVeggies
                        andPinataLifetime:      pinataLifetime];
        }
        else {
            spawned = [[Powerup alloc] 
                        initForGame:    game 
                        at:             position 
                        withVelocity:   velocity
                        andType:        type
                        andLifetime:    lifetime];
        }
        
        if (parachute) {
            [spawned attach:parachute];            
            [parachute release];
        }
        else if (bungee) {
            [spawned attachCord:bungee];
            [bungee release];
        }
        else {
            [PARTICLE_MANAGER createMistAt: position 
                                withColor:  COLOR3D_YELLOW
                                withScale:  1.0f];     
        }
        
        [[game getPowerups] addObject:spawned];
        [spawned release];
    }
}

-(void)dealloc {
    [types release];
    [super dealloc];
}

@end

///////////////////////////////

@implementation CloudSpawner

-(id)initWithGroup:(GroupLoad*)group {
    if (self = [super init]) {
        amount          = [group getAttributeInt:@"AMOUNT"];    
        timeBetween     = [group getAttributeFloat:@"TIME_BETWEEN"];
        initialDelay    = [group getAttributeFloat:@"INITIAL_DELAY"];
        randomDelay     = [group getAttributeFloat:@"RANDOM_DELAY"];
        lifetime        = [group getAttributeFloat:@"LIFETIME"];        
        
        fractionDogs    = [group getAttributeFloat:@"FRACTION_DOGS"];
        fallSpeed       = [group getAttributeFloat:@"FALL_SPEED"];  
        spawnDelay      = [group getAttributeFloat:@"SPAWN_DELAY"];                         
    }
    return self;
}

-(void)trigger {
    game.cloud.fractionDogs     = fractionDogs;
    game.cloud.fallSpeed        = fallSpeed; 
    game.cloud.spawnDelay       = spawnDelay;
    game.cloud.lifetime         = lifetime;
    [game setRainMode:true];
}

@end


