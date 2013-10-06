//
//  LevelEndScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/25/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "LevelEndScreen.h"
#import "Achievement.h"
#import "BankComponent.h"
#import "CrystalSession+PullTab.h"
#import "EAGLView.h"
#import "FacebookWrapper.h"
#import "Game.h"
#import "GameCommon.h"
#import "LevelLoader.h"
#import "Localize.h"
#import "MetagameManager.h"
#import "ModalControl.h"
#import "Particles.h"
#import "SaveGame.h"
#import "Sounds.h"
#import "Tool.h"

#ifdef DO_ANALYTICS
    #import "FlurryAPI.h"
#endif    


#define LEVEL_END_COUNT_DURATION 2.0f


//////////////////////////////////////////

@interface AchievementModal : ModalControl //<FBDialogDelegate>
{
    NSString* description;
    TextControl* text;
    ImageControl* icon;    
}
-(id)initWithDescription:(NSString*)description andImage:(NSString*)image;
-(void)postAchievementAction:(ButtonControl*)control;
@end

@implementation AchievementModal
-(id)initWithDescription:(NSString*)desc andImage:(NSString*)image {
    if (self == [super init]) {
        // add title
        
        description = desc;
        [description retain];
        
        Vector2D panelDimensions = GetImageDimensions(kTexture_ModalPanel);     
        Vector2D center = Vector2DMul(GetGLDimensions(), 0.5f);   
                            
        icon = [[ImageControl alloc] 
            initAt:Vector2DMake(center.x-0.35f*panelDimensions.x,center.y) withTexture:GetTextureId(image)];
        icon.hasShadow = false;
        icon.jiggling = true;
        [icon setFade:kFade_In];
        [icon bounce];
        [self addChild:icon];
        
        ButtonControl* facebookButton = [[ButtonControl alloc] 
            initAt:Vector2DMake(center.x,center.y-0.35f*panelDimensions.y) 
            withTexture:kTexture_Facebook
            andText:kLocalizedString_Null];
        facebookButton.hasShadow = false;
        [facebookButton setResponder:self andSelector:@selector(postAchievementAction:)];
        [facebookButton setFade:kFade_In];
        [facebookButton bounce];
        [self addChild:facebookButton];
        [facebookButton release];
        
        text = [[TextControl alloc] 
            initAt: Vector2DMake(center.x+32.0f, center.y-16.0f)
            withString:description
            andDimensions:Vector2DMake(panelDimensions.x*0.7f,96.0f) 
            andAlignment:UITextAlignmentLeft 
            andFontName:DEFAULT_FONT andFontSize:24];
        text.hasShadow = false;
        text.jiggling = true;
        [text setFade:kFade_In];
        [text bounce];
        [self addChild:text]; 
        
        TextControl* title = [[TextControl alloc] 
            initAt:Vector2DMake(center.x,center.y+0.25f*panelDimensions.y)
            withText:kLocalizedString_Achievement
            andArg:nil
            andDimensions:Vector2DMake(220.0f,128.0f) 
            andAlignment:UITextAlignmentCenter 
            andFontName:DEFAULT_FONT 
            andFontSize:36];
        title.hasShadow = false;
        title.jiggling = true;
        title.tilting = true;
        [title setFade:kFade_In];
        [title bounce];
        [self addChild:title];
        [title release];       
    }
    return self;
}

-(void)setDescription:(NSString*)desc andImage:(NSString*)image {
    [description release];
    description = [desc retain];
    
    Vector2D panelDimensions = GetImageDimensions(kTexture_ModalPanel);         
    Vector2D center = Vector2DMul(GetGLDimensions(), 0.5f);   
        
    [text   resetTo:Vector2DMake(center.x+32.0f, center.y-16.0f)
            withString:description
            andDimensions:Vector2DMake(panelDimensions.x*0.7f,96.0f) 
            andAlignment:UITextAlignmentLeft 
            andFontName:DEFAULT_FONT andFontSize:24];
            
    icon.texture = GetTextureId(image);
}

-(void)dealloc {
    [text release];
    [icon release];
    [description release];
    [super dealloc];
}

-(void)postAchievementAction:(ButtonControl*)control {
#ifdef DO_ANALYTICS
    [FlurryAPI logEvent:@"POST_ACHIEVEMENT"];
#endif    
//    eLocalizedString localized = LocalizeTextArgs(kLocalizedString_FB_Achievement, description);
//    [FacebookWrapper publishToFacebook:localized andImagePath:GetWebPath(@"Icon.png") andDelegate:self];
}

@end



//////////////////////////////////////////

