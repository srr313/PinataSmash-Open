//
//  Tool.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/14/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import "Tool.h"
#import "EAGLView.h"
#import "Game.h"
#import "GameParameters.h"
#import "MetagameManager.h"
#import "Particles.h"
#import "Pinata.h"
#import "PullCord.h"
#import "Sounds.h"

@interface Tool()
-(Boolean)swingAt:(TapEvent)tapEvent andDealDamage:(int)damage;
-(void)spawnSpikesAt:(Vector2D)position;
-(void)updatePullCord:(TapEvent)tapEvent;
@end

@implementation Tool

@synthesize type, count;

+(int)getPrice:(eTool)t {
    static int sToolPrices[] = {
        0, INT_MAX, 20, 20
    };
    
    return sToolPrices[t];
}

+(eTexture)getTexture:(eTool)t {
    return (eTexture)(kTexture_ToolsStart + t);
}

-(id)initType:(eTool)t forGame:(Game*)g {
    if (self == [super init]) {
        type    = t;
        game    = g;
        count   = 0;
        started = false;        
        lastTrigger     = [[NSDate date] retain];
        triggerDelay    = (t==kTool_AutoFire)?0.15f:0.0f;
    }
    return self;
}

-(void)dealloc {
    [lastTrigger    release];
    [lockedPullCord release];
    [super dealloc];
}

-(void)triggerAt:(TapEvent)tapEvent {
    [game triggerCandyAt:tapEvent];        
    [self updatePullCord:tapEvent];
    
    if (lockedPullCord) {
        started = false;
        return;
    }
    
    {
        NSDate* currentTime = [NSDate date];
        if ([currentTime timeIntervalSinceDate:lastTrigger] < triggerDelay) {
            return;
        }
        
        [lastTrigger release];
        lastTrigger = currentTime;
        [lastTrigger retain];
    }
        
    Vector2D tapLocation = Vector2DMake(tapEvent.location.x,tapEvent.location.y);    
    
    switch (type) {
        case kTool_Bat:
            if (tapEvent.type == kTapEventType_Start) {
                [self swingAt:tapEvent andDealDamage:1];                
            }
            break;
        case kTool_Bazooka:
            if (tapEvent.type == kTapEventType_Start) { 
                [game triggerGameEntsAt:tapEvent andDealDamage:1];

                [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_SmallExplosion)];                            

                [game explosionAt:tapLocation 
                        andRadius:  GAME_PARAMETERS.bazookaRadius 
                        andForce:   GAME_PARAMETERS.bazookaForce];
                ++count;
            }
            break;
        case kTool_AutoFire:
            if (tapEvent.type == kTapEventType_Start || (started && tapEvent.type == kTapEventType_Move)) {
                started = true;
                
                [PARTICLE_MANAGER createLaserFrom:  Vector2DMake(GetGLWidth(),0.1f*GetGLHeight())
                                    to:             tapLocation
                                    withColor:      Color3DMake(1.0f, 0.0f, 0.0f, 1.0f)];
                
                [PARTICLE_MANAGER createLaserFrom:  Vector2DMake(0.0f,0.1f*GetGLHeight())
                                    to:             tapLocation
                                    withColor:      Color3DMake(1.0f, 0.0f, 0.0f, 1.0f)];

                [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Laser)];

                if (![game triggerGameEntsAt:tapEvent andDealDamage:1]) {
                    [game repelAllGameEntsAt:tapLocation withStrength:100000.0f];
                    [game resetMultiplier];
                }
                ++count;
            }
            break;
        case kTool_SuperBat:
            if (tapEvent.type == kTapEventType_Start) {              
                [self swingAt:tapEvent andDealDamage:1];
                [self spawnSpikesAt:tapLocation];                  
            }
            break;
        default:
            break;
    }
}

-(Boolean)swingAt:(TapEvent)tapEvent andDealDamage:(int)damage {
    Boolean hitSomething = true;
    if (![game triggerGameEntsAt:tapEvent andDealDamage:damage]) {
        Vector2D tapLocation 
            = Vector2DMake(tapEvent.location.x,tapEvent.location.y);            
        
        [game swooshAt:tapLocation];
        
        Pinata* p = [game findNearestPinata:tapLocation];
        if (p) {
            static const int numMessages = 5;
            static const eLocalizedString sMessages[] = {
                @"Missed me!",
                @"Tough luck!",
                @"Ha Ha!",
                @"Bad swing!",
                @"Swoosh!",
            };        
            
            static int lastMessage = 0;
            int nextMessage = random()%numMessages;
            lastMessage = (lastMessage == nextMessage) ? (lastMessage+1)%numMessages : nextMessage;
            [Pinata postComment:sMessages[lastMessage] atPosition:p.position];
        }
        hitSomething = false;
    }
    ++count;
    ++METAGAME_MANAGER.totalBats;
    return hitSomething;
}

-(void)spawnSpikesAt:(Vector2D)position {
    float angleIncr = TWO_PI / GAME_PARAMETERS.pinheadSpikes;
    float currentAngle = TWO_PI * random()/RAND_MAX;
    
    for (int i = 0; i < GAME_PARAMETERS.pinheadSpikes; ++i) {
        Vector2D direction = Vector2DMake(cosf(currentAngle),sinf(currentAngle));
        Pinata* spawned =
            [PINATA_MANAGER NewPinata:game 
                at:Vector2DSub(position,ZeroVector())
                withVelocity:Vector2DMul(direction, 500.0f)
                withType:kPinataType_Spike
                withGhosting:false
                withVeggies:false
                withLifetime:GAME_PARAMETERS.pinheadSpikeLifetime];
        NSMutableArray* pinatas = [game getPinatas];
        [pinatas addObject:spawned];
        [spawned release];
        
        currentAngle += angleIncr;
    } 
}

-(void)stop {
    started = false;
}

-(void)updatePullCord:(TapEvent)tapEvent {

    if (lockedPullCord && !lockedPullCord.alive) {
        [lockedPullCord release];
        lockedPullCord = nil;
        return;
    }

    Vector2D location = Vector2DMake(tapEvent.location.x,tapEvent.location.y);
        
    if (lockedPullCord) {
        if (tapEvent.type == kTapEventType_Start || tapEvent.type == kTapEventType_End) {
            lockedPullCord.locked = false;
            [lockedPullCord release];
            lockedPullCord = nil;
        }
        else if (tapEvent.type == kTapEventType_Move) {
            lockedPullCord.position = location;
        }
    }
    else if (tapEvent.type == kTapEventType_Start || tapEvent.type == kTapEventType_Move) {
        PullCord* pullCord = [game getPullCordAt:tapEvent];
        if (pullCord) {
            lockedPullCord = pullCord;
            [lockedPullCord retain];
            lockedPullCord.locked = true;
            
            [PARTICLE_MANAGER createMistAt:location
                                withColor:COLOR3D_GREEN 
                                withScale:0.5f];
        }
    }
}

@end
