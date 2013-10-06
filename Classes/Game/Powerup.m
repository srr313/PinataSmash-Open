//
//  Powerup.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/20/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "Powerup.h"
#import "Bungee.h"
#import "EAGLView.h"
#import "ESRenderer.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "GameParameters.h"
#import "JiggleAnimation.h"
#import "LevelEnvironment.h"
#import "MetagameManager.h"
#import "Particles.h"
#import "Pinata.h"
#import "Sounds.h"
#import "Tool.h"

@interface Powerup()
-(Vector2D)dimensions;
-(eTexture)getPowerupTexture;
@end


@implementation Powerup

@synthesize position, velocity, color, alive, type, subtype, angle, pinataType, parachute, bungee;

#define RAND_POWERUP_SWITCH_TIME 0.5f

static inline ePowerupType NewRandPowerupType(ePowerupType t) {
    int i = t;
    while (i==t || i==kPowerupType_Pinatas) {
        i = random()%(kPowerupType_Count-1);
    }
    return i;
}

-(Vector2D)dimensions {
    return GetTextureDimensions([self getPowerupTexture]);
}

-(id)initForGame:(Game*)g at:(Vector2D)p 
            withVelocity:(Vector2D)v 
            andType:(ePowerupType)t 
            andLifetime:(float)lt  {
    if (self == [super init]) {
        game        = g;
        position    = p;
        velocity    = v;
        spawnTime   = 0.0f;
        lifetime    = lt;
        color       = COLOR3D_WHITE;
        type        = t;
        alive       = true;
        timeOnState = 0.0f;
        pointInsideParachute = false;
        
        subtype = kPowerupType_Count;
        if (type == kPowerupType_Random) {
            subtype = NewRandPowerupType(subtype);
        }
        
        jiggler = [[JiggleAnimation alloc] init];
        [jiggler jiggleFreq:20.0f andAmplitude:0.05f andDuration:FLT_MAX];        
        
        angle = 0.0f;
        
        NSAssert(type<kPowerupType_Count, @"Invalid powerup type");
    }
    return self;
}

-(id)initPinataTypeForGame:(Game*)g 
                            at:(Vector2D)p 
                            withVelocity:(Vector2D)v 
                            andLifetime:(float)lt
                            andPinataType:(ePinataType)t 
                            andNumPinatas:(int)n
                            andPinataGhosting:(Boolean)ghost
                            andPinataVeggies:(Boolean)veggies
                            andPinataLifetime:(float)pinataLt {
    numPinatas      = n;
    pinataType      = t;
    pinataGhosting  = ghost;
    pinataVeggies   = veggies;
    pinataLifetime  = pinataLt;
    return [self initForGame:g at:p 
                    withVelocity:v  
                    andType:kPowerupType_Pinatas
                    andLifetime:lt];
}

-(Boolean)isInside:(CGPoint)p {
    Vector2D dim = GetImageDimensions(kTexture_PowerupStart);    
    Boolean insidePowerup = fabsf(p.x-position.x) <= dim.x/2 &&
                            fabsf(p.y-position.y) <= dim.y/2;    
    
    pointInsideParachute = false;
    if (!insidePowerup) {
        if (parachute && [parachute isInside:p]) {
            pointInsideParachute = true;
            return true;
        }    
    }
    
    return insidePowerup;
}

-(void)tick:(float) timeElapsed {
    spawnTime += timeElapsed;

    Boolean pastLifespan = (lifetime > 0.0f && spawnTime > lifetime);

    [jiggler tick:timeElapsed];

    if (!bungee || pastLifespan) {
        // offscreen
        float rPadded = 1.5f*[self dimensions].x; 
        if (velocity.x > 0.0f && position.x > game.labWidth+rPadded 
            || velocity.x < 0.0f && position.x < -rPadded
            || velocity.y < 0.0f && position.y < -rPadded) {
            alive = false;
            return;
        }
    }
    
    Boolean controlledByManipulator = false;
        
    if (parachute) {
        [parachute tick:timeElapsed];
        velocity = parachute.velocity;
        angle = parachute.angle;
        position = Vector2DMake(parachute.position.x,parachute.position.y-parachute.cargoOffset);
        controlledByManipulator = true;
    }
    else if (bungee) {
        if (pastLifespan) {    
            bungee.alpha = fmaxf(1.0f-(spawnTime-lifetime), 0.0f);
        }
        else {
            velocity = bungee.velocity;
            angle = bungee.angle;
            position = bungee.cargoPosition;        
            [bungee tick:timeElapsed];
            controlledByManipulator = true;
        }
    }
    
    if (!controlledByManipulator) {
        angle += timeElapsed;
        velocity.y -= GAME_PARAMETERS.fallSpeed * timeElapsed;
        position = Vector2DAdd(position, Vector2DMul(velocity, timeElapsed));
    }
        
    timeOnState += timeElapsed;        
        
    if (type == kPowerupType_Random && timeOnState >= RAND_POWERUP_SWITCH_TIME) {
        subtype = NewRandPowerupType(subtype);
        timeOnState = 0.0f;
    }
}

