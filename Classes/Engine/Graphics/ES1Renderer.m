//
//  ES1Renderer.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright BlitShake LLC 2010. All rights reserved.
//

#import "ES1Renderer.h"
#import "EAGLView.h"
#import "CandyPile.h"
#import "Game.h"
#import "Particles.h"
#import "Pinata.h"
#import "Powerup.h"
#import "Screen.h"

static Texture2D* textures[kTexture_Count];
static NSString* textureNames[kTexture_Count];
static int textureCategory[kTexture_Count];

static int sTextureLoadCategory = 0;
static int kUndefinedCategory = -1;
static int kCommonCategory  = 0;
static int kUICategory      = 1;
static int kGameCategory    = 2;

NSString* GetDeviceImageName(NSString* name, eDisplayMode display) {
    NSString* imageName = nil;
    if (IsDeviceIPad() || display == kIPad) {
        imageName = [name stringByReplacingOccurrencesOfString:@"." withString:@"_IPAD."];
    }
    else if (display == kRetina) {
        imageName = [name stringByReplacingOccurrencesOfString:@"." withString:@"_HD."];    
    }
    else {
        imageName = name;
    }
    return imageName;
}

Texture2D* GetTexture(eTexture tex) {
    return textures[tex];
}

eTexture GetTextureId(NSString* name) {
    for (int i = 0; i < kTexture_Count; ++i) {
        // check high-def and standard names
        if ([GetDeviceImageName(name, kIPad) compare:textureNames[i]]==NSOrderedSame
        ||  [GetDeviceImageName(name, kRetina) compare:textureNames[i]]==NSOrderedSame
        ||  [name compare:textureNames[i]]==NSOrderedSame) {
            return i;
        }
    }
    #ifdef DEBUG_BUILD            
        NSLog(@"GetTextureId invalid id: %@", name);
    #endif
    return kTexture_Count;
}

Vector2D GetTextureDimensions(eTexture tex) {
    return Vector2DMake(textures[tex].pixelsWide,textures[tex].pixelsHigh);
}

Vector2D GetImageDimensions(eTexture tex) {
    return Vector2DMake(ToGameScaleX(textures[tex].pixelsWide),ToGameScaleY(textures[tex].pixelsHigh));
}

Vector2D MakeRandScreenVector() {
    return
        Vector2DMake(   GetGLWidth()*random()/(float)RAND_MAX,
                        GetGLHeight()*random()/(float)RAND_MAX);
}

@interface ES1Renderer()
-(void)initTexture:(NSString*)named withKey:(eTexture)key
        filterNearest:(Boolean)nearest wrapClamp:(Boolean)clamp;
@end


@implementation ES1Renderer

static const GLfloat SquareVertices[] = {
    -0.5f,  -0.5f,
     0.5f,  -0.5f,
    -0.5f,   0.5f,
     0.5f,   0.5f,
};

static inline float MotionBlurAlpha(Vector2D velocity) {
    #define MAX_BLUR 0.4f
    #define VELOCITY_ALPHA 0.0015f
    return 1.0f - fminf(MAX_BLUR,VELOCITY_ALPHA*Vector2DMagnitude(velocity));
}

static Vector2D sShadowOffset;

+(Vector2D)shadowOffset { 
    return sShadowOffset;
}

-(void)initTexture:(NSString*)named withKey:(eTexture)key
        filterNearest:(Boolean)nearest wrapClamp:(Boolean)clamp {
    
    if (textures[key]!=nil) {
        #ifdef DEBUG_BUILD            
            NSLog(@"ES1Renderer:initTextures already set");
        #endif
        
        return;
    }
    
    NSString* imageName = GetDeviceImageName(named, GetDisplayMode());
    UIImage* imageFile = [UIImage imageNamed:imageName];
    if (!imageFile) {
        if (GetDisplayMode() == kRetina) {
            imageName = GetDeviceImageName(named, kIPad); // use iPad as fallback
            imageFile = [UIImage imageNamed:imageName];        
        }
    
        // finally use standard as a fallback
        if (!imageFile) {
            imageName = named;
            imageFile = [UIImage imageNamed:imageName];
        }
    }
    
    textures[key] = [[Texture2D alloc] initWithImage:imageFile 
                        filterNearest:nearest wrapClamp:clamp]; 
                        
                        
    
    if (!textureNames[key]) {
        textureNames[key] = [imageName retain];
    }

    textureCategory[key] = sTextureLoadCategory;
}

