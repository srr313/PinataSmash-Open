//
//  Pinata.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "Pinata.h"
#import "CandyPile.h"
#import "EAGLView.h"
#import "ESRenderer.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "GameParameters.h"
#import "JiggleAnimation.h"
#import "LevelEnvironment.h"
#import "Particles.h"
#import "PullCord.h"
#import "MetagameManager.h"
#import "Sounds.h"

#define MIN_SPLIT_ENERGY        10.0f
#define BOMB_PART_DESTROY_RADIUS 50.0f
#define GHOST_HIDDEN_ALPHA      0.3f
#define CANNIBAL_HIT_POINTS     3
#define STRONG_HIT_POINTS       3
#define MOTHER_EATER_HIT_POINTS 4
#define UFO_HIT_POINTS          5
#define PINATA_MAX_PIECES       (PINATA_HORIZONTAL_PIECES*PINATA_VERTICAL_PIECES)
#define BONUS_PULSE_RATE        7.5f
#define PILE_TOP_PADDING        0.9f
#define PINATA_TRIGGER_TIME     0.5f
#define UFO_FRAMES              4
#define UFO_FRAME_DURATION      8
#define FAIRY_FRAMES            2
#define FAIRY_FRAME_DURATION    4


float lerpAngle(float start, float end, float t) {
    if (end < 0.0f) {
        end += TWO_PI;
    }

    float deltaAngle    = end-start;
    float incrAngle     = (deltaAngle > M_PI) ? deltaAngle-TWO_PI : deltaAngle;
    float angle         = start + t * incrAngle;
    if (angle > TWO_PI) {
        angle -= TWO_PI;
    }
    else if (angle < 0.0f) {
        angle += TWO_PI;
    }
    
    return angle;
}

@implementation PinataManager

+(PinataManager*)getPinataManager {
    static PinataManager* sPinataManager = nil;
    if (sPinataManager == nil) {
        sPinataManager = [[PinataManager alloc] init];
    }
    return sPinataManager;    
}

-(id)init {
    if (self == [super init]) {
        freePinatas = [[NSMutableArray alloc] initWithCapacity:100];
    }            
    return self;
}

-(Pinata*)NewPinata:(Game*)g 
        at:(Vector2D)pos
        withVelocity:(Vector2D)v
        withType:(ePinataType)t
        withGhosting:(Boolean)ghost
        withVeggies:(Boolean)veggies
        withLifetime:(float)lifetime { 
        
    Pinata* p = nil;
    if (freePinatas.count > 0) {
        p = [[freePinatas lastObject] retain];
        [freePinatas removeLastObject];
        
        [p initData:g at:pos 
            withVelocity:v 
            withType:t 
            withGhosting:ghost 
            withVeggies:veggies
            withLifetime:lifetime];
    }
    else {
        p = [[Pinata alloc] 
                initForGame:g at:pos 
                withVelocity:v 
                withType:t 
                withGhosting:ghost
                withVeggies:veggies
                withLifetime:lifetime];
    }
    return p;
}

-(void)ReleasePinata:(Pinata*)p {
    [freePinatas addObject:p];
}

-(void)clear {
    [freePinatas release];
}

-(void)dealloc {
    [self clear];
    [super dealloc];
}

@end

@interface Pinata()
+(void)updateComment:(float)timeElapsed;
//-(void)updateCenterOfMass;
-(void)jiggleFromWall:(float)impactSpeed;
-(void)removeAllParts;
-(void)floatMotion:(float)timeElapsed;
-(void)updateMotion:(float)timeElapsed;
-(void)handleBounds;
-(void)stayInBounds;
-(void)getPileDirection:(Vector2D*)direction 
        andDistance:(float*)distance 
        andTopOfPile:(Vector2D*)topOfPile
        withProximity:(float)proximity;
-(void)maybeEatPile:(float)timeElapsed;
-(float)minimumPileDistanceToEat;
-(void)updateSpawnerBehavior:(float)timeElapsed;
-(void)updateDealDamageBehavior:(float)timeElapsed;
-(void)updateTimeBombBehavior:(float)timeElapsed;
-(void)updateEatsPileBehavior:(float)timeElapsed;
-(void)updateHelpfulBehavior:(float)timeElapsed;
-(void)updateCannibalBehavior:(float)timeElapsed;
-(void)updateJoinableBehavior:(float)timeElapsed atIndex:(int)i;
-(void)updateZombie:(float)timeElapsed;
-(Boolean)helpfulAttackPinata:(Pinata*)p;
-(void)releaseConsumedPinatas;
-(void)consumePinata:(Pinata*)p;
-(void)releaseCandy;
-(void)setBehaviorByType;
-(void)drawWithShadowPass:(Boolean)shadowPass;
-(void)drawPartsWithShadowPass:(Boolean)shadowPass;
-(void)drawBeam;
-(void)addPinataCargo:(Pinata*)p;
-(void)removePinataCargo;
-(void)kill;
-(void)triggerPinatasAt:(Vector2D)p withinDistance:(float)distance;
-(void)convertToHealthy:(Pinata*) p;
-(Texture2D*)getTexture;
@end

@implementation Pinata

@synthesize position, velocity, spawnTime, numParts, angle,
            type, color, behavior, hitPoints, scale, expansion,
            consumed, veggies, pulseDamageT, attachmentPinata, 
            cargoPinata, pullCord, triggeredByPullCord;


static ImageControl* sComment            = nil;
static float         sCommentLastTime    = 0.0f;

+(void)renderComment:(float)timeElapsed {
    [sComment render:timeElapsed];
}

+(void)updateComment:(float)timeElapsed {
        // todo animation
    [sComment tick:timeElapsed];
    sCommentLastTime += timeElapsed;
    
    sComment.position = Vector2DAdd(sComment.position, Vector2DMake(0.0f,48.0f*timeElapsed));
    
    if (sCommentLastTime > 0.75f && sComment.fade == kFade_Stop && sComment.baseAlpha > 0.0f ) {
        [sComment setFade:kFade_Out];
    }
}

+(void)resetComment {
    [sComment release];
    sComment = nil;
}

+(void)postComment:(NSString*)text atPosition:(Vector2D)position {    
    if (sCommentLastTime > 2.0f) {
        [Pinata resetComment];
        
        sComment = [[TextControl alloc] 
                       initAt:ZeroVector()
                       withText:text
                       andArg:nil
                       andDimensions:Vector2DMake(96,20.0f) 
                       andAlignment:UITextAlignmentCenter 
                       andFontName:DEFAULT_FONT andFontSize:18];
        sComment.jiggling   = true;
        sComment.tilting    = true;
        sComment.hasShadow  = false;
        [sComment setColor:COLOR3D_BLUE];            
        
        position.x = fminf(position.x, GetGLWidth()-ToGameScaleX(128.0f));
        position.x = fmaxf(position.x, ToGameScaleX(128.0f));
        sComment.position = position;
        
        [sComment setFadeDelay:0.0f];    
        [sComment setFade:kFade_In];
        [sComment bounce:1.25f];
        
        sCommentLastTime = 0.0f;    
    }
}

#define PinataPartInRange(i,j) ((i>=0 && i<PINATA_HORIZONTAL_PIECES) && (j>=0 && j<PINATA_VERTICAL_PIECES))

-(id)initForGame:(Game*)g 
        at:(Vector2D)pos
        withVelocity:(Vector2D)v
        withType:(ePinataType)t 
        withGhosting:(Boolean)ghost
        withVeggies:(Boolean)veggie
        withLifetime:(float)life {
    if (self == [super init]) {
        [self initData:g 
                at:pos 
                withVelocity:v 
                withType:t 
                withGhosting:ghost
                withVeggies:veggie
                withLifetime:life];
    }
    return self;
}

