//
//  TitleScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/21/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "TitleScreen.h"
#import "CrystalSession.h"
#import "DebugActions.h"
#import "FacebookWrapper.h"
#import "GameCommon.h"
#import "EAGLView.h"
#import "LevelEnvironment.h"
#import "MetagameManager.h"
#import "ModalControl.h"
#import "Particles.h"
#import "SaveGame.h"
#import "Sounds.h"

#define REDEEM_AMOUNT 50

typedef enum {
    kTitleCharacterState_Expanding = 0,
    kTitleCharacterState_Shrinking,
    kTitleCharacterState_Shaking,
    kTitleCharacterState_Hidden,
} eTitleCharacterState;

@interface TitleCharacter : ImageControl {
    eTitleCharacterState    state;
    float                   stateTime;
    Vector2D                motion;
    Vector2D                startPosition;
}
-(id)initAt:(Vector2D)pos withVector:(Vector2D)v withTexture:(eTexture)tex;
@end

@implementation TitleCharacter
-(id)initAt:(Vector2D)pos withVector:(Vector2D)v withTexture:(eTexture)tex {
    if (self == [super initAt:pos withTexture:tex]) {
        state       = kTitleCharacterState_Hidden;
        stateTime   = 0.0f;
        baseScale   = 0.0f;
        baseAlpha   = 0.0f;
        motion      = v;
        startPosition = pos;
        hasShadow   = true;
    }
    return self;
}
-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    stateTime += timeElapsed;
    if (state == kTitleCharacterState_Hidden) {
        if (stateTime > 1.5f) {
            state       = kTitleCharacterState_Expanding;
            stateTime   = 0.0f;
        }
    }
    else if (state == kTitleCharacterState_Expanding) {
        const float expansionSpeed = 3.0f;
        baseScale += expansionSpeed*timeElapsed;
        baseAlpha = baseScale;
        position  = Vector2DAdd(startPosition, Vector2DMul(motion, expansionSpeed*stateTime));
        if (baseScale >= 1.0f) {
            baseScale   = 1.0f;
            baseAlpha   = 1.0f;
            state       = kTitleCharacterState_Shaking;
            stateTime   = 0.0f;
        }
    }    
    else if (state == kTitleCharacterState_Shaking) {
        baseScale = 1.0f+0.05f*sinf(16.0f*stateTime);
        baseAlpha = baseScale;
        if (stateTime > 3.0f) {
            state       = kTitleCharacterState_Shrinking;
            stateTime   = 0.0f;
        }
    }
    else if (state == kTitleCharacterState_Shrinking) {
        const float shrinkingSpeed = 3.0f;      
        baseScale -= shrinkingSpeed*timeElapsed;
        baseAlpha = baseScale;
        position  = Vector2DAdd(position, Vector2DMul(motion, -shrinkingSpeed*timeElapsed));      
        if (baseScale <= 0.0f) {
            baseScale   = 0.0f;
            baseAlpha   = 0.0f;
            position    = startPosition;
            state       = kTitleCharacterState_Hidden;
            stateTime   = 0.0f;
        }
    }
}
@end

// todo enable rating for app in follow-up update!

@interface TitleScreen()
-(void)storyAction:(ButtonControl*)owner;
-(void)titleAction:(ButtonControl*)owner;
-(void)achievementsAction:(ButtonControl*)owner;
-(void)creditsAction:(ButtonControl*)owner;
//-(void)rateMeAction:(ButtonControl*)owner;
//-(void)rateMeNowAction:(ButtonControl *)owner;
//-(void)redeemAction:(ButtonControl*)owner;
//-(void)facebookConnectAction:(ButtonControl*)owner;
//-(void)postFacebook:(ButtonControl*)owner;
-(void)facebookAction:(ButtonControl*)owner;
//-(void)twitterAction:(ButtonControl*)owner;
-(void)cheatAction:(ButtonControl*)owner;
-(void)clearAction:(ButtonControl*)owner;
@end

@implementation TitleScreen

-(void)cheatAction:(ButtonControl*)owner {
    [owner setEnabled:false];
    DEBUG_ACTIONS.useLocks = false;
}