- (void)resetTextures {
    for (int i = 0; i < kTexture_Count; ++i) {
        [textures[i] release];
        textures[i] = nil;
        
        [textureNames[i] release];
        textureNames[i] = nil;
        
        textureCategory[i] = kUndefinedCategory;
    }
}

- (void)clearTextureCategory:(int)category {
    for (int i = 0; i < kTexture_Count; ++i) {
        if (textureCategory[i] == category) {
            [textures[i] release];
            textures[i] = nil;
        }
    }
}

- (void)initCommonTextures {
    sTextureLoadCategory = kCommonCategory;
    [self initTexture:@"White.png"          withKey:kTexture_White          filterNearest:true wrapClamp:true];
    [self initTexture:@"PlayButton.png"     withKey:kTexture_PlayButton     filterNearest:false wrapClamp:true];
    [self initTexture:@"BuyButton.png"      withKey:kTexture_BuyButton      filterNearest:false wrapClamp:true];
    [self initTexture:@"LevelSilver.png"    withKey:kTexture_LevelSilver 	filterNearest:false wrapClamp:true];
    [self initTexture:@"LevelBronze.png"    withKey:kTexture_LevelBronze 	filterNearest:false wrapClamp:true];
    [self initTexture:@"LevelGold.png"      withKey:kTexture_LevelGold      filterNearest:false wrapClamp:true];
    [self initTexture:@"ModalPanel.png"     withKey:kTexture_ModalPanel     filterNearest:false wrapClamp:true];    
    [self initTexture:@"BankPanel.png"      withKey:kTexture_BankPanel      filterNearest:false wrapClamp:true];    
    [self initTexture:@"LevelPriceTag.png"  withKey:kTexture_LevelPriceTag  filterNearest:false wrapClamp:true];
    [self initTexture:@"LevelLock.png"      withKey:kTexture_LevelLock      filterNearest:false wrapClamp:true];    
    [self initTexture:@"AltCloseButton.png" withKey:kTexture_AltCloseButton filterNearest:false wrapClamp:true];    
    [self initTexture:@"CloseButton.png"    withKey:kTexture_CloseButton    filterNearest:false wrapClamp:true];

    [self initTexture:@"Candy_01.png"   withKey:kTexture_Candy_01 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_02.png"   withKey:kTexture_Candy_02 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_03.png"   withKey:kTexture_Candy_03 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_04.png"   withKey:kTexture_Candy_04 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_05.png"   withKey:kTexture_Candy_05 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_06.png"   withKey:kTexture_Candy_06   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_07.png"   withKey:kTexture_Candy_07   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_08.png"   withKey:kTexture_Candy_08   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_09.png"   withKey:kTexture_Candy_09 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_10.png"   withKey:kTexture_Candy_10 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_11.png"   withKey:kTexture_Candy_11 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_12.png"   withKey:kTexture_Candy_12   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_13.png"   withKey:kTexture_Candy_13   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_14.png"   withKey:kTexture_Candy_14   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_15.png"   withKey:kTexture_Candy_15   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_16.png"   withKey:kTexture_Candy_16   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_17.png"   withKey:kTexture_Candy_17   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_18.png"   withKey:kTexture_Candy_18   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_19.png"   withKey:kTexture_Candy_19   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_20.png"   withKey:kTexture_Candy_20 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_21.png"   withKey:kTexture_Candy_21 	filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_22.png"   withKey:kTexture_Candy_22   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_23.png"   withKey:kTexture_Candy_23   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_24.png"   withKey:kTexture_Candy_24   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_25.png"   withKey:kTexture_Candy_25   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_26.png"   withKey:kTexture_Candy_26   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_27.png"   withKey:kTexture_Candy_27   filterNearest:false wrapClamp:true];
    [self initTexture:@"Candy_28.png"   withKey:kTexture_Candy_28   filterNearest:false wrapClamp:true];
    
    [self initTexture:@"Balloon_Blue.png"           withKey:kTexture_BalloonBlue        filterNearest:false wrapClamp:true];
    [self initTexture:@"Balloon_Red.png"        	withKey:kTexture_BalloonRed         filterNearest:false wrapClamp:true];
    [self initTexture:@"Balloon_Yellow.png"     	withKey:kTexture_BalloonYellow      filterNearest:false wrapClamp:true];
    [self initTexture:@"Balloon_Green.png"          withKey:kTexture_BalloonGreen       filterNearest:false wrapClamp:true];    
        
    [self initTexture:@"BG_1_BACK.png"      withKey:kTexture_PlaygroundBack     filterNearest:true wrapClamp:false];    
    [self initTexture:@"BG_2_BACK.png"      withKey:kTexture_ZooBack            filterNearest:true wrapClamp:false];    
    [self initTexture:@"BG_3_BACK.png"      withKey:kTexture_CircusBack         filterNearest:true wrapClamp:false];            

    [self initTexture:@"GamePopup.png"      withKey:kTexture_GamePopup      filterNearest:false wrapClamp:true];    
        
    [self initTexture:@"SmokePuff1.png"     withKey:kTexture_SmokePuff1     filterNearest:false wrapClamp:true];    
    [self initTexture:@"SmokePuff2.png"     withKey:kTexture_SmokePuff2     filterNearest:false wrapClamp:true];    
    [self initTexture:@"SmokePuff3.png"     withKey:kTexture_SmokePuff3     filterNearest:false wrapClamp:true];    
    [self initTexture:@"SmokePuff4.png"     withKey:kTexture_SmokePuff4     filterNearest:false wrapClamp:true];    
    [self initTexture:@"SmokePuff5.png"     withKey:kTexture_SmokePuff5     filterNearest:false wrapClamp:true];                    
    [self initTexture:@"SmokePuff6.png"     withKey:kTexture_SmokePuff6     filterNearest:false wrapClamp:true];                                                                                                  
    
    [self initTexture:@"YellowLarge.png"        withKey:kTexture_Confetti0 filterNearest:true wrapClamp:true]; 
    [self initTexture:@"YellowSmall.png"        withKey:kTexture_Confetti1 filterNearest:true wrapClamp:true];
    [self initTexture:@"GreenLarge.png"         withKey:kTexture_Confetti2 filterNearest:true wrapClamp:true];           
    [self initTexture:@"GreenSmall.png"         withKey:kTexture_Confetti3 filterNearest:true wrapClamp:true];
    [self initTexture:@"BlueLarge.png"          withKey:kTexture_Confetti4 filterNearest:true wrapClamp:true];
    [self initTexture:@"BlueSmall.png"          withKey:kTexture_Confetti5 filterNearest:true wrapClamp:true];
    [self initTexture:@"PurpleLarge.png"        withKey:kTexture_Confetti6 filterNearest:true wrapClamp:true];
    [self initTexture:@"PurpleSmall.png"        withKey:kTexture_Confetti7 filterNearest:true wrapClamp:true];          
    [self initTexture:@"GreenLarge.png"         withKey:kTexture_Confetti8 filterNearest:true wrapClamp:true];                      
    [self initTexture:@"GreenSmall.png"        	withKey:kTexture_Confetti9 filterNearest:true wrapClamp:true];                          
    
    // title UI elements
    [self initTexture:@"StrongPinata1.png"  withKey:kTexture_StrongPinata1  filterNearest:false wrapClamp:true];    
    [self initTexture:@"PinataHero.png"     withKey:kTexture_HeroPinata     filterNearest:false wrapClamp:true];
    [self initTexture:@"Pinhead.png"        withKey:kTexture_Pinhead        filterNearest:false wrapClamp:true];    
    [self initTexture:@"Kid1.png"           withKey:kTexture_Kid1           filterNearest:false wrapClamp:true];    
    [self initTexture:@"WeakPinata.png"     withKey:kTexture_WeakCandyPinata filterNearest:false wrapClamp:true];  
    [self initTexture:@"GoodGremlin.png"    withKey:kTexture_GoodGremlin    filterNearest:false wrapClamp:true];        
    
    [self initTexture:@"Kid4.png"           withKey:kTexture_Kid4           filterNearest:false wrapClamp:true];    
    [self initTexture:@"SpeechBox.png"       withKey:kTexture_SpeechBox     filterNearest:false wrapClamp:true];    
    
    [self initTexture:@"Gift.png"               withKey:kTexture_Gift           filterNearest:false wrapClamp:true];            
}