-(void)initData:(Game*)g 
        at:(Vector2D)p 
        withVelocity:(Vector2D)v
        withType:(ePinataType)t
        withGhosting:(Boolean)ghost
        withVeggies:(Boolean)veggie
        withLifetime:(float)life {
    game = g;

    if (!jiggler) {
        jiggler = [[JiggleAnimation alloc] init];
    }
    [jiggler jiggleFreq:15.0f andAmplitude:0.1f andDuration:0.5f];
    
    [pinatasConsumed removeAllObjects];
    if (!pinatasConsumed) {
        pinatasConsumed = [[NSMutableArray alloc] init];
    }

    [self removeAllParts];

    position                    = p;
    velocity                    = v;
    spawnTime                   = 0.0f;
    angle                       = 0.0f;
    color                       = COLOR3D_WHITE;
    hitPoints                   = 0;
    pulseDamageT                = 1.0f;
    scale                       = 1.0f;
    type                        = t;
    consumed                    = false;
    ghostingPulseT              = 0.0f;
    pileEatTimeleft             = 0.0f;
    pileEatWarmup               = 0.0f;
    pinataHelpfulLastTrigger    = 0.0f;
    spawnerT                    = 0.0f;
    bombDetonateTime            = 0.0f;
    timedBombT                  = 0.0f;
    attachmentPinata            = nil;
    cargoPinata                 = nil;  
    ghosting                    = ghost;
    veggies                     = veggie;
    floatingT                   = TWO_PI*random()/RAND_MAX;
    lifetime                    = life;
    floatingRadius              = 15.0f;
    pullCord                    = nil;
    triggeredByPullCord         = false;
    planeLanded                 = false;
    flipped                     = false;
    timeTriggered               = FLT_MAX;
    expansion                   = 1.0f;
    timeLastPinataConsumed      = 0.0f;
    disguisePulseT              = 0.0f;
    inDisguise                  = false;
    frame                       = 0;
    active                      = true;
    lastSpecialT                = 9999.0f;
        
    [self setBehaviorByType];    
}

-(float)radius {
    if ((behavior&kPinataBehavior_Cannibal)!=0) {
        return  expansion * scale 
                * jiggler.scale 
                * GetTextureDimensions(kTexture_PinataEaterBegin).x/4
                * sqrt(pinatasConsumed.count+1.0f);
    }
    return scale * expansion * jiggler.scale * [self getTexture].pixelsWide/2;
}

-(void)jiggleFromWall:(float)impactSpeed {
    [jiggler jiggleFreq:0.04f*impactSpeed andAmplitude:0.0003f*impactSpeed andDuration:0.5f];
}

-(void)tick:(float)timeElapsed atIndex:(int)i {    
    spawnTime += timeElapsed;
    if (numParts <= 0 || consumed) {
        return;
    }
    
    timeTriggered += timeElapsed;
    
    if (timeTriggered <= PINATA_TRIGGER_TIME) {
        if (type == kPinataType_Pinhead) {
            expansion = 1.0f + GAME_PARAMETERS.pinheadDestroyRadius
                                *sinf(M_PI*timeTriggered/PINATA_TRIGGER_TIME);
        }
    }

    [jiggler tick:timeElapsed];
    
    [self updateMotion:timeElapsed];

    position = Vector2DAdd(position, Vector2DMul(velocity, timeElapsed));
        
    if (pulseDamageT < 1.0f) {
        pulseDamageT = fminf(timeElapsed+pulseDamageT,1.0f);
        color.alpha = fminf(fabsf(1.0f-10.0f*pulseDamageT),1.0f);
    }
    
    {
        if ((behavior&kPinataBehavior_EatsPile)!=0) {
            [self updateEatsPileBehavior:timeElapsed];
        }
    
        if ((behavior&kPinataBehavior_Joinable)!=0) {
            [self updateJoinableBehavior:timeElapsed atIndex:i];
        }
            
        if ((behavior&kPinataBehavior_Cannibal)!=0) {
            [self updateCannibalBehavior:timeElapsed];
        }
        
        if ((behavior&kPinataBehavior_Helpful)!=0) {
            [self updateHelpfulBehavior:timeElapsed];
        }
            
        if ((behavior&kPinataBehavior_TimedBomb)!=0) {
            [self updateTimeBombBehavior:timeElapsed];
        }
        
        if ((behavior&kPinataBehavior_Spawner)!=0) {
            [self updateSpawnerBehavior:timeElapsed];
        }
        
        if ((behavior&kPinataBehavior_DealDamage)!=0) {
            [self updateDealDamageBehavior:timeElapsed];
            
            if ((behavior&kPinataBehavior_ShortLifetime)!=0) {
                color.alpha = fminf( fmaxf(0.0f, 5.0f*(lifetime-spawnTime)), 1.0f );
                if (spawnTime > lifetime) {
                    [self kill];
                    return;
                }
            }
        }
                
        if ((behavior&kPinataBehavior_Ghost)!=0) {
            ghostingPulseT += timeElapsed;        
            
            Boolean wasHidden = (color.alpha == GHOST_HIDDEN_ALPHA);
            Boolean nowHidden = (fabsf(sinf(M_PI*ghostingPulseT/2))<0.5f);
        
            if (wasHidden != nowHidden) {
                color.alpha = nowHidden ? GHOST_HIDDEN_ALPHA : 1.0f;
                [self bounce];
            }
        }
        
        if ((behavior&kPinataBehavior_Disguised)!=0) {
            disguisePulseT += timeElapsed;
            
            float pace = kPinataType_Grower ? 0.0f : 0.5f;
            Boolean wasDisguised = inDisguise;
            inDisguise = sinf(M_PI*disguisePulseT/2.0f)<pace;
            
            if (wasDisguised != inDisguise) {
                [self bounce];
            }
        }
        
        if (type == kPinataType_Zombie) {
            [self updateZombie:timeElapsed];
        }
    }
    
    [self handleBounds];
    
    [pullCord tick:timeElapsed];
}

-(void)updateZombie:(float)timeElapsed {
    if (!cargoPinata) {
        disguisePulseT += timeElapsed;
        Boolean wasDisguised = inDisguise;            
        inDisguise      = sinf(M_PI*disguisePulseT/2.0f) < 0.5f;            
        if (wasDisguised != inDisguise) {
            angle = 0.0f;
            if (inDisguise) {
                color.alpha = 0.0f;
                active      = false;
            }
            else {
                position    = MakeRandScreenVector();        
                velocity    = ZeroVector();
                color.alpha = 1.0f;
                active      = true;
            }
            [PARTICLE_MANAGER createSmokePuffAt:position withScale:1.0f withLayer:kLayer_Game];                    
        }   
    }
    
    if (!inDisguise && active) {
        NSMutableArray* nearPinatas = [game findPinatasNear:position 
                                            withinDistance:[self radius]];
        for (Pinata* p in nearPinatas) {
            if (p != self && !p.veggies && (p.behavior&kPinataBehavior_Edible)!=0) {
                active = false;
                [self convertToHealthy:p];
                [self bounce];
                break;
            }
        }                    
        [nearPinatas release];            
    }
}

-(void)handleBounds {
    const float kBoundsPadding = 128.0f;
    if ((behavior&kPinataBehavior_ShortLifetime)!=0 && spawnTime > lifetime) {        
        if (position.x > game.labWidth+kBoundsPadding && velocity.x > 0.0f
                || position.x < -kBoundsPadding && velocity.x < 0.0f
                || position.y > game.labHeight+kBoundsPadding && velocity.y > 0.0f
                || position.y < -kBoundsPadding && velocity.y < 0.0f) {
            [self kill];
        }
    }
    else {
        [self stayInBounds];
    }
}

-(void)updateMotion:(float)timeElapsed {
    float speed = Vector2DMagnitude(velocity);

    // drag
    if (speed > 10.0f) {    
        velocity = Vector2DSub(velocity, 
                        Vector2DMul(velocity, timeElapsed*GAME_PARAMETERS.pinataDrag));

        // clamp speed
        if (speed > GAME_PARAMETERS.maxPinataSpeed+1.0f) {
            Vector2DNormalize(&velocity);
            velocity = Vector2DMul(velocity, GAME_PARAMETERS.maxPinataSpeed);
        }
    }
    
    if (type == kPinataType_Pinhead && speed > GAME_PARAMETERS.pinheadMaxSpeed) {
        Vector2DNormalize(&velocity);
        velocity = Vector2DMul(velocity, GAME_PARAMETERS.pinheadMaxSpeed);        
    }
        
    if ((behavior&kPinataBehavior_Cannibal)==0 
            && (behavior&kPinataBehavior_Helpful)==0
            && (behavior&kPinataBehavior_EatsPile)==0) {
            
        if (speed < 50.0f) {
            [self floatMotion:timeElapsed];
        }
            
        angle += 0.01f*speed*timeElapsed;     
    }
}