-(void)clearAction:(ButtonControl*)owner {
    [[NSUserDefaults standardUserDefaults] 
        setPersistentDomain:[NSDictionary dictionary] 
        forName:[[NSBundle mainBundle] bundleIdentifier]];
}

-(void)titleAction:(ButtonControl *)owner {
    [PARTICLE_MANAGER createCandyExplosionAt:owner.position withAmount:16 withLayer:kLayer_UI];
    [PARTICLE_MANAGER createConfettiAt:owner.position withAmount:12 withLayer:kLayer_UI];
}

-(void)storyAction:(ButtonControl*)owner {
    [flowManager changeFlowState:kFlowState_EpisodeSelection];
}

-(void)achievementsAction:(ButtonControl*)owner {
    if (IsDeviceIPad()) {
        achievementsButton.enabled = false;        
    }
    else {
        [[SimpleAudioEngine sharedEngine] pauseBackgroundMusic];
    }
    [CrystalSession activateCrystalUIAtProfile];    
}

-(void)creditsAction:(ButtonControl*)owner {
    [flowManager changeFlowState:kFlowState_Credits];
}

//-(void)rateMeAction:(ButtonControl*)owner {
//    rateMeModal.visible = true;
//}

//-(void)rateMeNowAction:(ButtonControl*)owner {
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:FACEBOOK_APP_URL]]; // todo launch rate url
//}


//-(void)redeemAction:(ButtonControl*)owner {
//    redeemModal.visible = true;
//}

//-(void)postFacebook:(ButtonControl*)owner {
////    [FacebookWrapper publishToFacebook:kLocalizedString_JustStartedPlaying andImagePath:GetWebPath(@"Icon.png") andDelegate:self];
//}

//-(void)facebookConnectAction:(ButtonControl*)owner {
////    [FacebookWrapper authorizeWithDelegate:self];
//}

-(void)facebookAction:(ButtonControl*)owner {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:FACEBOOK_APP_URL]];
}

//-(void)twitterAction:(ButtonControl*)owner {
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:TWITTER_APP_URL]];
//}