@interface LevelEndScreen()
-(void)bankAction:(ButtonControl*)control;
-(void)continueAction:(ButtonControl*)control;
-(void)menuAction:(ButtonControl*)control;
-(void)retryAction:(ButtonControl*)control;
-(void)achievementClosedAction:(ButtonControl*)control;
-(void)updateParticles:(float)timeElapsed;
-(void)showCurrentMetricCount;
-(void)showControls;
-(void)nextAchievementDialog;
-(void)initMetricControls;
@end

@implementation LevelEndScreen

-(void)bankAction:(ButtonControl *)control {
    bankTip.visible = true;
}

-(void)continueAction:(ButtonControl *)control {
    [game nextLevel];
}

-(void)menuAction:(ButtonControl *)control {
    [PARTICLE_MANAGER clear];
    [flowManager changeFlowState:kFlowState_LevelSelection]; 
}

-(void)retryAction:(ButtonControl *)control {
    [game retryLevel];
}

-(void)achievementClosedAction:(ButtonControl*)control {    
    [self nextAchievementDialog];
}

-(id)initWithFlowManager:(id<FlowManager>)fm andGame:(Game*)g {
    if (self == [super initWithFlowManager:fm]) {
        game = g;
        currentMetricCount = 0;
        metricCounterT = 0.0f;
        achievementModal = nil;
        currentAchievementIndex = 0;
        
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:Vector2DMul(GetGLDimensions(), 0.5f) withTexture:kTexture_GamePanel];
        bgImage.jiggling = true;      
        [bgImage bounce];
        [self addControl:bgImage]; 
        [bgImage release];
        bgImage = nil;           
        
        int startCash = METAGAME_MANAGER.money;
        medalCash = [game getMedalCash];
        medal = [game getMedalEarned];
        
        {
            [METAGAME_MANAGER addMoney:medalCash];
            [game awardMedal];
        }        

        Vector2D pos = Vector2DMake(0.5f*GetGLWidth(), 436.0f);

       static eLocalizedString medalMessage[kAchievement_Gold-kAchievement_Bronze+1] = {
            kLocalizedString_BronzeWon,
            kLocalizedString_SilverWon,
            kLocalizedString_GoldWon,
        };
        
        TextControl* victoryText = [[TextControl alloc] 
            initAt: pos
            withText:medalMessage[medal-kAchievement_Bronze]
            andArg:nil
            andDimensions:Vector2DMake(256.0f,50.0f) 
            andAlignment:UITextAlignmentCenter 
            andFontName:DEFAULT_FONT andFontSize:48];
        victoryText.tilting = true;
        victoryText.hasShadow = true;
        victoryText.jiggling = true;
        victoryText.autoShadow = false;
        [victoryText setFade:kFade_In];
        [victoryText bounce:1.0f];
        
        [self initMetricControls];
        
        {
            pos.y = 150.0f;
            bank = [[BankComponent alloc] 
                        initAt:pos 
                        withAmount:startCash];
            [bank setResponder:self andSelector:@selector(bankAction:)];
        }
        
        pos.y -= 80.0f;        
        
        if (game.level+1 < [LevelLoader getNumLevelsInEpisode:game.episodePath]) {
            continueButton = [[ButtonControl alloc] 
                initAt:Vector2DMake(240.0f,pos.y) withTexture:kTexture_NextButton andString:nil];
            [continueButton setResponder:self andSelector:@selector(continueAction:)];                
        }
        else {
            pos.y += 32.0f;
            episodeEndText = [[TextControl alloc] 
                initAt: pos
                withString:@"Episode Complete!"
                andDimensions:Vector2DMake(256.0f,34.0f) 
                andAlignment:UITextAlignmentCenter 
                andFontName:DEFAULT_FONT andFontSize:32];
            episodeEndText.hasShadow = false;
            episodeEndText.jiggling = true;
            
            pos.y = IsDeviceIPad() ? (pos.y-48.0f) : (pos.y-64.0f);
        }       
        
        {      
            pos.x = (continueButton) ? 160.0f : 240.0f;
            retryButton = [[ButtonControl alloc] 
                initAt:pos withTexture:kTexture_RetryButton andString:nil];
            [retryButton setResponder:self andSelector:@selector(retryAction:)];
        }
         
        {
            pos.x = 80.0f;        
            menuButton = [[ButtonControl alloc] 
                initAt:pos withTexture:kTexture_MenuButton andString:nil];
            [menuButton setResponder:self andSelector:@selector(menuAction:)];
       }
        
        [self showCurrentMetricCount];
        [self showControls];

        [self addControl:victoryText];
        [victoryText release];
        victoryText = nil;   
        
        if (!IsDeviceIPad()) {
            [CrystalSession activateCrystalPullTabOnLeaderboardsFromScreenEdge:@"bottom"];        
        }
    }
    return self;    
}