-(Boolean)trigger {
    if (!alive) {
        return false;
    }

    if (parachute && pointInsideParachute) { 
        [parachute trigger];
        return true;
    }

    if (type==kPowerupType_Random) {
        type = subtype;
    }

    switch (type) {
    case kPowerupType_Bomb:
        {
            [game vibrate];
            
            [game explosionAt:position 
                    andRadius:GAME_PARAMETERS.bombRadius 
                    andForce:GAME_PARAMETERS.bombForce];
                    
            [game.levelEnvironment jiggleBackground];                    

            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Explosion)];            
                
            METAGAME_MANAGER.totalBombsDestroyed++;
                            
            break;
        }
    case kPowerupType_Candy:
        {
            float randFrac = RAND_CANDY_PIECES_PER_RELEASE*random()/(float)RAND_MAX;  
            int candies = (int)(GAME_PARAMETERS.strongPinataCandy * randFrac);
            [game spawnCandyPieces:candies atPosition:position];                
            [game addCandy:GAME_PARAMETERS.strongPinataCandy useMultiplier:false];
            [game setSugarRushMode:true];
            
            [PARTICLE_MANAGER createCandyExplosionAt:position 
                                withAmount:GAME_PARAMETERS.strongPinataCandy*CANDY_TO_VFX_RATIO
                                withLayer:kLayer_Game];
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_CandyDrop)];
            
            break;
        }
    case kPowerupType_Negative:
        {
            // subtract candy from pile
            [game addCandy:(-GAME_PARAMETERS.healthyPinataVegetables) useMultiplier:false];
            [game.levelEnvironment flashBackground:COLOR3D_RED];                                            
            
            METAGAME_MANAGER.totalVegetablesCollected += fabsf(GAME_PARAMETERS.healthyPinataVegetables);            
            
            [PARTICLE_MANAGER   createVegetableExplosionAt:position 
                                withAmount:fabsf(GAME_PARAMETERS.healthyPinataVegetables)*VEGETABLE_TO_VFX_RATIO];
            
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_VegetablesDrop)];
            break;
        }
    case kPowerupType_SlowMotion: 
        {
            [game   setSimulationSpeed:GAME_PARAMETERS.slowMotionSpeed 
                    withDuration:GAME_PARAMETERS.slowMotionDuration];
            [PARTICLE_MANAGER createConfettiAt:position withAmount:15 withLayer:kLayer_Game];                 
            
            [game.levelEnvironment flashBackground:COLOR3D_WHITE];                                            
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_SlowMotion)];
            break;
        }
    case kPowerupType_Shrink: 
        {
            [game   setPinataScale:GAME_PARAMETERS.shrinkScale 
                    withPinataBehavior:0xFFFF            
                    withDuration:GAME_PARAMETERS.shrinkDuration];
            [game   setSimulationSpeed:GAME_PARAMETERS.shrinkSpeed 
                    withDuration:GAME_PARAMETERS.shrinkDuration];                    
            [PARTICLE_MANAGER createConfettiAt:position withAmount:15 withLayer:kLayer_Game];                 
            
            [game.levelEnvironment flashBackground:COLOR3D_GREEN];                                
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Shrink)];
            break;
        }
    case kPowerupType_Pinatas:
        {
            for (int i = 0; i < numPinatas; ++i) {
                Vector2D spawnVelocity = 
                    (pinataType != kPinataType_Hero)
                        ? MakeRandVector2D(GAME_PARAMETERS.splitSpeed)
                        : MakeRandVector2D(40.0f);
                Pinata* spawned =
                    [PINATA_MANAGER NewPinata:game 
                                    at:position 
                                    withVelocity:spawnVelocity
                                    withType:pinataType
                                    withGhosting:pinataGhosting
                                    withVeggies:pinataVeggies
                                    withLifetime:pinataLifetime];
                [spawned addAllParts];

                NSMutableArray* pinatas = [game getPinatas];
                [pinatas addObject:spawned];
            }
             
            if (pinataType == kPinataType_PileEater) {
                METAGAME_MANAGER.totalTicksFreed += numPinatas;
            }
            else if (pinataType == kPinataType_Hero) {
                METAGAME_MANAGER.totalHerosFreed += numPinatas;
            }
            
            [PARTICLE_MANAGER createConfettiAt:position withAmount:15 withLayer:kLayer_Game];                 
            
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PinataBox)];
            
            break;
        }
    case kPowerupType_MetricBonus:
        {
            [PARTICLE_MANAGER createConfettiAt:position withAmount:15 withLayer:kLayer_Game];                             
            
            [game addMetricBonus:GAME_PARAMETERS.metricBonus atPosition:position];
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_MetricBonus)];              
        }
    default:break;
    }
    
    if (parachute) {
        [parachute releaseCargo];
        [[game getParachutes] addObject:parachute];
    }
    
    alive = false;
    return true;
}

