//
//  Pinata.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESRenderer.h"
#import "GameEntity.h"
#import "OpenGLCommon.h"

@class Game;
@class JiggleAnimation;
@class PullCord;
@class Texture2D;

#define PINATA_HORIZONTAL_PIECES    2
#define PINATA_VERTICAL_PIECES      2

#define PINATA_MANAGER [PinataManager getPinataManager]

typedef enum {
    kPinataBehavior_Joinable            = 1,
    kPinataBehavior_Cannibal            = 1<<1,
    kPinataBehavior_Edible              = 1<<2,
    kPinataBehavior_Ghost               = 1<<3,
    kPinataBehavior_TimedBomb           = 1<<4,
    kPinataBehavior_Negative            = 1<<5,
    kPinataBehavior_Destroyable         = 1<<6,
    kPinataBehavior_Separable           = 1<<7,
    kPinataBehavior_EatsPile            = 1<<8,
    kPinataBehavior_Helpful             = 1<<9,
    kPinataBehavior_ShortLifetime       = 1<<10,
    kPinataBehavior_Disguised           = 1<<11,
    kPinataBehavior_Spawner             = 1<<12,
    kPinataBehavior_DealDamage          = 1<<13,
    kPinataBehavior_Mountable           = 1<<14,
    kPinataBehavior_TriggersOnShake     = 1<<15,
} ePinataBehavior;

typedef enum {
    kPinataType_Null = 0,       // must be first entry!
    kPinataType_Normal,         //1
    kPinataType_Cannibal,       //2
    kPinataType_Ghost,          //3
    kPinataType_HealthyParts,   //4
    kPinataType_TimedBombParts, //5
    kPinataType_Strong,         //6
    kPinataType_PileEater,      //7
    kPinataType_Hero,           //8
    kPinataType_BreakableHealthy,//9
    kPinataType_MotherPileEater,//10
    kPinataType_WeakCandy,      //11
    kPinataType_UFO,            //12 
    kPinataType_GoodGremlin,    //13 
    kPinataType_BadGremlin,     //14
    kPinataType_Spike,          //15
    kPinataType_Pinhead,        //16
    kPinataType_Treasure,       //17
    kPinataType_Zombie,         //18
    kPinataType_Plane,          //19
    kPinataType_Osmos,          //20
    kPinataType_Chameleon,      //21
    kPinataType_Dog,            //22
    kPinataType_Cat,            //23
    kPinataType_Grower,         //24
    kPinataType_Count,
} ePinataType;

@interface Pinata : NSObject<GameEntity> {
@private
    Game*               game;
    Vector2D            position;
    Vector2D            velocity;
    float               spawnTime;
    JiggleAnimation*    jiggler;
    int                 numParts;
    float               angle;
    Color3D             color;
    ePinataBehavior     behavior;
    ePinataType         type;
    int                 hitPoints;
    float               pulseDamageT;
    NSMutableArray*     pinatasConsumed;
    Boolean             consumed;
    float               scale;
    float               ghostingPulseT;
    float               timedBombT;
    float               bombDetonateTime;
    float               pileEatTimeleft;
    float               pileEatProximity;
    float               pileEatWarmup;
    float               pinataHelpfulLastTrigger;
    ePinataType         spawnType;
    float               spawnerT;
    eTexture            disguise;
    PullCord*           pullCord;
    Pinata*             attachmentPinata;
    Pinata*             cargoPinata;
    Boolean             ghosting;
    Vector2D            floatOffset;
    float               floatingT;
    float               floatingRadius;
    Boolean             veggies;
    float               lifetime;
    Boolean             triggeredByPullCord;
    Boolean             planeLanded;
    Boolean             flipped;
    float               timeTriggered;
    float               expansion;
    float               timeLastPinataConsumed;
    float               disguisePulseT;
    Boolean             inDisguise;
    float               pulseT;
    int                 frame;
    Boolean             active;
    float               lastSpecialT;
        
@public
    ePinataType         parts[PINATA_HORIZONTAL_PIECES][PINATA_VERTICAL_PIECES]; 
}

@property (nonatomic) Vector2D position;
@property (nonatomic) Vector2D velocity;
@property (nonatomic) float spawnTime;
@property (nonatomic) int numParts;
@property (nonatomic) float angle;
@property (nonatomic) ePinataType type;
@property (nonatomic) Color3D color;
@property (nonatomic) int hitPoints;
@property (nonatomic) ePinataBehavior behavior;
@property (nonatomic) float scale;
@property (nonatomic) float expansion;
@property (nonatomic) Boolean consumed;
@property (nonatomic) Boolean veggies;
@property (nonatomic) float pulseDamageT;
@property (nonatomic,assign) Pinata* cargoPinata;
@property (nonatomic,assign) Pinata* attachmentPinata;
@property (nonatomic,assign) PullCord* pullCord;
@property (nonatomic) Boolean triggeredByPullCord;

+(void)renderComment:(float)timeElapsed;
+(void)updateComment:(float)timeElapsed;
+(void)postComment:(NSString*)text atPosition:(Vector2D)position;
+(void)resetComment;

+(Texture2D*)getTexture:(ePinataType)type 
                withHitPoints:(int)hitPoints 
                wasTriggered:(Boolean)triggered
                veggies:(Boolean)veggies                
                frame:(int)frame;

-(id)initForGame:(Game*)g at:(Vector2D)p 
        withVelocity:(Vector2D)v 
        withType:(ePinataType)t 
        withGhosting:(Boolean)ghost
        withVeggies:(Boolean)veggie
        withLifetime:(float)lifetime;
-(void)initData:(Game*)g
        at:(Vector2D)p 
        withVelocity:(Vector2D)v
        withType:(ePinataType)t
        withGhosting:(Boolean)ghost
        withVeggies:(Boolean)veggie
        withLifetime:(float)lifetime;        
-(float)radius;
-(void)tick:(float) timeElapsed atIndex:(int)i;
-(void)merge:(Pinata*)otherPinata;
-(void)split;
-(Boolean)trigger;
-(Boolean)triggerDamage:(int)damage;
-(void)shake;
-(float)distanceTo:(Pinata*)otherPinata;
-(Boolean)isInside:(CGPoint)p;
-(Boolean)isInsidePullCord:(CGPoint)p;
-(Boolean)canJoinWith:(Pinata*)p;
-(void)addAllParts;
-(int)candy;
-(Boolean)isWhole;
-(void)addForce:(Vector2D)force;
-(void)bounce;
-(void)render:(float)timeElapsed;
@end

@interface PinataManager : NSObject {
@private
    NSMutableArray* freePinatas;
}
+(PinataManager*)getPinataManager;
-(id)init;
-(Pinata*)NewPinata:(Game*)g 
        at:(Vector2D)p 
        withVelocity:(Vector2D)v
        withType:(ePinataType)t
        withGhosting:(Boolean)ghosting
        withVeggies:(Boolean)veggies
        withLifetime:(float)lifetime;                
-(void)ReleasePinata:(Pinata*)p;
-(void)clear;
-(void)dealloc;
@end
