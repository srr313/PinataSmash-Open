//
//  Sounds.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/25/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "Sounds.h"

UInt32 sGameSounds[kSound_Count];
NSString* sGameSoundNames[kSound_Count];

void InitializeSounds() {
    sGameSoundNames[kSound_PinataSplit]     = [[NSBundle mainBundle] pathForResource:@"BUBBLE_POP_FR"       ofType:@"wav"];
    sGameSoundNames[kSound_PinataDamage]    = [[NSBundle mainBundle] pathForResource:@"SHATTER_FR"          ofType:@"wav"]; 
    sGameSoundNames[kSound_PinataDestroy]   = [[NSBundle mainBundle] pathForResource:@"PINATA_DESTROY_FR"   ofType:@"wav"];
    sGameSoundNames[kSound_PileEaterKill]   = [[NSBundle mainBundle] pathForResource:@"SPLAT_FR"            ofType:@"wav"];                             
    sGameSoundNames[kSound_Miss]            = [[NSBundle mainBundle] pathForResource:@"WHOOSH_FR"           ofType:@"wav"];        
    sGameSoundNames[kSound_EatOneCandy]     = [[NSBundle mainBundle] pathForResource:@"EAT_ONE_CANDY_FR"    ofType:@"wav"];
    sGameSoundNames[kSound_ButtonPress]     = [[NSBundle mainBundle] pathForResource:@"BUTTON_PRESS_FR"     ofType:@"wav"];
    sGameSoundNames[kSound_Swallow]         = [[NSBundle mainBundle] pathForResource:@"GULP_FR"             ofType:@"wav"];
    sGameSoundNames[kSound_EaterSpawn]      = [[NSBundle mainBundle] pathForResource:@"EATER_SPAWN_FR"      ofType:@"wav"];                            
    sGameSoundNames[kSound_UFOBeam]         = [[NSBundle mainBundle] pathForResource:@"UFO_BEAM_FR"         ofType:@"wav"];                                
    sGameSoundNames[kSound_Laser]           = [[NSBundle mainBundle] pathForResource:@"LASER_FR"            ofType:@"wav"];                                                                  
    sGameSoundNames[kSound_Explosion]       = [[NSBundle mainBundle] pathForResource:@"EXPLOSION_FR"        ofType:@"wav"];
    sGameSoundNames[kSound_LevelTip]        = [[NSBundle mainBundle] pathForResource:@"LEVEL_TIP_FR"        ofType:@"wav"];                                  
    sGameSoundNames[kSound_CandyDrop]       = [[NSBundle mainBundle] pathForResource:@"CANDY_DROP_FR"       ofType:@"wav"];
    sGameSoundNames[kSound_SlowMotion]      = [[NSBundle mainBundle] pathForResource:@"SLOW_MOTION_FR"      ofType:@"wav"];
    sGameSoundNames[kSound_MotionSpeedup]   = [[NSBundle mainBundle] pathForResource:@"FAST_FR"             ofType:@"wav"];                                  
    sGameSoundNames[kSound_Shrink]          = [[NSBundle mainBundle] pathForResource:@"SHRINK_FR"           ofType:@"wav"];   
    sGameSoundNames[kSound_VegetablesDrop]  = [[NSBundle mainBundle] pathForResource:@"VEGETABLE_DROP_FR"   ofType:@"wav"];   
    sGameSoundNames[kSound_PinataBox]       = [[NSBundle mainBundle] pathForResource:@"PINATA_BOX_FR"       ofType:@"wav"];
    sGameSoundNames[kSound_BalloonPop]      = [[NSBundle mainBundle] pathForResource:@"BALLOON_POP_FR"      ofType:@"wav"];                
    sGameSoundNames[kSound_BungeeHit]       = [[NSBundle mainBundle] pathForResource:@"BUNGEE_HIT_FR"       ofType:@"wav"];                
    sGameSoundNames[kSound_BungeePull]      = [[NSBundle mainBundle] pathForResource:@"BUNGEE_PULL_FR"      ofType:@"wav"];                
    sGameSoundNames[kSound_SugarHigh]       = [[NSBundle mainBundle] pathForResource:@"SUGAR_HIGH_FR"       ofType:@"wav"];                            
    sGameSoundNames[kSound_SugarHighCandy]  = [[NSBundle mainBundle] pathForResource:@"SUGAR_HIGH_CANDY_FR" ofType:@"wav"];                                
    sGameSoundNames[kSound_MetricBonus]     = [[NSBundle mainBundle] pathForResource:@"METRIC_BONUS_FR"     ofType:@"wav"];                                    
    sGameSoundNames[kSound_Money]           = [[NSBundle mainBundle] pathForResource:@"MONEY_FR"            ofType:@"wav"];                                                                
    sGameSoundNames[kSound_Inflate]         = [[NSBundle mainBundle] pathForResource:@"INFLATE_FR"          ofType:@"wav"];                                                                
    sGameSoundNames[kSound_Thunder]         = [[NSBundle mainBundle] pathForResource:@"THUNDER_FR"          ofType:@"wav"];                                                                    
    sGameSoundNames[kSound_Gameover]        = [[NSBundle mainBundle] pathForResource:@"LOST_FR"             ofType:@"wav"];   
    sGameSoundNames[kSound_ClockTick]       = [[NSBundle mainBundle] pathForResource:@"CLOCK_TICK_FR"       ofType:@"wav"];                                                                                                                      
    sGameSoundNames[kSound_SmallExplosion]  = [[NSBundle mainBundle] pathForResource:@"SMALL_EXPLOSION_FR"  ofType:@"wav"];        
    sGameSoundNames[kSound_PorcupineHit]    = [[NSBundle mainBundle] pathForResource:@"PORCUPINE_HIT_FR"    ofType:@"wav"];        
    sGameSoundNames[kSound_FairyTransform]  = [[NSBundle mainBundle] pathForResource:@"FAIRY_TRANSFORM_FR"  ofType:@"wav"];        
    sGameSoundNames[kSound_Treasure]        = [[NSBundle mainBundle] pathForResource:@"TREASURE_FR"         ofType:@"wav"];        
    sGameSoundNames[kSound_Slurp]           = [[NSBundle mainBundle] pathForResource:@"SLURP_FR"            ofType:@"wav"];
    
    for (int i = 0; i < kSound_Count; ++i) {
        [[SimpleAudioEngine sharedEngine] preloadEffect:sGameSoundNames[i]];        
    }       
}

NSString* GetSoundName(eSound sound) {  
    return sGameSoundNames[sound];
}