-(void)dealloc {
    if (!IsDeviceIPad()) {    
        [CrystalSession deactivateCrystalPullTab];
    }
    
    [SaveGame saveMetagame:METAGAME_MANAGER andUpdateCrystal:true];

    [achievements release];
    [bank release];
    [bankTip release];
    [metricCounter release];
    [episodeEndText release];
    [continueButton release];
    [retryButton release];
    [menuButton release];
    [achievementModal release];
    [super dealloc];
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    [self updateParticles:timeElapsed];
}

-(void)initMetricControls {

    int metricValues[3];
    metricValues[0] = game.gameLevel.rule.gold;
    metricValues[1] = game.gameLevel.rule.silver;
    metricValues[2] = game.gameLevel.rule.bronze;
    
    // todo localize
    NSString* labels[] = {
        @"Gold",
        @"Silver",
        @"Bronze"
    };
    
    float startPosition = 50.0f;    
    float metricSpace = 50.0f;    
    Vector2D position = Vector2DMake(startPosition,GetGLHeight()-170.0f);
    
//    {    
//        ImageControl* highlightPanel = [[ImageControl alloc] 
//            initAt:Vector2DMake(0.5f*GetGLWidth(),position.y) withTexture:kTexture_GamePopup];
//        [highlightPanel setColor:COLOR3D_GREEN];
//        highlightPanel.jiggling = true;
//        highlightPanel.hasShadow = false;
//        highlightPanel.baseScale = 0.7f; 
//        [highlightPanel setFade:kFade_In]; 
//        [highlightPanel bounce];
//        [self addControl:highlightPanel]; 
//        [highlightPanel release];
//        highlightPanel = nil;             
//    }
    
    
    for (int i = 0; i < 3; ++i) { 
        Boolean pulsing = (kAchievement_Gold-medal == i);
          
        ImageControl* medalImage = [[ImageControl alloc] 
            initAt:Vector2DMake(position.x,position.y-10.0f)
            withTexture:(kTexture_LevelGold-i)];
        medalImage.hasShadow = true;
        medalImage.tilting = true;
        medalImage.jiggling = true;
        medalImage.baseScale = 0.75f;
        medalImage.pulsing = pulsing;        
        [medalImage setFade:kFade_In];
        [medalImage bounce];
        [self addControl:medalImage];
        [medalImage release];

        position.x += 85.0f;

        TextControl* medalText = [[TextControl alloc] 
            initAt: position
            withString:labels[i]
            andDimensions:Vector2DMake(0.35f*GetGLWidth(),36.0) 
            andAlignment:UITextAlignmentLeft 
            andFontName:DEFAULT_FONT andFontSize:36];
        medalText.hasShadow = false;
        medalText.jiggling = true;
        medalText.pulsing = pulsing;        
        [medalText setColor:COLOR3D_WHITE];
        [medalText setFade:kFade_In];
        [medalText bounce];
        [self addControl:medalText];
        [medalText release];

        Vector2D metricTextDimensions;
        NSString* displayMetricValue = nil;
        
        if (game.gameLevel.rule.metric==kGameRule_Shots) {
            position.x += 130.0f;        
            metricTextDimensions = Vector2DMake(0.5f*GetGLWidth(), 24.0f);
            displayMetricValue = [NSString stringWithFormat:@"%d", metricValues[i]];
        }
        else {
            position.x += 130.0f;
            metricTextDimensions = Vector2DMake(0.25f*GetGLWidth(), 24.0f);            
            displayMetricValue = GetGameTimeFormat(metricValues[2]-metricValues[i], true);            
        }

        TextControl* metricText = [[TextControl alloc] 
            initAt: Vector2DMake(position.x, position.y-5.0f)
            withString:displayMetricValue
            andDimensions:metricTextDimensions 
            andAlignment:UITextAlignmentLeft
            andFontName:DEFAULT_FONT andFontSize:24];
        metricText.hasShadow = false;
        metricText.jiggling = true;
        metricText.pulsing = pulsing;         
        [metricText setColor:COLOR3D_WHITE];
        [metricText setFade:kFade_In];
        [metricText bounce];
        [self addControl:metricText];
        [metricText release];

        position.x = startPosition;
        position.y -= metricSpace;
    }
}