-(void)updateTimeBombBehavior:(float)timeElapsed { 
    int i = timedBombT/bombDetonateTime;
    timedBombT = timedBombT+timeElapsed;
    int j = timedBombT/bombDetonateTime;
    
    if (j-i > 0) {            
        float explosionScale = BOMB_PART_DESTROY_RADIUS/GetTextureDimensions(kTexture_SmallExplosion).x;
        [PARTICLE_MANAGER createExplosionAt:position withScale:explosionScale withLarge:false withLayer:kLayer_Game]; 
        
        [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_SmallExplosion)];            
                    
        if (numParts <= 1) {
            velocity = MakeRandVector2D(GAME_PARAMETERS.splitSpeed);            
        }
        else {
            [self split];
        }
    }
}

-(void)updateDealDamageBehavior:(float)timeElapsed {
    NSMutableArray* pinatas = [game getPinatas];
    for (Pinata* p in pinatas) {
        if (p != self 
                && p.hitPoints > 0 
                && p.type != kPinataType_Spike 
                && spawnTime > 0.25f
                && Vector2DDistance(p.position,position)<32.0f) {
            [self kill];
            [p trigger];
            break;
        }
    }    
}

-(void)updateSpawnerBehavior:(float)timeElapsed {
    int i = spawnerT/GAME_PARAMETERS.motherPileEaterBirthWait;
    spawnerT = spawnerT+timeElapsed;
    int j = spawnerT/GAME_PARAMETERS.motherPileEaterBirthWait;
    
    if (j-i > 0) {            
        Pinata* spawned =
            [PINATA_MANAGER NewPinata:game 
                                at:Vector2DSub(position,Vector2DMake(0.0f,-[self radius]))
                                withVelocity:Vector2DMake(0.0f,-500.0f) 
                                withType:spawnType
                                withGhosting:ghosting
                                withVeggies:veggies
                                withLifetime:lifetime];
        [spawned addAllParts];

        NSMutableArray* pinatas = [game getPinatas];
        [pinatas addObject:spawned];
        [spawned release];
        [jiggler jiggleFreq:15.0f andAmplitude:0.25f andDuration:1.0f];
          
        [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_EaterSpawn)]; 
    }
}

-(void)updateEatsPileBehavior:(float)timeElapsed {
    NSAssert(behavior!=kPinataBehavior_EatsPile,@"Pinata::updateEatsPileBehavior - Invalid pinata");
    
    lastSpecialT += timeElapsed;
    
    Vector2D dir;
    Vector2D topOfPile;
    float distance;
    [self getPileDirection:&dir     
            andDistance:&distance 
            andTopOfPile:&topOfPile 
            withProximity:pileEatProximity];
    
    if (distance > 1.0f) {
        if (type == kPinataType_Plane) {
            velocity = Vector2DMul(dir, 150.0f);
        }
        else {
            float forceMagnitude = 2.5f;
            Vector2D force = Vector2DMul(dir, forceMagnitude);
            velocity = Vector2DAdd(velocity,force); 
        }
    }
    
    Boolean withinEatingDistance = (distance < [self minimumPileDistanceToEat]);
    if (withinEatingDistance) {
        float dot = Vector2DDotProduct(velocity, dir);
        velocity = Vector2DSub(velocity, Vector2DMul(dir, dot));
        velocity = Vector2DMul(velocity, 0.95f);
        
        pileEatTimeleft -= timeElapsed;
                
        if (pileEatTimeleft <= 0.0f) {
            [self maybeEatPile:timeElapsed];
        }
    }
    else {
        pileEatWarmup = fmaxf(0.0f, pileEatWarmup-timeElapsed);
    }
    
    if (type==kPinataType_PileEater) {
        if (Vector2DMagnitude(velocity) < 0.1f) {
            Vector2D perp = Vector2DMake(2.0f*(random()%2)-1.0f, 0.0f);
            velocity = Vector2DAdd(Vector2DMul(perp, 10.0f), velocity);
        }
             
        float targetAngle = (distance<2.0f*[self minimumPileDistanceToEat])
                                ? 0.0f : atan2f(velocity.y,velocity.x);
        angle = lerpAngle(angle, targetAngle, 10.0f*timeElapsed);         
    }
    else {        
        [self floatMotion:timeElapsed];      
    }        
}

-(void)getPileDirection:(Vector2D*)direction 
        andDistance:(float*)distance 
        andTopOfPile:(Vector2D*)top
        withProximity:(float)proximity {
        
    CandyPile* pile = [game getCandyPile];
    Vector2D topOfPile = Vector2DMake(position.x,
                                PILE_TOP_PADDING * [pile getForegroundHeight] 
                                    * [pile getJiggleScale]
                                    * (1.0f+0.25f*sinf(position.x))
                                     + proximity);
                    
    (*top)              = topOfPile;
    Vector2D dir        = Vector2DSub(topOfPile, position);
    (*distance)         = Vector2DMagnitude(dir);
    Vector2DNormalize(&dir);    
    (*direction)        = dir;
}

-(void)maybeEatPile:(float)timeElapsed {
    if (type == kPinataType_PileEater) {
        [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_EatOneCandy)]; 

        [game addCandy:-GAME_PARAMETERS.pileEaterEatAmount useMultiplier:false];
                    
        [PARTICLE_MANAGER createCandyExplosionAt:position withAmount:3 withLayer:kLayer_Game];            
        pileEatTimeleft = GAME_PARAMETERS.pileEaterEatDelay;

        [jiggler jiggleFreq:15.0f andAmplitude:0.25f andDuration:1.0f];
    }
    else if (type == kPinataType_GoodGremlin) {
        if (pileEatWarmup <= 1.0f) {
            pileEatWarmup += 0.5f*timeElapsed;
            color.green = color.blue = 1.0f - pileEatWarmup;
        }
        else {
            [self kill];
            [PARTICLE_MANAGER 
                createConfettiAt:position withAmount:5 withLayer:kLayer_Game];
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_EaterSpawn)];             
            
            NSMutableArray* pinatas = [game getPinatas];  
            [Pinata postComment:@"Grrrr!" atPosition:position];  
            for (int i = 0; i < 4; ++i) {
                Pinata* spawned =
                    [PINATA_MANAGER NewPinata:game 
                                        at:position
                                        withVelocity:Vector2DMake(300.0f*(random()/(float)RAND_MAX-0.5f),500.0f) 
                                        withType:kPinataType_BadGremlin
                                        withGhosting:ghosting
                                        withVeggies:false
                                        withLifetime:FLT_MAX];

                [pinatas addObject:spawned];
                [spawned release];
            }
        }
    }
    else if (type == kPinataType_UFO) {
        if (pileEatWarmup <= 1.0f) {
            float prevWarmup = pileEatWarmup;
            pileEatWarmup   += timeElapsed;
            
            // just started beam
            if (prevWarmup <= 0.0f && pileEatWarmup > 0.0f) {
                if (lastSpecialT > 1.0f) {
                    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_UFOBeam)];            
                    lastSpecialT = 0.0f;
                }
            }
        }
        else {
            [game addCandy:-GAME_PARAMETERS.ufoEatAmount useMultiplier:false];
            pileEatTimeleft = GAME_PARAMETERS.ufoEatDelay;
                                         
            Vector2D d;
            Vector2D topOfPile;
            float distance;
            [self getPileDirection:&d andDistance:&distance andTopOfPile:&topOfPile withProximity:0.0f];
            
            Vector2D dir = Vector2DSub(position,topOfPile);
            Vector2DNormalize(&dir);
                        
            const float kSpeed = 400.0f;                                                                                                                                                                                                                                                                                                                                                    
            Particle* p = [PARTICLE_MANAGER
                        NewParticleAt:topOfPile
                            andVelocity:Vector2DMul(dir, kSpeed)
                            andAngle:TWO_PI*random()/RAND_MAX 
                            andScaleX:CANDY_MAX_SIZE 
                            andScaleY:CANDY_MAX_SIZE 
                            andColor:COLOR3D_WHITE 
                            andTotalLifetime:distance/kSpeed
                            andType:kParticleType_Basic
                            andTexture:kTexture_CandyBegin+rand()%(kTexture_CandyEnd-kTexture_CandyBegin)]; 
            [PARTICLE_MANAGER addParticle:p];
            [p release];  
        }  
    }
    else if (type == kPinataType_Plane) {
        planeLanded = true;
        behavior ^= kPinataBehavior_Negative;
        
        [self trigger];
    }        
}