-(id)initWithFlowManager:(id<FlowManager>)fm {
    if (self == [super initWithFlowManager:fm]) {
        sceneEnvironment = [[LevelEnvironment alloc] initWithEnvironment:kLevelEnvironment_Title];
        sceneEnvironment.happyLevel     = 0.6f;
        sceneEnvironment.effectsEnabled = true;
                
        Vector2D screenDimensions = GetGLDimensions();
        Vector2D buttonPosition;
        buttonPosition.x = screenDimensions.x*0.5f;
        buttonPosition.y = screenDimensions.y-64.0f;
        
        ButtonControl* titleImage = [[ButtonControl alloc] 
            initAt:buttonPosition withTexture:kTexture_GameTitle andString:nil];
        titleImage.jiggling     = true;
        titleImage.tilting      = true;
        titleImage.hasShadow    = true;
        titleImage.autoShadow   = false;
        titleImage.jiggling     = true;
        [titleImage setPressSound:kSound_PinataSplit];
        [titleImage setResponder:self andSelector:@selector(titleAction:)];
        [titleImage setFade:kFade_In];
        [titleImage bounce:1.0f];
        [self addControl:titleImage];
        [titleImage release];
        titleImage = nil;   
        
        buttonPosition.y -= 140.0f;
        
        TitleCharacter* bear = [[TitleCharacter alloc] 
                               initAt:Vector2DAdd(buttonPosition, 
                                            Vector2DMake(-GetImageDimensions(kTexture_PlayButton).x/3,0.0f))
                               withVector:Vector2DMake(-16.0f,42.0f)
                               withTexture:kTexture_StrongPinata1 ];    
        bear.angle = 22.0f;
        [self addControl:bear];
        [bear release];
        
        TitleCharacter* kid = [[TitleCharacter alloc] 
                               initAt:buttonPosition
                               withVector:Vector2DMake(0.0f,75.0f)
                               withTexture:kTexture_Kid1 ];        
        [self addControl:kid];
        [kid release];

        TitleCharacter* donkey = [[TitleCharacter alloc] 
                                  initAt:Vector2DAdd(buttonPosition, 
                                                  Vector2DMake(GetImageDimensions(kTexture_PlayButton).x/3,0.0f))
                                  withVector:Vector2DMake(16.0f,32.0f)
                                  withTexture:kTexture_WeakCandyPinata];        
        [self addControl:donkey];
        [donkey release];        
        
        ButtonControl* storyButton = [[ButtonControl alloc] 
            initAt:buttonPosition withTexture:kTexture_PlayButton andString:nil];
        [storyButton setResponder:self andSelector:@selector(storyAction:)];
        [self addControl:storyButton];
        [storyButton release];
        storyButton.hasShadow = false;
        storyButton = nil;
        
        
                        
        buttonPosition.y -= 75.0f;
        
        TitleCharacter* monkey = [[TitleCharacter alloc] 
                                  initAt:Vector2DAdd(buttonPosition, 
                                                     Vector2DMake(-GetImageDimensions(kTexture_PlayButton).x/3,0.0f))
                                  withVector:Vector2DMake(-32.0f,0.0f)
                                  withTexture:kTexture_HeroPinata];
        monkey.angle = 33.0f;        
        [self addControl:monkey];
        [monkey release];                        
        
        achievementsButton = [[ButtonControl alloc] 
            initAt:buttonPosition withTexture:kTexture_AchievementButton andString:nil];
        [achievementsButton setResponder:self andSelector:@selector(achievementsAction:)];
        achievementsButton.hasShadow = false;
        [self addControl:achievementsButton];
        
        buttonPosition.y -= 75.0f;
        
        TitleCharacter* porcupine = [[TitleCharacter alloc] 
                                     initAt:Vector2DAdd(buttonPosition, 
                                                        Vector2DMake(GetImageDimensions(kTexture_PlayButton).x/3,0.0f))
                                     withVector:Vector2DMake(0.0f,-48.0f)
                                     withTexture:kTexture_Pinhead];        
        porcupine.angle = 180.0f;        
        [self addControl:porcupine];
        [porcupine release];                        
        
        ButtonControl* creditsButton = [[ButtonControl alloc] 
            initAt:buttonPosition withTexture:kTexture_CreditsButton andString:nil];
        [creditsButton setResponder:self andSelector:@selector(creditsAction:)];
        [self addControl:creditsButton];
        [creditsButton release];
        creditsButton.hasShadow = false;
        creditsButton = nil;

        #ifdef DEBUG_BUILD
            ButtonControl* cheatButton = [[ButtonControl alloc] 
                initAt:Vector2DMake(buttonPosition.x,buttonPosition.y-75.0f) 
                withTexture:kTexture_Button andString:@"D:UNLOCK"];
            [cheatButton setResponder:self andSelector:@selector(cheatAction:)];
            [cheatButton setColor:Color3DMake(0.0f, 0.0f, 1.0f, 1.0f)];
            [self addControl:cheatButton];
            [cheatButton release];
            cheatButton = nil;   
        
            ButtonControl* clearButton = [[ButtonControl alloc] 
                                          initAt:Vector2DMake(buttonPosition.x,buttonPosition.y-125.0f) 
                                          withTexture:kTexture_Button andString:@"D:CLEAR"];
            [clearButton setResponder:self andSelector:@selector(clearAction:)];
            [clearButton setColor:Color3DMake(0.0f, 0.0f, 1.0f, 1.0f)];
            [self addControl:clearButton];
            [clearButton release];
            clearButton = nil;           
        #endif
        
//        buttonPosition.y = 50.0f;
//        ButtonControl* fbConnectButton = [[ButtonControl alloc] 
//            initAt:buttonPosition withTexture:kTexture_FacebookConnect andText:kLocalizedString_Null];
//        [fbConnectButton setResponder:self andSelector:@selector(facebookConnectAction:)];
//        [self addControl:fbConnectButton];
//        [fbConnectButton release];
//        fbConnectButton = nil;
                      
        
        buttonPosition = Vector2DMake(36.0f,20.0f);
        TitleCharacter* gremlin = [[TitleCharacter alloc] 
                                  initAt:Vector2DAdd(buttonPosition, 
                                                     Vector2DMake(0.0f,GetImageDimensions(kTexture_Facebook).y/3))
                                  withVector:Vector2DMake(0.0f,20.0f)
                                  withTexture:kTexture_GoodGremlin];
        [self addControl:gremlin];
        [gremlin release];         
        
        ButtonControl* facebookButton = [[ButtonControl alloc] 
                                            initAt:     buttonPosition 
                                            withTexture:kTexture_Facebook 
                                            andText:    kLocalizedString_Null];
        facebookButton.hasShadow = false;
        [facebookButton setResponder:self andSelector:@selector(facebookAction:)];
        [self addControl:facebookButton];
        [facebookButton release];
        facebookButton = nil;
        
        TextControl* facebookText = [[TextControl alloc] 
                                  initAt:       Vector2DAdd(buttonPosition,
                                                            Vector2DMake(2.0f*GetImageDimensions(kTexture_Facebook).x
                                                                            +ToScreenScaleX(5.0f),0.0f))
                                  withString:   @"Like us!"
                                  andDimensions:Vector2DMake(100.0f,20.0) 
                                  andAlignment: UITextAlignmentLeft 
                                  andFontName:  DEFAULT_FONT 
                                  andFontSize:  18.0f];
        facebookText.hasShadow = false;
        facebookText.pulsing = true;        
        [facebookText setColor:COLOR3D_BLUE];
        [self addControl:facebookText];
        [facebookText release];        
        
//        buttonPosition.x += 128.0f;
//        ButtonControl* twitterButton = [[ButtonControl alloc] 
//            initAt:buttonPosition withTexture:kTexture_Twitter andText:kLocalizedString_Null];
//        [twitterButton setResponder:self andSelector:@selector(twitterAction:)];
//        [self addControl:twitterButton];
//        [twitterButton release];
//        twitterButton = nil;
                
//        ButtonControl* rateButton = [[ButtonControl alloc] 
//            initAt:ZeroVector() withTexture:kTexture_Button andString:@"Rate"];
//        [rateButton setResponder:self andSelector:@selector(rateMeNowAction:)];
//        [rateButton setColor:COLOR3D_BLUE];
//
//        rateMeModal = [ModalControl createModalWithMessage:
//                            @"We hope you are enjoying our game!  Please rate this game 5 stars so we can release free updates"
//                                "in the future.  Thank you."
//                        andArg:nil
//                        andButton:rateButton];
//        [self addControl:rateMeModal];
//        [rateMeModal retain];
//        [rateButton release];
            
        // only display facebook authorization on first launch
//        if ([fm previousFlowState] == kFlowState_Splash) {
//            if ( ![[NSUserDefaults standardUserDefaults] objectForKey:@"launchedBefore"] ) {
//                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"launchedBefore"];        
//                [[NSUserDefaults standardUserDefaults] synchronize];
//
//                ModalControl* fbMessage = [ModalControl 
//                                            createModalWithMessage:@"Welcome to Piñata Smash!  "
//                                                                    "Press \"Play\" to get started or "
//                                                                    "login with Facebook to share your achievements with friends!"
//                                            andArg:nil];
//                [self addControl:fbMessage];
//                fbMessage.visible = true;
//            }
//        }
    }
    return self;
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    [sceneEnvironment tick:timeElapsed];
}

-(void)render:(float)timeElapsed {
    [sceneEnvironment render:timeElapsed];
    [super render:timeElapsed];
}

//-(void)dialogDidComplete:(FBDialog *)dialog {
//    [METAGAME_MANAGER addMoney:REDEEM_AMOUNT];
//    [SaveGame saveMetagame:METAGAME_MANAGER];
//    rateMeModal.visible = false;
//}

-(void)crystalUiDeactivated {
    achievementsButton.enabled = true;
}

-(void)dealloc {
    [CrystalSession deactivateCrystalUI];    
    
    [achievementsButton release];
    [rateMeModal release];
    [sceneEnvironment release];
    [super dealloc];
}

@end
