//
//  ESRenderer.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright BlitShake LLC 2010. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@class Game;
@class ImageControl;
@class ParticleManager;
@class Screen;
@class TextControl;

typedef enum {
    kTexture_White,

    kTexture_UIBegin,
        kTexture_Title = kTexture_UIBegin,
        kTexture_CompanySplash,
        kTexture_TitleBackground,
        kTexture_Button,
        kTexture_PlayButton,
        kTexture_NextButton,
        kTexture_RetryButton,
        kTexture_BuyButton,
        kTexture_MenuButton,
        kTexture_AchievementButton,
        kTexture_CreditsButton,
        kTexture_GamePanel,        
        kTexture_MenuBackground,
        kTexture_BackButton,
        kTexture_LevelButton1,
        kTexture_LevelButton2,        
        kTexture_LevelButton3,                
        kTexture_LevelLock,
        kTexture_LevelBronze,
        kTexture_LevelSilver,
        kTexture_LevelGold,
        kTexture_Episode1,
        kTexture_Episode2,
        kTexture_Episode3,        
        kTexture_Episode1Background,
        kTexture_Episode2Background,
        kTexture_Episode3Background,                
        kTexture_PauseButton0,
        kTexture_PauseButton1,
        kTexture_PauseButton2,
        kTexture_GamePopup,
        kTexture_ModalPanel,
        kTexture_BankPanel,
        kTexture_LevelPriceTag,
        kTexture_EpisodePriceTag,
        kTexture_AltCloseButton,
        kTexture_CloseButton,
        kTexture_AchievementIcon,
        kTexture_QuestionMark,
        kTexture_Facebook,
        kTexture_AchievementPanel,
        kTexture_TimeIcon,
        kTexture_GameTitle,
    kTexture_UIEnd,    

    kTexture_GameBegin,
        kTexture_PlaygroundBack = kTexture_GameBegin,
        kTexture_ZooBack,
        kTexture_CircusBack,
        kTexture_CandyPileBG,
        kTexture_CandyPileFG,        
        kTexture_CandyPileSmall,
    kTexture_GameEnd,
    
    kTexture_Clouds,
    
    kTexture_Pinata,
    kTexture_GreenPinata,
    
    kTexture_StrongPinataBegin,
        kTexture_StrongPinata1 = kTexture_StrongPinataBegin,
        kTexture_StrongPinata2,
        kTexture_StrongPinata3,
    kTexture_StrongPinataEnd,
    
    kTexture_GreenStrongPinata1,
    kTexture_GreenStrongPinata2,
    kTexture_GreenStrongPinata3,    
    
    kTexture_BombPart,
    
    kTexture_PinataEaterBegin,
        kTexture_PinataEater1 = kTexture_PinataEaterBegin,
        kTexture_PinataEater2,
        kTexture_PinataEater3,
    kTexture_PinataEaterEnd,

    kTexture_MotherPileEaterBegin,
        kTexture_MotherPileEater1 = kTexture_MotherPileEaterBegin,
        kTexture_MotherPileEater2,
        kTexture_MotherPileEater3,
        kTexture_MotherPileEater4,
    kTexture_MotherPileEaterEnd,

    kTexture_WeakCandyPinata,
    kTexture_GreenWeakCandyPinata,
    
    kTexture_HeroPinata,
    kTexture_BreakableVegetablePinata,
    kTexture_BreakableVegetablePinataGlow,    
    kTexture_Disguised,
    kTexture_PileEater,
    kTexture_UFO1,
    kTexture_UFO2,
    kTexture_UFO3,
    kTexture_UFO4, 
    kTexture_Fairy1,
    kTexture_Fairy2,              
    kTexture_BadGremlin,
    kTexture_GoodGremlin,
    kTexture_Spike,
    kTexture_Pinhead,    
    kTexture_PinheadSpiked,    
    kTexture_Treasure, 
    kTexture_Plane,
    kTexture_Osmos, 
    kTexture_Chameleon,   
    kTexture_Dog,   
    kTexture_Cat, 
    kTexture_GoodGrower,
    kTexture_BadGrower,                 
    
    kTexture_KidBegin,
        kTexture_Kid1 = kTexture_KidBegin,
        kTexture_Kid1a,
        kTexture_Kid1b,
        kTexture_Kid2,
        kTexture_Kid2a,
        kTexture_Kid2b,
        kTexture_Kid2c,
        kTexture_Kid2d,
        kTexture_Kid2e,
        kTexture_Kid3,
        kTexture_Kid3a,
        kTexture_Kid3b,
        kTexture_Kid3c,
        kTexture_Kid3d,
        kTexture_Kid4,
        kTexture_KidEx,
        kTexture_KidEx1,
        kTexture_KidEx2,
        kTexture_KidEx3,
        kTexture_KidEx4,
        kTexture_KidEx5,
        kTexture_KidEx6,                                                                                                        
    kTexture_KidEnd,
    
    kTexture_SpeechBox,
    
    kTexture_BalloonBegin,
        kTexture_BalloonBlue = kTexture_BalloonBegin,
        kTexture_BalloonRed,
        kTexture_BalloonYellow,
        kTexture_BalloonGreen,
    kTexture_BalloonEnd,                                        

    kTexture_LargeExplosionBegin,
        kTexture_LargeExplosion1 = kTexture_LargeExplosionBegin,
        kTexture_LargeExplosion2,
        kTexture_LargeExplosion3,
        kTexture_LargeExplosion4,
        kTexture_LargeExplosion5,
        kTexture_LargeExplosion6,
        kTexture_LargeExplosion7,
    kTexture_LargeExplosionEnd,

    kTexture_SmallExplosionBegin,
        kTexture_SmallExplosion1 = kTexture_SmallExplosionBegin,
        kTexture_SmallExplosion2,
        kTexture_SmallExplosion3,
        kTexture_SmallExplosion4,
        kTexture_SmallExplosion5,
        kTexture_SmallExplosion6,
        kTexture_SmallExplosion7,
    kTexture_SmallExplosionEnd, 
    
    kTexture_SparkleBegin,
        kTexture_Sparkle1,
        kTexture_Sparkle2,
        kTexture_Sparkle3,
        kTexture_Sparkle4,
        kTexture_Sparkle5,                                
    kTexture_SparkleEnd,
    
    kTexture_SmokePuffBegin,
        kTexture_SmokePuff1,
        kTexture_SmokePuff2,
        kTexture_SmokePuff3,
        kTexture_SmokePuff4,
        kTexture_SmokePuff5,   
        kTexture_SmokePuff6,                                        
    kTexture_SmokePuffEnd,
        
    kTexture_TapMissBegin,
        kTexture_TapMiss1 = kTexture_TapMissBegin,
        kTexture_TapMiss2,
        kTexture_TapMiss3,
        kTexture_TapMiss4,
    kTexture_TapMissEnd,  
    
    kTexture_HitBegin,
        kTexture_Hit1 = kTexture_HitBegin,
        kTexture_Hit2,
        kTexture_Hit3,
        kTexture_Hit4,
        kTexture_Hit5,
        kTexture_Hit6,
        kTexture_Hit7,        
    kTexture_HitEnd,     
                                      
    kTexture_ParticlesBegin,
        kTexture_LargeExplosion = kTexture_LargeExplosionBegin,
        kTexture_SmallExplosion = kTexture_SmallExplosionBegin,
        kTexture_TapMiss        = kTexture_TapMissBegin,
        kTexture_Hit            = kTexture_HitBegin,
        kTexture_Vegetable      = kTexture_ParticlesBegin+4,
        kTexture_Mist,
    kTexture_ParticlesEnd,
    
    kTexture_ConfettiBegin,
        kTexture_Confetti0 = kTexture_ConfettiBegin,
        kTexture_Confetti1,
        kTexture_Confetti2,
        kTexture_Confetti3,
        kTexture_Confetti4,
        kTexture_Confetti5,
        kTexture_Confetti6,
        kTexture_Confetti7,
        kTexture_Confetti8,  
        kTexture_Confetti9,                
    kTexture_ConfettiEnd,
                            
    kTexture_CandyBegin,
        kTexture_Candy_01 = kTexture_CandyBegin,
        kTexture_Candy_02,
        kTexture_Candy_03,
        kTexture_Candy_04,
        kTexture_Candy_05,
        kTexture_Candy_06,        
        kTexture_Candy_07,
        kTexture_Candy_08,
        kTexture_Candy_09,
        kTexture_Candy_10,
        kTexture_Candy_11,
        kTexture_Candy_12,
        kTexture_Candy_13,
        kTexture_Candy_14, 
        kTexture_Candy_15, 
        kTexture_Candy_16, 
        kTexture_Candy_17, 
        kTexture_Candy_18, 
        kTexture_Candy_19, 
        kTexture_Candy_20,
        kTexture_Candy_21,
        kTexture_Candy_22,
        kTexture_Candy_23,
        kTexture_Candy_24, 
        kTexture_Candy_25, 
        kTexture_Candy_26, 
        kTexture_Candy_27, 
        kTexture_Candy_28,          
    kTexture_CandyEnd,       
        
    kTexture_PowerupStart,
        kTexture_BombPowerup = kTexture_PowerupStart,
        kTexture_CandyPowerup,
        kTexture_NegativePowerup,
        kTexture_SlowMotionPowerup,
        kTexture_ShrinkPowerup,
        kTexture_PinataBox,
    kTexture_PowerupEnd,
    
    kTexture_Bungee,
    kTexture_PullCordHandle,
    
    kTexture_ToolsStart,
        kTexture_BatTool = kTexture_ToolsStart,
        kTexture_SuperBatTool, 
        kTexture_BazookaTool,
        kTexture_AutoFireTool,   
    kTexture_ToolsEnd,
    
    kTexture_Gift,    
	
    kTexture_Count,
    kTexture_Null,
} eTexture;

@protocol ESRenderer <NSObject>

- (void)render:(const Game*)game 
            afterTimeElapsed:(float)timeElapsed 
            withParticleManager:(ParticleManager*)pm 
            andScreen:(Screen*)screen
            andFilter:(ImageControl*)filter
            andPopupElements:(NSMutableArray*)popupElements;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (void)initGameTextures;
- (void)initUITextures;
@end