-(float)minimumPileDistanceToEat {
    return 10.0f+2.5f*floatingRadius;
}

-(void)chaseBadPinata {
    NSMutableArray* pinatas = [game getPinatas];
    float minDistance = FLT_MAX;
    Vector2D nearestPosition = Vector2DMake(0.0f,0.0f);
    for (Pinata* p in pinatas) { 
        if (p.numParts > 0 && !p.consumed && !p.cargoPinata &&
            ((p.behavior&kPinataBehavior_EatsPile)!=0 || (p.behavior&kPinataBehavior_Cannibal)!=0 
                || (p.type==kPinataType_MotherPileEater))) 
        {
            float distanceToPinata = Vector2DDistance(position,p.position);
            if (distanceToPinata < [p radius]) {  
                [p addPinataCargo:self];
                break;
            }
            else {
                minDistance = distanceToPinata;
                nearestPosition = p.position;
            }
        }
    }

    if (!attachmentPinata && minDistance != FLT_MAX && minDistance > 1.0f) {
        Vector2D dir = Vector2DSub(nearestPosition, position);
        Vector2DNormalize(&dir);
        Vector2D force = Vector2DMul(dir, GAME_PARAMETERS.pinataHeroSpeed*minDistance*minDistance);
        velocity = Vector2DAdd(velocity, force); 
    }            

}

-(void)updateHelpfulBehavior:(float)timeElapsed {
    NSAssert((behavior&kPinataBehavior_Helpful)!=0, @"Pinata::updateHelpfulBehavior - Invalid pinata");
    
    pinataHelpfulLastTrigger += timeElapsed;

    if (!attachmentPinata) {
    
        if (Vector2DMagnitude(velocity) < 100.0f) {
            triggeredByPullCord = false;
        }
    
        if (triggeredByPullCord) {
            NSMutableArray* pinatas = [game getPinatas];
            for (Pinata* p in pinatas) { 
                if (p.numParts > 0 && !p.consumed && !p.cargoPinata) {
                    float distanceToPinata = Vector2DDistance(position,p.position);                
                    if (distanceToPinata < [p radius]) {  
                        if ([self helpfulAttackPinata:p]) {
                            break;
                        }
                    }
                }
            }            
        }
        else {
            [self floatMotion:timeElapsed];
        }
    }
    else {
        velocity    = attachmentPinata.velocity;
        position    = attachmentPinata.position;
        angle       = attachmentPinata.angle; 
        
        if (pinataHelpfulLastTrigger > GAME_PARAMETERS.pinataHeroAttackDelay) {  
            pinataHelpfulLastTrigger = 0.0f;
            [attachmentPinata trigger];
        }            
    }
}

-(Boolean)helpfulAttackPinata:(Pinata*)p {
    if (type == kPinataType_Hero) {
        if ((p.behavior&kPinataBehavior_Mountable)!=0 && p.color.alpha != 0.0f) {
            [p addPinataCargo:self];
//            triggeredByPullCord = false;
            return true;
        }
        else if (p.type==kPinataType_PileEater) {
            [p trigger];
            [self bounce];
            
//            float speed = Vector2DMagnitude(velocity);
//            if (0.95f*speed >= 105.0f) {
//                velocity = Vector2DMul(velocity, 0.95f);
//            }
            return true;
        }
    }
    
    return false;
}

-(void)convertToHealthy:(Pinata*)p {    
    p.pulseDamageT  = 0.0f;   
    if (p.type == kPinataType_Dog) {
        p.type = kPinataType_Cat;
        [p setBehaviorByType];
    }          
    else {
        p.behavior      |= kPinataBehavior_Negative;
        p.behavior      &= (~kPinataBehavior_Edible);
        p.veggies       = true;            
    }
    
    [p bounce];
    [self bounce];
    [PARTICLE_MANAGER createSparkleAt:position withLayer:kLayer_Game];

    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_FairyTransform)];
}

-(void)addPinataCargo:(Pinata*)p {
    NSAssert(!cargoPinata, @"Cargo already attached!");
    cargoPinata = p;
    [cargoPinata retain];

    NSAssert(!p.attachmentPinata, @"Cargo already attached!");
    p.attachmentPinata = self;
    [p.attachmentPinata retain];
}

-(void)removePinataCargo {
    // remove this pinata from cargo's attachment
    [cargoPinata.attachmentPinata release];
    cargoPinata.attachmentPinata = nil;
    
    // knock off cargo
    [cargoPinata addForce:MakeRandVector2D(GAME_PARAMETERS.splitSpeed)];
    
    // get rid off cargo
    [cargoPinata release];
    cargoPinata = nil;    
}

-(void)updateCannibalBehavior:(float)timeElapsed {
    NSAssert((behavior&kPinataBehavior_Cannibal)!=0, @"Pinata::updateCannibalBehavior - Invalid pinata");

    timeLastPinataConsumed += timeElapsed;

    if (timeLastPinataConsumed < GAME_PARAMETERS.pinataEaterDelay) {
        return;
    }

    NSMutableArray* pinatas = [game getPinatas];
    float minDistance = FLT_MAX;
    Vector2D nearestPosition = Vector2DMake(0.0f,0.0f);
    for (Pinata* p in pinatas) { 
        if (    p.numParts <= 1+pinatasConsumed.count    // this pinata is large enough to eat the other pinata
            &&  p.numParts > 0                         // the other pinata has parts to consume
            &&  !p.consumed ) 
        {
            if (    ((type==kPinataType_Cannibal || type==kPinataType_BadGremlin) && (p.behavior&kPinataBehavior_Edible)!=0) 
                ||  (type == kPinataType_Osmos && p.type == kPinataType_Hero)  ) {
                float distanceToPinata = Vector2DDistance(position,p.position);
                if (distanceToPinata < 10.0f) {  
                    [self consumePinata:p];
                    break;
                }
                else {
                    minDistance = distanceToPinata;
                    nearestPosition = p.position;
                }
            }
        }
    }
    
    if (minDistance != FLT_MAX && minDistance > 1.0f) {
        Vector2D dir = Vector2DSub(nearestPosition, position);
        Vector2DNormalize(&dir);
        
        float speed = GAME_PARAMETERS.pinataEaterSpeed;
        if (type == kPinataType_Osmos) {
            speed = GAME_PARAMETERS.osmosChaseSpeed;
        }
        
        Vector2D force = Vector2DMul(dir, GAME_PARAMETERS.pinataEaterSpeed/(minDistance*minDistance));
        velocity = Vector2DAdd(velocity, force); 
    }
    
    float targetAngle = 0.0f;
    if (type == kPinataType_Cannibal) {
        targetAngle = atan2f(velocity.y,velocity.x)+M_PI;
    }
            
    angle = lerpAngle(angle, targetAngle, 5.0f*timeElapsed);    
}

-(void)updateJoinableBehavior:(float)timeElapsed atIndex:(int)i {
    NSMutableArray* pinatas = [game getPinatas];
    for (int j = i+1; j < pinatas.count; ++j) {
        Pinata* otherPinata = [pinatas objectAtIndex:j];
        if (    spawnTime > 1.0f
            &&  otherPinata.spawnTime > 1.0f
            &&  numParts != 0
            &&  otherPinata.numParts != 0
            &&  (otherPinata.behavior&kPinataBehavior_Joinable)!=0
            &&  ((otherPinata.behavior^behavior)&kPinataBehavior_Negative)==0 ) { 

            Boolean attracted = [self canJoinWith:otherPinata];                                   
            if (attracted) {
                float distance = [self distanceTo:otherPinata];
                if (distance < 15.0f) {
                    [self merge: otherPinata];
                }
                else {
                    // attraction force
                    Vector2D dir = Vector2DSub(otherPinata.position, position);
                    Vector2DNormalize(&dir);
                    Vector2D attraction = Vector2DMul(dir, GAME_PARAMETERS.mergeSpeed/(distance*distance));
                    velocity = Vector2DAdd(velocity, attraction);
                    Vector2DFlip(&attraction);
                    otherPinata.velocity = Vector2DAdd(otherPinata.velocity, attraction); 
                }
            }
        }
    } 
}

-(void)releaseConsumedPinatas {
    for (Pinata* p in pinatasConsumed) {
        p.consumed = false;
        p.position = position;
        p.velocity = MakeRandVector2D(GAME_PARAMETERS.splitSpeed);
        p.pulseDamageT = 0.0f; 
    }
    [pinatasConsumed removeAllObjects];
}