-(void)showControls {
    [bank setFade:kFade_In];            
    [bank adjustAmountBy:medalCash];        
    [self addControl:bank]; 
    
    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_Money)];

    if (continueButton) {
        [continueButton setFade:kFade_In];
        [continueButton bounce];
        [self addControl:continueButton];
    } else if (episodeEndText) {
        [episodeEndText setFade:kFade_In];
        [episodeEndText bounce];
        [self addControl:episodeEndText];
    }
    
    [retryButton setFade:kFade_In];
    [retryButton bounce];            
    [self addControl:retryButton];

    [menuButton setFade:kFade_In];            
    [menuButton bounce];
    [self addControl:menuButton];
    
    ImageControl* bankImage = [[ImageControl alloc] initAt:ZeroVector() withTexture:kTexture_BankPanel];
    NSArray* imageControls = [NSArray arrayWithObject:bankImage];
    bankTip = [ModalControl createModalWithMessage:kLocalizedString_BankInfo 
                                andArg:nil 
                                andImages:imageControls];    
    [self addControl:bankTip];
    [bankImage release];
  
    
//    [self nextAchievementDialog];
}

-(void)nextAchievementDialog {
    if (!achievements) {
        achievements = [METAGAME_MANAGER getNewAchievements];
    }
    
    if (currentAchievementIndex < achievements.count) {
        Achievement* achievement = [achievements objectAtIndex:currentAchievementIndex];
        
        if (!achievementModal) {
            achievementModal = 
                [[AchievementModal alloc] initWithDescription:achievement.description andImage:achievement.imageName];
            [achievementModal setCloseResponder:self andSelector:@selector(achievementClosedAction:)];                
            [self addControl:achievementModal];
        }
        else {
            [achievementModal setDescription:achievement.description andImage:achievement.imageName];
            [achievementModal bounce];

        }
        achievementModal.visible = true;        
        ++currentAchievementIndex;
    }
    else {
        for (Achievement* achievement in achievements) {
            achievement.newAchievement = false;
        }
        
        achievementModal.visible = false;        
    }
}
    
-(void)showCurrentMetricCount {
    if (metricCounter) {
        [self removeControl:metricCounter];
        [metricCounter release];
        metricCounter = nil;
    }
    
    Vector2D screenDimensions = GetGLDimensions();
        
    int timeCount = MAX(game.gameLevel.rule.bronze-[game gameTime],0);
    Vector2D timeDimensions = GetImageDimensions(kTexture_TimeIcon);    
    Vector2D position = Vector2DMake(0.5f*screenDimensions.x+timeDimensions.x/2+10.0f, screenDimensions.y-110.0f);
    
    ImageControl* timeIcon = [[ImageControl alloc] 
        initAt:Vector2DMake(position.x-timeDimensions.x-5.0f,position.y) 
        withTexture:kTexture_TimeIcon];
    timeIcon.hasShadow = true;
    timeIcon.tilting = true;
    [self addControl:timeIcon];
    [timeIcon release];
    
    NSString* metricString = GetGameTimeFormat(timeCount, false);
    
    metricCounter = [[TextControl alloc] 
        initAt:position 
        withString:metricString
        andDimensions:Vector2DMake(64.0f,32.0f) 
        andAlignment:UITextAlignmentLeft 
        andFontName:DEFAULT_FONT 
        andFontSize:32];
    metricCounter.hasShadow = false;
    [self addControl:metricCounter];
}

-(void)updateParticles:(float)timeElapsed {
    if (![flowManager changingFlowState]) {
        static float timeForNextCandy = 0.0f;
        timeForNextCandy -= timeElapsed;
        if (timeForNextCandy <= 0.0f) {
            timeForNextCandy = 0.2f;
        
            Particle* p = [PARTICLE_MANAGER
                                NewParticleAt:Vector2DMake(GetGLWidth()*rand()/(float)RAND_MAX,GetGLHeight()+32.0f)
                                    andVelocity:Vector2DMake(0.0f,-150.0f) 
                                    andAngle:TWO_PI*random()/RAND_MAX 
                                    andScaleX:CANDY_MAX_SIZE 
                                    andScaleY:CANDY_MAX_SIZE 
                                    andColor:COLOR3D_WHITE
                                    andTotalLifetime:2.0f 
                                    andType:kParticleType_Candy
                                    andTexture:kTexture_CandyBegin+rand()%(kTexture_CandyEnd-kTexture_CandyBegin)]; 
            p.layer = kLayer_UI;
            [PARTICLE_MANAGER addParticle:p];
            [p release];
        }
    }
}

@end