- (void)initUITextures {
    [self clearTextureCategory:kGameCategory];

    [self initTexture:@"CompanySplash.png" withKey:kTexture_CompanySplash   filterNearest:true wrapClamp:true];    

    sTextureLoadCategory = kUICategory;
    [self initTexture:@"AchievementButton.png" withKey:kTexture_AchievementButton   filterNearest:false wrapClamp:true];
    [self initTexture:@"CreditsButton.png"  withKey:kTexture_CreditsButton  filterNearest:false wrapClamp:true];        
    [self initTexture:@"Button.png"         withKey:kTexture_Button         filterNearest:false wrapClamp:true];
    [self initTexture:@"MenuBackground.png" withKey:kTexture_MenuBackground filterNearest:true wrapClamp:true];    
    [self initTexture:@"BackButton.png"     withKey:kTexture_BackButton     filterNearest:false wrapClamp:true];

    [self initTexture:@"LevelButton1.png"   withKey:kTexture_LevelButton1   filterNearest:false wrapClamp:true];
    [self initTexture:@"LevelButton2.png"   withKey:kTexture_LevelButton2   filterNearest:false wrapClamp:true];    
    [self initTexture:@"LevelButton3.png"   withKey:kTexture_LevelButton3   filterNearest:false wrapClamp:true];        

    textures[kTexture_EpisodePriceTag] = [textures[kTexture_BankPanel] retain];

    [self initTexture:@"Episode1.png"       withKey:kTexture_Episode1       filterNearest:false wrapClamp:true];
    [self initTexture:@"Episode2.png"       withKey:kTexture_Episode2       filterNearest:false wrapClamp:true];
    [self initTexture:@"Episode3.png"       withKey:kTexture_Episode3       filterNearest:false wrapClamp:true];    

    [self initTexture:@"Episode1Background.png" withKey:kTexture_Episode1Background   filterNearest:false wrapClamp:true];
    textures[kTexture_Episode2Background] = [textures[kTexture_Episode1Background] retain];
    textures[kTexture_Episode3Background] = [textures[kTexture_Episode1Background] retain];
    
    [self initTexture:@"Facebook.png"       withKey:kTexture_Facebook       filterNearest:false wrapClamp:true];    
    
    [self initTexture:@"GameTitle.png"          withKey:kTexture_GameTitle          filterNearest:false wrapClamp:true];    
    [self initTexture:@"TitleBackground.png"    withKey:kTexture_TitleBackground    filterNearest:false wrapClamp:true];        
}