-(void)consumePinata:(Pinata*)p {
    timeLastPinataConsumed = 0.0f;

    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Swallow)];

    [pinatasConsumed addObject:p];
    p.consumed = true;
    
    [jiggler jiggleFreq:15.0f andAmplitude:0.25f andDuration:3.0f];
    [PARTICLE_MANAGER createConfettiAt:position withAmount:5 withLayer:kLayer_Game];    
    
    [Pinata postComment:@"Nom Nom Nom" atPosition:position];    
}

-(void)stayInBounds {
    float speed     = Vector2DMagnitude(velocity);
    float padding   = 0.125f*[self radius];

    if (position.x+padding > game.labWidth && velocity.x > 0.0f) {
        velocity.x = -fabsf(velocity.x);
        [self jiggleFromWall:speed];
    }
    else if (position.x-padding < 0.0f && velocity.x < 0.0f) {
        velocity.x = fabsf(velocity.x);
        [self jiggleFromWall:speed];        
    }
    
    if (position.y+padding > game.labHeight && velocity.y > 0.0f) {
        velocity.y = -fabsf(velocity.y);
        [self jiggleFromWall:speed];
    }
    else if (position.y-padding < 0.0f && velocity.y < 0.0f) {
        velocity.y = fabsf(velocity.y);
        [self jiggleFromWall:speed];        
    }
}

-(void)setBehaviorByType {
    switch (type) {
    case kPinataType_Normal:
        behavior    = (kPinataBehavior_Separable|kPinataBehavior_Joinable|kPinataBehavior_Edible);
        flipped     = (random()%2)==0;        
        break;
    case kPinataType_Ghost:
        behavior    = (kPinataBehavior_Ghost|kPinataBehavior_Separable|kPinataBehavior_Joinable|kPinataBehavior_Edible);
        break;
    case kPinataType_Cannibal:
        behavior    = (kPinataBehavior_Cannibal|kPinataBehavior_Destroyable|kPinataBehavior_Mountable);
        numParts    = 1;
        hitPoints   = CANNIBAL_HIT_POINTS;
        break;
    case kPinataType_HealthyParts:
        behavior    = (kPinataBehavior_Negative|kPinataBehavior_Separable|kPinataBehavior_Edible|kPinataBehavior_Joinable);
        break;
    case kPinataType_TimedBombParts:
        behavior    = (kPinataBehavior_TimedBomb|kPinataBehavior_Separable|kPinataBehavior_Joinable|kPinataBehavior_Edible);
        bombDetonateTime = 1.0f+random()/(float)RAND_MAX;
        break;
    case kPinataType_Strong:
        behavior    = (kPinataBehavior_Edible|kPinataBehavior_Destroyable); //|kPinataBehavior_ShortLifetime); 
        flipped     = (random()%2)==0;
        numParts    = 1;
        hitPoints   = STRONG_HIT_POINTS;
        break;
    case kPinataType_PileEater:
        behavior    = (kPinataBehavior_Destroyable|kPinataBehavior_EatsPile);
        flipped     = (random()%2)==0;        
        pileEatProximity = 0.0f;
        floatingRadius = 0.0f;
        numParts    = 1;
        hitPoints   = 1;
        break;
    case kPinataType_Hero:
        behavior    = (kPinataBehavior_Destroyable|kPinataBehavior_Helpful);
        flipped     = (random()%2)==0;        
        numParts    = 1;
        hitPoints   = 1;
        pullCord    = [[PullCord alloc] initForPinata:self forGame:game];
        break;
    case kPinataType_Cat:        
    case kPinataType_BreakableHealthy:
        behavior    = (kPinataBehavior_Negative|kPinataBehavior_Destroyable);
        flipped     = (random()%2)==0;        
        numParts    = 1;
        hitPoints   = 1;
        break;    
    case kPinataType_MotherPileEater:
        behavior    = (kPinataBehavior_Destroyable|kPinataBehavior_Spawner|kPinataBehavior_Mountable);
        flipped     = (random()%2)==0;        
        numParts    = 1;
        hitPoints   = MOTHER_EATER_HIT_POINTS;
        spawnType   = kPinataType_PileEater;
        break;    
    case kPinataType_Dog:
    case kPinataType_WeakCandy:
        behavior    = (kPinataBehavior_Edible|kPinataBehavior_Destroyable);       
        flipped     = (random()%2)==0;        
        numParts    = 1;
        hitPoints   = 1;        
        break;       
    case kPinataType_UFO:
        behavior    = (kPinataBehavior_Destroyable|kPinataBehavior_EatsPile|kPinataBehavior_Mountable);
        flipped     = (random()%2)==0;        
        pileEatProximity = 200.0f;
        floatingRadius = 15.0f;
        numParts    = 1;
        hitPoints   = UFO_HIT_POINTS;
        break;
    case kPinataType_Zombie:
        behavior    = (kPinataBehavior_Destroyable|kPinataBehavior_Mountable);
        flipped     = (random()%2)==0;        
        numParts    = 1;
        hitPoints   = 1;
        color.alpha = 0.0f;
        inDisguise  = true;
        break;
    case kPinataType_Plane:
        behavior    = (kPinataBehavior_Negative|kPinataBehavior_Destroyable|kPinataBehavior_EatsPile);
        flipped     = (random()%2)==0;
        numParts    = 1;
        hitPoints   = 1;        
        break;
    case kPinataType_Osmos:
        behavior    = (kPinataBehavior_Cannibal);
        numParts    = 1;
        hitPoints   = 1;        
        break;
    case kPinataType_GoodGremlin:
        behavior    = (kPinataBehavior_Destroyable|kPinataBehavior_EatsPile);
        flipped     = (random()%2)==0;        
        pileEatProximity = 0.0f;        
        numParts    = 1;
        hitPoints   = 1;
        break;  
    case kPinataType_BadGremlin:
        behavior    = (kPinataBehavior_Cannibal|kPinataBehavior_Destroyable|kPinataBehavior_Mountable);
        flipped     = (random()%2)==0;        
        numParts    = 1;
        hitPoints   = 1;    
        break;
    case kPinataType_Spike:
        behavior    = kPinataBehavior_DealDamage;
        numParts    = 1;
        hitPoints   = 1;
        break;
    case kPinataType_Pinhead:
        behavior    = 0;
        flipped     = (random()%2)==0;        
        flipped     = (random()%2)==0;
        numParts    = 1;
        break;
    case kPinataType_Treasure:
        behavior    = (kPinataBehavior_Destroyable|kPinataBehavior_TriggersOnShake);
        flipped     = (random()%2)==0;        
        numParts    = 1;
        hitPoints   = 1;
        break;        
    case kPinataType_Chameleon:
        disguise    = kTexture_BreakableVegetablePinataGlow;
        flipped     = (random()%2)==0;        
        behavior    = (kPinataBehavior_Disguised|kPinataBehavior_Destroyable);
        hitPoints   = 1;
        numParts    = 1;
        break;    
    case kPinataType_Grower:
        behavior    = (kPinataBehavior_Disguised|kPinataBehavior_Destroyable);
        disguise    = kTexture_BadGrower;
        flipped     = (random()%2)==0;        
        numParts    = 1;
        hitPoints   = 1;
        break;               
    default:
        NSAssert(false, @"Invalid pinata type");
        break;
    }
    
    if (ghosting) {
        behavior |= kPinataBehavior_Ghost;
    }
    
    if (veggies) {
        behavior |= kPinataBehavior_Negative;
        behavior &= (~kPinataBehavior_Edible);
    }
    
    if (lifetime > 0.0f) {
        behavior |= kPinataBehavior_ShortLifetime;
    }
}

-(float)distanceTo:(Pinata*)otherPinata {
    return Vector2DDistance(position,otherPinata.position);
}

-(void)merge:(Pinata*)otherPinata {
    NSAssert((behavior&kPinataBehavior_Joinable)!=0, @"Pinata::merge - Invalid pinata");

    [jiggler jiggleFreq:15.0f andAmplitude:0.25f andDuration:3.0f];

    int mergedParts = otherPinata.numParts + numParts;
    for (int i = 0; i < PINATA_HORIZONTAL_PIECES; ++i) {
        for (int j = 0; j < PINATA_VERTICAL_PIECES; ++j) {
            NSAssert( !(otherPinata->parts[i][j]!=kPinataType_Null && parts[i][j]!=kPinataType_Null), @"Pinata::merge - Matching parts!");
            if (otherPinata->parts[i][j] != kPinataType_Null) {
                parts[i][j] = otherPinata->parts[i][j];
                behavior |= otherPinata.behavior;
            }
        }
    }
    otherPinata.numParts = 0;
    numParts = mergedParts;
}

