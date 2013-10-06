//
//  Sounds.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/25/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EAGLView.h"
#import "SimpleAudioEngine.h"

extern UInt32 sGameSounds[];
extern NSString* sGameSoundNames[];

#define TO_SOUND_SPACE_X(a) (2.0f*a/GetGLWidth()-1.0f)
#define TO_SOUND_SPACE_Y(a) (2.0f*a/GetGLHeight()-1.0f)

typedef enum {
	kSound_PinataSplit= 0,
    kSound_PinataDamage,
    kSound_PinataDestroy, 
    kSound_PileEaterKill, 
    kSound_UFOBeam,       
    kSound_Miss,
    kSound_EatOneCandy,
    kSound_ButtonPress,
    kSound_EaterSpawn,
    kSound_Swallow,
    kSound_Explosion,
    kSound_LevelTip,    
    kSound_CandyDrop,
    kSound_SlowMotion, 
    kSound_MotionSpeedup,   
    kSound_Shrink,        
    kSound_VegetablesDrop,
    kSound_PinataBox,   
    kSound_BalloonPop,
    kSound_BungeePull,
    kSound_BungeeHit,
    kSound_SugarHigh,
    kSound_SugarHighCandy, 
    kSound_MetricBonus,   
    kSound_Money,
    kSound_Inflate,
    kSound_Thunder,
    kSound_Gameover,
    kSound_ClockTick,
    kSound_Laser,   
    kSound_SmallExplosion, 
    kSound_PorcupineHit,
    kSound_FairyTransform,
    kSound_Treasure,
    kSound_Slurp,
	kSound_Count,
} eSound;

NSString* GetSoundName(eSound sound);
void InitializeSounds();