- (void)initGameTextures {
    [self clearTextureCategory:kUICategory];

    sTextureLoadCategory = kGameCategory;
    [self initTexture:@"NextButton.png"     withKey:kTexture_NextButton     filterNearest:false wrapClamp:true];
    [self initTexture:@"RetryButton.png"    withKey:kTexture_RetryButton    filterNearest:false wrapClamp:true];
    [self initTexture:@"MenuButton.png"     withKey:kTexture_MenuButton     filterNearest:false wrapClamp:true];              
    [self initTexture:@"PauseButton0.png"   withKey:kTexture_PauseButton0   filterNearest:false wrapClamp:true];
    [self initTexture:@"PauseButton1.png"   withKey:kTexture_PauseButton1   filterNearest:false wrapClamp:true];
    [self initTexture:@"PauseButton2.png"   withKey:kTexture_PauseButton2 	filterNearest:false wrapClamp:true];
    [self initTexture:@"GamePanel.png"      withKey:kTexture_GamePanel      filterNearest:true wrapClamp:true];            
  
    [self initTexture:@"Clouds.png"         withKey:kTexture_Clouds         filterNearest:false wrapClamp:true];        
    
    [self initTexture:@"CandyPileBG.png"    withKey:kTexture_CandyPileBG    filterNearest:false wrapClamp:true];
    [self initTexture:@"CandyPileFG.png"    withKey:kTexture_CandyPileFG    filterNearest:false wrapClamp:true];    
    [self initTexture:@"CandyPileSmall.png" withKey:kTexture_CandyPileSmall filterNearest:false wrapClamp:true];    
    
    [self initTexture:@"Pinata.png"         withKey:kTexture_Pinata         filterNearest:false wrapClamp:false];
    [self initTexture:@"GreenPinata.png"    withKey:kTexture_GreenPinata    filterNearest:false wrapClamp:false];
    
    [self initTexture:@"StrongPinata2.png"  withKey:kTexture_StrongPinata2  filterNearest:false wrapClamp:true];
    [self initTexture:@"StrongPinata3.png"  withKey:kTexture_StrongPinata3  filterNearest:false wrapClamp:true];

    [self initTexture:@"GreenStrongPinata1.png"  withKey:kTexture_GreenStrongPinata1  filterNearest:false wrapClamp:true];
    textures[kTexture_GreenStrongPinata2] = [textures[kTexture_GreenStrongPinata1] retain];
    textures[kTexture_GreenStrongPinata3] = [textures[kTexture_GreenStrongPinata1] retain];    

    [self initTexture:@"GreenWeakPinata.png" withKey:kTexture_GreenWeakCandyPinata filterNearest:false wrapClamp:true];            

    [self initTexture:@"PinataEater1.png"   withKey:kTexture_PinataEater1   filterNearest:false wrapClamp:true];
    [self initTexture:@"PinataEater2.png"   withKey:kTexture_PinataEater2   filterNearest:false wrapClamp:true];
    [self initTexture:@"PinataEater3.png"   withKey:kTexture_PinataEater3   filterNearest:false wrapClamp:true];

    [self initTexture:@"MotherPileEater1.png"  withKey:kTexture_MotherPileEater1 filterNearest:false wrapClamp:true];
    textures[kTexture_MotherPileEater2] = [textures[kTexture_MotherPileEater1] retain];
    textures[kTexture_MotherPileEater3] = [textures[kTexture_MotherPileEater1] retain];
    textures[kTexture_MotherPileEater4] = [textures[kTexture_MotherPileEater1] retain];        
    
    [self initTexture:@"BreakableHealthy.png"  withKey:kTexture_BreakableVegetablePinata filterNearest:false wrapClamp:true];
    [self initTexture:@"BreakableHealthyGlow.png"  withKey:kTexture_BreakableVegetablePinataGlow filterNearest:false wrapClamp:true];    
    [self initTexture:@"PileEater.png"      withKey:kTexture_PileEater      filterNearest:false wrapClamp:true];
    [self initTexture:@"UFO1.png"           withKey:kTexture_UFO1           filterNearest:false wrapClamp:true];    
    [self initTexture:@"UFO2.png"           withKey:kTexture_UFO2           filterNearest:false wrapClamp:true];    
    [self initTexture:@"UFO3.png"           withKey:kTexture_UFO3           filterNearest:false wrapClamp:true];    
    [self initTexture:@"UFO4.png"           withKey:kTexture_UFO4           filterNearest:false wrapClamp:true];                
    [self initTexture:@"Fairy1.png"         withKey:kTexture_Fairy1         filterNearest:false wrapClamp:true];    
    [self initTexture:@"Fairy2.png"         withKey:kTexture_Fairy2         filterNearest:false wrapClamp:true];    
    [self initTexture:@"BadGremlin.png"     withKey:kTexture_BadGremlin     filterNearest:false wrapClamp:true];            
    [self initTexture:@"PinheadSpiked.png"  withKey:kTexture_PinheadSpiked  filterNearest:false wrapClamp:true];    
    [self initTexture:@"Treasure.png"       withKey:kTexture_Treasure       filterNearest:false wrapClamp:true];        
    [self initTexture:@"Osmos.png"          withKey:kTexture_Osmos          filterNearest:false wrapClamp:true];                    
    [self initTexture:@"Chameleon.png"      withKey:kTexture_Chameleon      filterNearest:false wrapClamp:true];                        
    [self initTexture:@"Dog.png"            withKey:kTexture_Dog            filterNearest:false wrapClamp:true];                        
    [self initTexture:@"Cat.png"            withKey:kTexture_Cat            filterNearest:false wrapClamp:true];                        
    [self initTexture:@"GoodGrower.png"     withKey:kTexture_GoodGrower     filterNearest:false wrapClamp:true];                        
    [self initTexture:@"BadGrower.png"      withKey:kTexture_BadGrower      filterNearest:false wrapClamp:true];                            
            
    [self initTexture:@"Vegetable.png"      withKey:kTexture_Vegetable      filterNearest:false wrapClamp:false];    
    [self initTexture:@"TimeIcon.png"       withKey:kTexture_TimeIcon       filterNearest:false wrapClamp:true];
    
    [self initTexture:@"Kid1a.png"          withKey:kTexture_Kid1a          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid1b.png"          withKey:kTexture_Kid1b          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid2.png"           withKey:kTexture_Kid2           filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid2a.png"          withKey:kTexture_Kid2a          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid2b.png"          withKey:kTexture_Kid2b          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid2c.png"          withKey:kTexture_Kid2c          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid2d.png"          withKey:kTexture_Kid2d          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid2e.png"          withKey:kTexture_Kid2e          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid3.png"           withKey:kTexture_Kid3           filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid3a.png"          withKey:kTexture_Kid3a          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid3b.png"          withKey:kTexture_Kid3b          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid3c.png"          withKey:kTexture_Kid3c          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid3d.png"          withKey:kTexture_Kid3d          filterNearest:false wrapClamp:true];
    // kid4 is always loaded for loading screen
    [self initTexture:@"Kid_ex.png"         withKey:kTexture_KidEx          filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid_ex1.png"        withKey:kTexture_KidEx1         filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid_ex2.png"        withKey:kTexture_KidEx2         filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid_ex3.png"        withKey:kTexture_KidEx3         filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid_ex4.png"        withKey:kTexture_KidEx4         filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid_ex5.png"        withKey:kTexture_KidEx5         filterNearest:false wrapClamp:true];
    [self initTexture:@"Kid_ex6.png"        withKey:kTexture_KidEx6         filterNearest:false wrapClamp:true];
              
    [self initTexture:@"Mist.png"           withKey:kTexture_Mist                   filterNearest:false wrapClamp:true];
    [self initTexture:@"BombPowerup.png"    withKey:kTexture_BombPowerup    filterNearest:false wrapClamp:true];
    [self initTexture:@"SlowMotionPowerup.png"  withKey:kTexture_SlowMotionPowerup filterNearest:false wrapClamp:true];
    
    // reuse pinata textures
    textures[kTexture_CandyPowerup]     = [textures[kTexture_CandyPileSmall] retain];
    textures[kTexture_NegativePowerup]  = [textures[kTexture_BreakableVegetablePinata] retain];
    
    [self initTexture:@"ShrinkPowerup.png"      withKey:kTexture_ShrinkPowerup      filterNearest:false wrapClamp:true];
    [self initTexture:@"Box.png"                withKey:kTexture_PinataBox          filterNearest:false wrapClamp:true];
    [self initTexture:@"Bungee.png"             withKey:kTexture_Bungee             filterNearest:false wrapClamp:false];     
    [self initTexture:@"PullCordHandle.png"     withKey:kTexture_PullCordHandle     filterNearest:false wrapClamp:false];     
       
    [self initTexture:@"BatTool.png"            withKey:kTexture_BatTool        filterNearest:false wrapClamp:true];                     
    [self initTexture:@"BazookaTool.png"        withKey:kTexture_BazookaTool    filterNearest:false wrapClamp:true];
    [self initTexture:@"LaserTool.png"          withKey:kTexture_AutoFireTool   filterNearest:false wrapClamp:true];
    
    [self initTexture:@"SuperBatTool.png"       withKey:kTexture_SuperBatTool   filterNearest:false wrapClamp:true];    
    [self initTexture:@"Spike.png"              withKey:kTexture_Spike          filterNearest:false wrapClamp:true];
        
    [self initTexture:@"LargeExplosion1.png"     withKey:kTexture_LargeExplosion1        filterNearest:true wrapClamp:true];                         
    [self initTexture:@"LargeExplosion2.png"     withKey:kTexture_LargeExplosion2        filterNearest:true wrapClamp:true];                         
    [self initTexture:@"LargeExplosion3.png"     withKey:kTexture_LargeExplosion3        filterNearest:true wrapClamp:true];                         
    [self initTexture:@"LargeExplosion4.png"     withKey:kTexture_LargeExplosion4        filterNearest:true wrapClamp:true];                         
    [self initTexture:@"LargeExplosion5.png"     withKey:kTexture_LargeExplosion5        filterNearest:true wrapClamp:true];                         
    [self initTexture:@"LargeExplosion6.png"     withKey:kTexture_LargeExplosion6        filterNearest:true wrapClamp:true];                         
    [self initTexture:@"LargeExplosion7.png"     withKey:kTexture_LargeExplosion7        filterNearest:true wrapClamp:true];                         

    [self initTexture:@"SmallExplosion1.png"     withKey:kTexture_SmallExplosion1        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"SmallExplosion2.png"     withKey:kTexture_SmallExplosion2        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"SmallExplosion3.png"     withKey:kTexture_SmallExplosion3        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"SmallExplosion4.png"     withKey:kTexture_SmallExplosion4        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"SmallExplosion5.png"     withKey:kTexture_SmallExplosion5        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"SmallExplosion6.png"     withKey:kTexture_SmallExplosion6        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"SmallExplosion7.png"     withKey:kTexture_SmallExplosion7        filterNearest:false wrapClamp:true];                         

    [self initTexture:@"Sparkle1.png"     withKey:kTexture_Sparkle1        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"Sparkle2.png"     withKey:kTexture_Sparkle2        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"Sparkle3.png"     withKey:kTexture_Sparkle3        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"Sparkle4.png"     withKey:kTexture_Sparkle4        filterNearest:false wrapClamp:true];                                     
    [self initTexture:@"Sparkle5.png"     withKey:kTexture_Sparkle5        filterNearest:false wrapClamp:true];                         

    [self initTexture:@"TapMiss0.png"     withKey:kTexture_TapMiss1        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"TapMiss1.png"     withKey:kTexture_TapMiss2        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"TapMiss2.png"     withKey:kTexture_TapMiss3        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"TapMiss3.png"     withKey:kTexture_TapMiss4        filterNearest:false wrapClamp:true];                                     
    
    [self initTexture:@"Hit1.png"     withKey:kTexture_Hit1        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"Hit2.png"     withKey:kTexture_Hit2        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"Hit3.png"     withKey:kTexture_Hit3        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"Hit4.png"     withKey:kTexture_Hit4        filterNearest:false wrapClamp:true];                                     
    [self initTexture:@"Hit5.png"     withKey:kTexture_Hit5        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"Hit6.png"     withKey:kTexture_Hit6        filterNearest:false wrapClamp:true];                         
    [self initTexture:@"Hit7.png"     withKey:kTexture_Hit7        filterNearest:false wrapClamp:true];                         
}

// Create an OpenGL ES 1.1 context
- (id)init
{
    if ((self = [super init]))
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

        if (!context || ![EAGLContext setCurrentContext:context])
        {
            [self release];
            return nil;
        }
            
        // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
        glGenFramebuffersOES(1, &defaultFramebuffer);
        glGenRenderbuffersOES(1, &colorRenderbuffer);
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
    }
    
    [self resetTextures];
    [self initCommonTextures];
    [self initUITextures];

    return self;
}