-(void)addAllParts {
    if ((behavior&kPinataBehavior_Separable)) {
        for (int i = 0; i < PINATA_HORIZONTAL_PIECES; ++i) {
            for (int j = 0; j < PINATA_VERTICAL_PIECES; ++j) {
                parts[i][j] = type;
            }
        }
        numParts = PINATA_VERTICAL_PIECES * PINATA_HORIZONTAL_PIECES;        
    }
}

-(void)floatMotion:(float)timeElapsed {
    floatingT   += timeElapsed;
    position.x  += floatingRadius*(sinf(floatingT) - sinf(floatingT-timeElapsed));
    position.y  += floatingRadius*(cosf(0.5f*floatingT) - cosf(0.5f*(floatingT-timeElapsed)));
}

-(void)removeAllParts {
    for (int i = 0; i < PINATA_HORIZONTAL_PIECES; ++i) {
        for (int j = 0; j < PINATA_VERTICAL_PIECES; ++j) {  
            parts[i][j] = kPinataType_Null;
        }
    }
    numParts = 0;
}

-(void)split { 
    NSAssert(numParts > 1, @"Pinata::split - Not enough parts to split!");
    NSAssert((behavior&kPinataBehavior_Separable)!=0, @"Pinata::split - Invalid pinata");

    if (numParts <= 1) {
        return;
    }

    NSMutableArray* pinatas = game.getPinatas;
    int pinatasCreated = 0;
    Boolean doneCreating = (numParts-1 <= 0);
    for (int i = 0; i < PINATA_HORIZONTAL_PIECES && !doneCreating; ++i) {
        for (int j = 0; j < PINATA_VERTICAL_PIECES && !doneCreating; ++j) {  
            if (parts[i][j] != kPinataType_Null) {
            
                Pinata* newPinata = [PINATA_MANAGER NewPinata:game 
                                at:position 
                                withVelocity:MakeRandVector2D(GAME_PARAMETERS.splitSpeed)
                                withType:type
                                withGhosting:ghosting
                                withVeggies:veggies
                                withLifetime:lifetime];
                newPinata->parts[i][j] = parts[i][j];
                newPinata.numParts = 1;
                
                [pinatas addObject:newPinata];
                [newPinata release];
                newPinata = nil;
                
                parts[i][j] = kPinataType_Null;
                ++pinatasCreated;
                
                doneCreating = (pinatasCreated==numParts-1);
            }
        }
    }

//    NSAssert(pinatasCreated==numParts-1, @"Pinata::split - Not enough pinatas created!");

    numParts = 1;
    spawnTime = 0.0f;
    [self setBehaviorByType];
    
    [PARTICLE_MANAGER createConfettiAt:position withAmount:5 withLayer:kLayer_Game];    
}

-(Boolean)isInside:(CGPoint)p {
    if (consumed) {
        return false;
    }

    Vector2D dim = GetImageDimensions(kTexture_Pinata);    
    return fabsf(p.x-position.x) <= dim.x/2*scale &&
           fabsf(p.y-position.y) <= dim.y/2*scale;    
}

-(Boolean)isInsidePullCord:(CGPoint)p {
    if (consumed) {
        return false;
    }

    return [pullCord isInside:p];
}

-(void)shake {     
    if (type == kPinataType_Treasure) {
        [self trigger];
    }
    else if (type == kPinataType_PileEater || type == kPinataType_GoodGremlin) {
        Vector2D dir;
        Vector2D topOfPile;
        float distance;
        [self getPileDirection:&dir     
                andDistance:&distance 
                andTopOfPile:&topOfPile 
                withProximity:0.0f];

        if (distance-pileEatProximity-[self radius] <= [self minimumPileDistanceToEat]) {
            CandyPile* pile = [game getCandyPile];
            Vector2D pilePosition = [pile position];
            Vector2D toEater = Vector2DSub(position, pilePosition);
            Vector2DNormalize(&toEater);
            [self addForce:Vector2DMul(toEater, GAME_PARAMETERS.pileShakeForce)];
        }
    }
}

-(Boolean)trigger {
    return [self triggerDamage:1];
}

-(Boolean)triggerDamage:(int)damage {
    if (spawnTime < 0.01f) {
        return false;
    } 
    
    if (numParts == 0 || consumed) {
        return false;
    }

    if ((behavior&kPinataBehavior_Ghost)!=0) {
        if (color.alpha == GHOST_HIDDEN_ALPHA) {
            return false;
        }
    }
    
    if (type == kPinataType_Zombie && !cargoPinata) {
        return false;
    }
    
    Boolean handled = false;
        
    if ((behavior&kPinataBehavior_Separable)!=0) {
        if (numParts >= 1) {
            if (numParts > 1) {
                [self split];
            }
            [self releaseCandy];
            handled = true;
        }
        [PARTICLE_MANAGER createHitAt:position];        
        [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PinataSplit)];
        
        METAGAME_MANAGER.totalNormalPinatasDestroyed++;
    }
    
    if ((behavior&kPinataBehavior_Destroyable)!=0 && (behavior&kPinataBehavior_Helpful)==0) {
        hitPoints -= damage;        
        pulseDamageT = 0.0f;
        
        [PARTICLE_MANAGER createHitAt:position];
        
        if (hitPoints <= 0) {              
            [self kill];
            
            [self releaseCandy];
            [PARTICLE_MANAGER 
                createConfettiAt:position withAmount:5 withLayer:kLayer_Game];
            
            // exploding
            if (type == kPinataType_UFO) {
                [PARTICLE_MANAGER
                    createExplosionAt:position withScale:1.0f withLarge:false withLayer:kLayer_Game];
            }
             
            // healthy/unhealthy ////////////////////////////////////////////////////////////                   
            {
                if (type == kPinataType_BreakableHealthy || (behavior&kPinataBehavior_Negative)!=0) {
                    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_VegetablesDrop)];
                    [game.levelEnvironment flashBackground:COLOR3D_RED];                                                                                    
                }
                else if (type == kPinataType_Strong) {
                    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_CandyDrop)];            
                }
            }
            
            if (type == kPinataType_Grower) {
                ePinataBehavior filter = inDisguise ? kPinataBehavior_Negative : kPinataBehavior_Edible;
                [game   setPinataScale:     GAME_PARAMETERS.growerExpansion 
                        withPinataBehavior: filter          
                        withDuration:       GAME_PARAMETERS.growerDuration];
            }
            
            // destroy sound ////////////////////////////////////////////////////////////
            {
                if (type == kPinataType_PileEater) {
                    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PileEaterKill)];
                }
                else if (type == kPinataType_Treasure) {
                    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Treasure)];            
                }
                else {
                    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PinataDestroy)]; 
                }
            }
                        
            // achievements ////////////////////////////////////////////////////////////
            {
                METAGAME_MANAGER.totalPinatasDestroyed++;            
                
                switch (type) {
                    case kPinataType_Cannibal:
                        METAGAME_MANAGER.totalCannibalPinatasDestroyed++;
                        break;
                    case kPinataType_PileEater:
                        METAGAME_MANAGER.totalTickPinatasDestroyed++;  
                        break;
                    case kPinataType_Chameleon:
                        METAGAME_MANAGER.totalChameleonsDestroyed++;                          
                        break;
                    case kPinataType_Zombie:
                        METAGAME_MANAGER.totalFairiesDestroyed++;                          
                        break;
                    case kPinataType_Treasure:
                        METAGAME_MANAGER.totalTreasuresDestroyed++;                          
                        break;
                    case kPinataType_UFO:
                        METAGAME_MANAGER.totalUFOsDestroyed++;                          
                        break;
                    case kPinataType_GoodGremlin:
                        METAGAME_MANAGER.totalGoodGremlinsDestroyed++;
                        break;
                    default:
                        break;
                }
            }
        }
        else {        
            velocity = Vector2DAdd(velocity, MakeRandVector2D(1000.0f)); 
            [PARTICLE_MANAGER 
                createConfettiAt:position withAmount:5 withLayer:kLayer_Game];  
                
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PinataDamage)];     
        }
        handled = true;
    }
        
    // special behavior ////////////////////////////////////////////////////////////            
    {
        if (type == kPinataType_Pinhead) {                    
            [self triggerPinatasAt:position 
                    withinDistance:GAME_PARAMETERS.pinheadDestroyRadius*[self radius]];
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PorcupineHit)];             
            handled = true;
        }
    }    

    // special behavior ////////////////////////////////////////////////////////////            
    
    if (!pullCord) {
        [PARTICLE_MANAGER createSparkAt:position 
                        withAmount:8  
                        withColor:game.multiplierColor
                        withSpeed:sqrtf(game.multiplier)*50.0f
                        withScale:1.0f
                        withLayer:kLayer_Game];

        velocity = MakeRandVector2D(GAME_PARAMETERS.splitSpeed);
        [jiggler jiggleFreq:15.0f andAmplitude:0.25f andDuration:3.0f];
    }
        
    timeTriggered = 0.0f;
    
    return handled;
}