- (void)dealloc {      
    [jiggler release];
    [parachute release];
    [bungee release];
    [super dealloc];
}

-(void)attach:(Parachute *)chute {
    NSAssert(!parachute, @"Powerup::attach - parachute already attached!");
    parachute = chute;
    [parachute attatch:self];
    [parachute retain];
}

-(void)remove:(Parachute *)chute {
    NSAssert(parachute, @"Powerup::remove - parachute not attached!");
    [parachute release];
    parachute = nil;
}

-(void)attachCord:(Bungee *)b {
    NSAssert(!bungee, @"Powerup::attach - bungee already attached!");
    bungee = b;
    [bungee attatch:self];
    [bungee retain];
}

-(void)removeCord:(Bungee *)b {
    NSAssert(bungee, @"Powerup::remove - bungee not attached!");
    [bungee release];
    bungee = nil;
}

-(void)addForce:(Vector2D)force {
    if (parachute) {
        [parachute addForce:force];
    }
    else if (bungee) {
        [bungee addForce:force];
    }
    else {
        velocity = Vector2DAdd(velocity, force);        
    }
}

- (void)render:(float)timeElapsed {
    if (!alive) {
        return;
    }

    eTexture tex = [self getPowerupTexture];
    
    Texture2D* texture = GetTexture(tex);
    float angleDegree = angle*RAD_TO_DEGR;
    
    [parachute render:timeElapsed];
    [bungee render:timeElapsed];
    
    float scale = jiggler.scale;

    if (IsGameShadowsEnabled()) {
        Vector2D shadowOffset = [ES1Renderer shadowOffset];
        Color3D shadowColor = [game shadowColor];        
    
        // render shadow
        glLoadIdentity();        
        glTranslatef(ToScreenScaleX(position.x+shadowOffset.x), ToScreenScaleY(position.y+shadowOffset.y), 0.0f);
        glRotatef(angleDegree,0.0f,0.0f,1.0f);
        glScalef(scale, scale, 1.0f);        
        glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, shadowColor.alpha); 
        [texture draw];
    }
    
    if (IsGameMotionBlurEnabled()) {
        float blurAlpha = 0.75f*Vector2DMagnitude(velocity)/GAME_PARAMETERS.maxPinataSpeed;
        if (blurAlpha > 0.1f) {
            // motion blur
            glLoadIdentity();
            glTranslatef(ToScreenScaleX(position.x-2.0f*timeElapsed*velocity.x), 
                            ToScreenScaleY(position.y-2.0f*timeElapsed*velocity.y), 0.0f);
            glRotatef(angleDegree,0.0f,0.0f,1.0f);
            glScalef(scale, scale, 1.0f);     
            glColor4f(1.0f, 1.0f, 1.0f, blurAlpha);
            [texture draw];    
        }
    }
    
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
    glRotatef(angleDegree,0.0f,0.0f,1.0f);
    glScalef(scale, scale, 1.0f);        
    glColor4f(color.red, color.green, color.blue,1.0f); 
    [texture draw];       
    
    if (type == kPowerupType_Pinatas) {
        static const float BoxArtScale = 0.5f;
        Texture2D* texture = [Pinata    getTexture:     pinataType 
                                        withHitPoints:  INT_MAX 
                                        wasTriggered:   false
                                        veggies:        pinataVeggies                                        
                                        frame:          0];
        glTranslatef(0.0f, 0.125f*BoxArtScale*ToGameScaleY(texture.pixelsHigh), 0.0f);                                                
        glRotatef(15.0f, 0.0f, 0.0f, 1.0f);
        glScalef(BoxArtScale, BoxArtScale, 1.0f);
        [texture draw];          
    }
}

-(eTexture)getPowerupTexture {
    ePowerupType powerupType = (type==kPowerupType_Random) ? subtype : type;
    eTexture tex = kTexture_PowerupStart+(int)(powerupType);
//    if (powerupType==kPowerupType_Pinatas&&(pinataType!=kPinataType_Hero&&pinataType!=kPinataType_Strong)) {
//        ++tex; // use 'bad' texture
//    }
    
    if (powerupType==kPowerupType_MetricBonus) {
        if (game.gameLevel.rule.metric==kGameRule_Time) {
            tex = kTexture_TimeIcon;
        }
        else if (game.gameLevel.rule.metric==kGameRule_Shots) {
            tex = [Tool getTexture:game.tool.type];    
        }
    }
    return tex;
}

@end




