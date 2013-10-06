//
//  WeatherCloud.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 3/26/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import "WeatherCloud.h"
#import "EAGLView.h"
#import "Game.h"
#import "GameParameters.h"
#import "LevelEnvironment.h"
#import "Pinata.h"
#import "Sounds.h"

@implementation WeatherCloud

@synthesize fractionDogs, fallSpeed, spawnDelay, lifetime;

-(float)top {
    Texture2D* texture  = GetTexture(kTexture_Clouds);
    return (ToScreenScaleY(GetGLHeight())+0.5f*texture.pixelsHigh);    
}

-(float)bottom {
    Texture2D* texture  = GetTexture(kTexture_Clouds);
    return (ToScreenScaleY(GetGLHeight())-0.25f*texture.pixelsHigh);
}

-(id)initForGame:(Game*)g {
    if (self = [super init]) {
        game        = g;
        lastRain    = 0.0f;
        raining     = false;
        descendT    = descendTarget = [self top];
    }
    return self;
}

-(void)tick:(float)timeElapsed {
    descendT    += timeElapsed*(descendTarget-descendT);
    descendT    =  fmaxf(fminf(descendT, [self top]), [self bottom]);

    if (raining) {
        lastRain += timeElapsed;
        if (lastRain >= spawnDelay) {
            Texture2D* texture  = GetTexture(kTexture_Clouds);        
            Vector2D location = Vector2DMake(
                                    GetGLWidth()*random()/(float)RAND_MAX,
                                    GetGLHeight()-ToGameScaleY(0.25f*texture.pixelsHigh));
            ePinataType type = (random()/(float)RAND_MAX < fractionDogs)
                                    ? kPinataType_Dog
                                    : kPinataType_Cat;        
            Pinata* spawned =
                [PINATA_MANAGER NewPinata:      game 
                                at:             location
                                withVelocity:   Vector2DMake(0.0f,-fallSpeed)
                                withType:       type
                                withGhosting:   false
                                withVeggies:    false
                                withLifetime:   1.0f];                
            [spawned addAllParts];

            [[game getPinatas] addObject:spawned];
            [spawned release];
            
            lastRain = 0.0f;
            
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_EaterSpawn)];        
        }
    }
}

-(void)render:(float)timeElapsed {
    Texture2D* texture  = GetTexture(kTexture_Clouds);
    
    // draw inside
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);    
    glLoadIdentity();
    glTranslatef(   ToScreenScaleX(0.5f*GetGLWidth()), 
                    descendT, 
                    0.0f);
    [texture draw];
}

-(void)setRain:(Boolean)flag {
    raining = flag;
    
    if (raining) {
        descendTarget   = [self bottom];
        [game.levelEnvironment flashBackground:COLOR3D_WHITE];          
        [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Thunder)];        
    }
    else {
        descendTarget   = [self top];
    }
}

@end