-(void)triggerPinatasAt:(Vector2D)p withinDistance:(float)distance {
    NSMutableArray* nearPinatas = [game findPinatasNear:p 
                                        withinDistance:distance];
    for (Pinata* p in nearPinatas) {
        if (p != self && (p.behavior&kPinataBehavior_TriggersOnShake)==0) {
            [p trigger];
        }
    }                    
    [nearPinatas release];
}


-(void)kill {
    numParts = 0;

    if (pinatasConsumed.count > 0) {
        [self releaseConsumedPinatas];
    }
    
    if (pullCord) {
        pullCord.alive = false;
        [pullCord release];
        pullCord = nil;
    }
    
    [self removePinataCargo];
    
    if (attachmentPinata) {
        [attachmentPinata removePinataCargo];
    }
}

-(void)releaseCandy {
    int amount = [self candy];
    [game addCandy:amount useMultiplier:true];
    
    if (amount < 0) {
        [PARTICLE_MANAGER 
            createVegetableExplosionAt:position withAmount:(int)(fabsf(amount)*VEGETABLE_TO_VFX_RATIO)];     
            METAGAME_MANAGER.totalVegetablesCollected += (-amount);      
    }
    else if (amount > 0) {
        float randFrac = RAND_CANDY_PIECES_PER_RELEASE*random()/(float)RAND_MAX;  
        int candies = (int)(amount * randFrac);
        [game spawnCandyPieces:candies atPosition:position];                
    
        [PARTICLE_MANAGER 
            createCandyExplosionAt:position withAmount:(int)(amount*CANDY_TO_VFX_RATIO) withLayer:kLayer_Game];            
    }
}

-(Boolean)canJoinWith:(Pinata *)p {
    if (    (p.behavior&kPinataBehavior_Joinable)==0
        ||  (p.behavior&kPinataBehavior_Joinable)==0) {
        return false;
    }

    Boolean connecting = false;
    for (int i = 0; i < PINATA_HORIZONTAL_PIECES; ++i) {
        for (int j = 0; j < PINATA_VERTICAL_PIECES; ++j) {
            if (parts[i][j] != kPinataType_Null) {
                if (p->parts[i][j] != kPinataType_Null) {
                    return false;
                }
                if ( !connecting &&
                    (   PinataPartInRange(i+1,j) && p->parts[i+1][j]!= kPinataType_Null
                    ||  PinataPartInRange(i-1,j) && p->parts[i-1][j]!= kPinataType_Null
                    ||  PinataPartInRange(i,j+1) && p->parts[i][j+1]!= kPinataType_Null
                    ||  PinataPartInRange(i,j-1) && p->parts[i][j-1]!= kPinataType_Null )) {
                    connecting = true;
                }
            }
        }
    }
    
    return connecting;
}

-(int)candy {
    int amountOfCandy = 0;
    if (type == kPinataType_HealthyParts) {
        int countableParts = 0;
        for (int i = 0; i < PINATA_HORIZONTAL_PIECES; ++i) {
            for (int j = 0; j < PINATA_VERTICAL_PIECES; ++j) {
                if (parts[i][j] != kPinataType_Null) { 
                    countableParts = (parts[i][j] == kPinataType_HealthyParts) 
                                        ? countableParts-1
                                        : countableParts+1;
                }
            }
        }
        amountOfCandy = countableParts*GAME_PARAMETERS.pinataPartCandy;
    }
    else {
        switch (type) {
        case kPinataType_Strong:
            amountOfCandy = GAME_PARAMETERS.strongPinataCandy;
            break;           
        case kPinataType_GoodGremlin:
            amountOfCandy = GAME_PARAMETERS.gremlinCandy;
            break;
        case kPinataType_Cat:            
        case kPinataType_BreakableHealthy:
            amountOfCandy = GAME_PARAMETERS.healthyPinataVegetables;
            break;
        case kPinataType_Dog:
        case kPinataType_WeakCandy:
        case kPinataType_Chameleon:        
            amountOfCandy = GAME_PARAMETERS.weakPinataCandy;
            break;          
        case kPinataType_Treasure:
            amountOfCandy = GAME_PARAMETERS.treasureCandy;
            break;
        case kPinataType_Plane:            
            amountOfCandy = (planeLanded) 
                                ? GAME_PARAMETERS.planeCandy 
                                : GAME_PARAMETERS.planeVegetables;
            break;
        case kPinataType_Grower:
        case kPinataType_Spike:
        case kPinataType_Pinhead:
        case kPinataType_Cannibal:
        case kPinataType_PileEater:
        case kPinataType_UFO:
        case kPinataType_MotherPileEater: 
        case kPinataType_BadGremlin:
        case kPinataType_Hero:            
        case kPinataType_Zombie:           
        case kPinataType_Osmos:
            amountOfCandy = 0;
            break;  
        default:
            amountOfCandy = numParts*GAME_PARAMETERS.pinataPartCandy;        
            break;
        }
        
        if (ghosting) {
            amountOfCandy = (int)(amountOfCandy*GAME_PARAMETERS.ghostCandyMultiplier);
        }
        
        if ((behavior&kPinataBehavior_Negative)!=0) {
            amountOfCandy = -abs(amountOfCandy);
        }
    }
        
    return amountOfCandy;    
}

-(Boolean)isWhole {
    return numParts == (PINATA_HORIZONTAL_PIECES*PINATA_VERTICAL_PIECES);
}

- (void)dealloc {    
    [jiggler release];
    [pinatasConsumed release];
    [attachmentPinata release];
    [cargoPinata release];    
    [pullCord release];
    [super dealloc];
}

-(void)addForce:(Vector2D)force {
    if (pullCord && !triggeredByPullCord) {
        return;
    }
    
    if (color.alpha == 0.0f) {
        return;
    }
    
    if (ghosting && color.alpha==GHOST_HIDDEN_ALPHA) {
        return;
    }
    
    velocity = Vector2DAdd(velocity, force);
    
    if (Vector2DMagnitude(velocity) > GAME_PARAMETERS.maxPinataSpeed+1.0f) {
        Vector2DNormalize(&velocity);
        velocity = Vector2DMul(velocity, GAME_PARAMETERS.maxPinataSpeed);
    }    
}

-(void)bounce { 
    [jiggler jiggleFreq:15.0f andAmplitude:0.25f andDuration:1.0f];
}

-(void)render:(float)timeElapsed { 
    if (!numParts || consumed) {
        return;
    }
           
    float angleDegree = angle * RAD_TO_DEGR;

    // it's not economical to do shadows and motion blur for pile eaters
    // since there are often many onscreen
    if (type != kPinataType_PileEater) { 
        if (IsGameShadowsEnabled()) {
            // shadow
            Vector2D shadowOffset = [ES1Renderer shadowOffset];
            Color3D shadowColor = [game shadowColor];        
        
            glLoadIdentity();        
            glTranslatef(ToScreenScaleX(position.x+shadowOffset.x), ToScreenScaleY(position.y+shadowOffset.y), 0.0f);
            glRotatef(angleDegree,0.0f,0.0f,1.0f);
            glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, color.alpha*shadowColor.alpha);         
            [self drawWithShadowPass:true];       
        }

        if (IsGameMotionBlurEnabled()) {
            float blurAlpha = 0.75f*Vector2DMagnitude(velocity)/GAME_PARAMETERS.maxPinataSpeed;
            if (blurAlpha > 0.1f) {
                // motion blur
                glLoadIdentity();
                glTranslatef(ToScreenScaleX(position.x-2.0f*timeElapsed*velocity.x), 
                                ToScreenScaleY(position.y-2.0f*timeElapsed*velocity.y), 0.0f);
                glRotatef(angleDegree,0.0f,0.0f,1.0f);
                glColor4f(color.red,color.green,color.blue, blurAlpha);
                [self drawWithShadowPass:true];    
            }
        }
    }
    
    if (type == kPinataType_UFO) {
        [self drawBeam];
    }
    
    [pullCord render:timeElapsed];    
               
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
    glRotatef(angleDegree,0.0f,0.0f,1.0f);
    glColor4f(color.red,color.green,color.blue, color.alpha);
    [self drawWithShadowPass:false];
    
    [cargoPinata render:timeElapsed];
    
    ++frame;
}