- (void)render:(Game*)game 
        afterTimeElapsed:(float)timeElapsed 
        withParticleManager:(ParticleManager*)particleManager 
        andScreen:(Screen*)screen
        andFilter:(ImageControl*)filter
        andPopupElements:(NSMutableArray*)popupElements {

    // This application only creates a single context which is already set current at this point.
    // This call is redundant, but needed if dealing with multiple contexts.
    [EAGLContext setCurrentContext:context];

    // This application only creates a single default framebuffer which is already bound at this point.
    // This call is redundant, but needed if dealing with multiple framebuffers.
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    
    glClientActiveTexture(GL_TEXTURE0);
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);    
        
    glViewport(0, 0, backingWidth, backingHeight);  
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    glOrthof(0.0f,backingWidth, 0.0f,backingHeight, -0.01f,1.0f);
    
    glMatrixMode(GL_MODELVIEW);
          
    [game render:timeElapsed];
    [particleManager renderParticles:timeElapsed inLayer:kLayer_Game];
    [screen render:timeElapsed];
    [particleManager renderParticles:timeElapsed inLayer:kLayer_UI];
    
    if (filter.color.alpha > 0.0f) {
        [filter render:timeElapsed];
    }
    
    for (ScreenControl* control in popupElements) {
        if (control.color.alpha > 0.0f) {           
            [control render:timeElapsed];
        }
    }
    
    {
        static float t = 0.0f;
        t += timeElapsed;
        sShadowOffset = Vector2DMake(7.5f*cosf(1.0f*t),7.5f*sinf(0.25f*t));
    }
        
    // This application only creates a single color renderbuffer which is already bound at this point.
    // This call is redundant, but needed if dealing with multiple renderbuffers.
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	
    // Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        #ifdef DEBUG_BUILD            
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        #endif
        return NO;
    }

    return YES;
}

- (void)dealloc
{
    for (int t = 0; t < kTexture_Count; ++t) {
        [textures[t] release];
    }

    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffersOES(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        glDeleteRenderbuffersOES(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }

    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    
    [super dealloc];
}

@end