-(void)drawBeam {  
    if (pileEatWarmup <= 0.0f) {
        return;
    }
                           
    Vector2D d;
    Vector2D topOfPile;
    float distance;
    [self getPileDirection:&d andDistance:&distance andTopOfPile:&topOfPile withProximity:0.0f];
    
    Vector2D dir = Vector2DSub(topOfPile, position);
    Vector2DNormalize(&dir);
    dir = Vector2DMul(dir, distance);
   
    float angleToPile = atan2f(dir.y,dir.x)*RAD_TO_DEGR;
    
    Texture2D* texture = GetTexture(kTexture_White);   
   
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
    glRotatef(angleToPile,0.0f,0.0f,1.0f);
    glScalef(ToScreenScaleX(pileEatWarmup*distance)/texture.pixelsWide, ToScreenScaleY(16.0f)/texture.pixelsHigh, 0.0f);
    glTranslatef(texture.pixelsWide/2,0.0f,0.0f);
    glColor4f(1.0f,1.0f,0.0f, 0.5f);
    [texture draw];                        
}

- (void)drawWithShadowPass:(Boolean)shadowPass {
    if ((behavior&kPinataBehavior_Separable)!=0) {
        [self drawPartsWithShadowPass:shadowPass];    
    }
    else {
        Texture2D* texture = [self getTexture];
        float radius = [self radius];
        float radiusX = 2.0f*radius/(float)texture.pixelsWide;
        if (flipped) {
            radiusX = -radiusX;
        }
        
        float radiusY = 2.0f*radius/(float)texture.pixelsHigh;
        glScalef(radiusX, radiusY, 1.0f);
        [texture draw];        
    }
}

- (void)drawPartsWithShadowPass:(Boolean)shadowPass {
    Texture2D* baseTexture = [self getTexture];
    float radius = [self radius];
    float xIncr = 2.0f*radius/PINATA_HORIZONTAL_PIECES;
    float yIncr = 2.0f*radius/PINATA_VERTICAL_PIECES;    
    float maxS = baseTexture.maxS;
    float maxT = baseTexture.maxT;
    float sIncr = maxS / PINATA_HORIZONTAL_PIECES;
    float tIncr = maxT / PINATA_VERTICAL_PIECES;
    CGRect rect = CGRectMake(-radius, -radius, xIncr, yIncr);
    CGRect texRect = CGRectMake(0.0f, 0.0f, -sIncr, -tIncr);
    for (int i = 0; i < PINATA_HORIZONTAL_PIECES; ++i) {
        for (int j = 0; j < PINATA_VERTICAL_PIECES; ++j) {
            if (parts[i][j] != kPinataType_Null) {
                Texture2D* texture = [Pinata getTexture:parts[i][j] 
                                                withHitPoints:0
                                                wasTriggered:(timeTriggered<PINATA_TRIGGER_TIME)
                                                veggies:(veggies)
                                                frame:frame];
                Texture2D* secondPass = nil;

                if (!shadowPass) {
                    if (parts[i][j] == kPinataType_HealthyParts) {
                        secondPass = GetTexture(kTexture_Vegetable);
                    }
                    else if (parts[i][j] == kPinataType_TimedBombParts) {
                        secondPass = GetTexture(kTexture_BombPart);                    
                    }
                }
                
                [texture drawInRect:rect withTexCoords:texRect withSecondTexture:secondPass];
            }
            rect.origin.y += yIncr;
            texRect.origin.y += tIncr;
        }
        
        rect.origin.x += xIncr;
        rect.origin.y = -radius;
        
        texRect.origin.x += sIncr;        
        texRect.origin.y = 0.0f;
    }
}

-(Texture2D*)getTexture {
    if ((behavior&kPinataBehavior_Disguised)!=0 && inDisguise) {
        return GetTexture(disguise);
    }
        
    return [Pinata  getTexture:     type 
                    withHitPoints:  hitPoints
                    wasTriggered:   (timeTriggered<PINATA_TRIGGER_TIME)
                    veggies:        veggies                    
                    frame:          frame];
}

+(Texture2D*)getTexture:(ePinataType)type 
                withHitPoints:(int)hitPoints 
                wasTriggered:(Boolean)triggered
                veggies:(Boolean)veggies                
                frame:(int)frame {
    eTexture tex = kTexture_Pinata+(int)(veggies);
    switch (type) {
    case kPinataType_Cannibal:
        {
            int maxPoints = kTexture_PinataEaterEnd-kTexture_PinataEaterBegin;
            if (hitPoints > maxPoints) {
                hitPoints = maxPoints;
            }
            tex = kTexture_PinataEaterEnd-hitPoints;    
            break;
        }
    case kPinataType_HealthyParts:
        {
            tex = kTexture_Pinata;
            break;
        }
    case kPinataType_Strong:
        {
            int maxPoints = kTexture_StrongPinataEnd-kTexture_StrongPinataBegin;
            if (hitPoints > maxPoints) {
                hitPoints = maxPoints;
            }
            tex = (int)(veggies)*maxPoints+kTexture_StrongPinataEnd - hitPoints;
            break;
        }
    case kPinataType_BreakableHealthy:
        {
            tex = kTexture_BreakableVegetablePinata;
            break;
        }
    case kPinataType_WeakCandy:
        {
            tex = kTexture_WeakCandyPinata+(int)(veggies);
            break;
        }        
    case kPinataType_Hero:
        {
            tex = kTexture_HeroPinata;
            break;
        }
    case kPinataType_PileEater:
        {
            tex = kTexture_PileEater;
            break;
        }
    case kPinataType_UFO:
        {
            tex = kTexture_UFO1+(frame/UFO_FRAME_DURATION)%UFO_FRAMES;
            break;
        }
    case kPinataType_Zombie:
        {
            tex = kTexture_Fairy1+(frame/FAIRY_FRAME_DURATION)%FAIRY_FRAMES;
            break;
        }
    case kPinataType_Plane:
        {
            tex = kTexture_Plane;
            break;
        }
    case kPinataType_Osmos:
        {
            tex = kTexture_Osmos;
            break;
        }        
    case kPinataType_GoodGremlin:
        {
            tex = kTexture_GoodGremlin;
            break;
        }
    case kPinataType_BadGremlin:
        {
            tex = kTexture_BadGremlin;
            break;
        }                
    case kPinataType_MotherPileEater:
        {
            int maxPoints = kTexture_MotherPileEaterEnd-kTexture_MotherPileEaterBegin;
            if (hitPoints > maxPoints) {
                hitPoints = maxPoints;
            }
            tex = kTexture_MotherPileEaterEnd - hitPoints;
            break;
        }
    case kPinataType_Spike:
        {
            tex = kTexture_Spike;
            break;
        }
    case kPinataType_Pinhead:
        {  
            tex = (triggered)   ? kTexture_PinheadSpiked 
                                : kTexture_Pinhead;
            break;
        }
    case kPinataType_Treasure:
        {
            tex = kTexture_Treasure;
            break;
        }
    case kPinataType_Chameleon:
        {
            tex = kTexture_Chameleon;
            break;
        } 
    case kPinataType_Dog:
        {
            tex = kTexture_Dog;
            break;
        }
    case kPinataType_Cat:
        {
            tex = kTexture_Cat;
            break;
        }
    case kPinataType_Grower:
        {
            tex = kTexture_GoodGrower;
            break;
        }
    default:
        break;
    }
    return GetTexture(tex);
}

@end
