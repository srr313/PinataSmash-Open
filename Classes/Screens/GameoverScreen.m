//
//  GameoverScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/21/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "GameoverScreen.h"
#import "EAGLView.h"
#import "Game.h"
#import "GameCommon.h"
#import "Localize.h"
#import "MetagameManager.h"
#import "ModalControl.h"
#import "SaveGame.h"

@interface GameoverScreen()
-(void)playAgainAction:(ButtonControl*)owner;
-(void)menuAction:(ButtonControl*)owner;
-(void)purchaseAction:(ButtonControl*)owner;
@end

@implementation GameoverScreen

-(id)initWithFlowManager:(id<FlowManager>)fm andGame:(Game*)g {
    if (self == [super initWithFlowManager:fm]) {
        game = g;
        
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:Vector2DMul(GetGLDimensions(), 0.5f) withTexture:kTexture_GamePanel];
        [bgImage bounce];
        bgImage.jiggling = true; 
        bgImage.baseAlpha= 0.75f;       
        [self addControl:bgImage]; 
        [bgImage release];
        bgImage = nil;     
    
        Vector2D pos = Vector2DMul(GetGLDimensions(), 0.5f);
        pos.y = 400.0f;
        TextControl* gameoverText = [[TextControl alloc] 
            initAt: pos
            withText:kLocalizedString_Gameover
            andArg:nil
            andDimensions:Vector2DMake(256.0f,72.0f) 
            andAlignment:UITextAlignmentCenter 
            andFontName:DEFAULT_FONT andFontSize:72];
        gameoverText.tilting = true;
        gameoverText.jiggling = true;
        gameoverText.hasShadow = true;
        [gameoverText setFade:kFade_In];
        [gameoverText bounce:1.0f];
        [self addControl:gameoverText];
        [gameoverText release];
        gameoverText = nil;
        
        NSString* levelEndReason = nil;
        if ([game levelEndReason]==kLevelEndReason_NoCandy) {
            levelEndReason = @"You ran out of candy!";
        } 
        else if ([game levelEndReason]==kLevelEndReason_NoHits) {
            levelEndReason = @"You ran out of shots!";            
        }
        else if ([game levelEndReason]==kLevelEndReason_NoTime) {
            levelEndReason = @"You ran out of time!";        
        }
        
        pos.y -= 120.0f;
        TextControl* reason = [[TextControl alloc] 
            initAt: pos
            withText:levelEndReason
            andArg:nil
            andDimensions:Vector2DMake(256.0f,96.0f) 
            andAlignment:UITextAlignmentCenter 
            andFontName:DEFAULT_FONT andFontSize:48];
        reason.hasShadow = false;
        [reason setFade:kFade_In];
        [reason setColor:COLOR3D_RED];
        [reason bounce:1.0f];
        [self addControl:reason];
        [reason release];
        reason = nil;
        
        pos.x = 240.0f;
        pos.y -= 100.0f;
        ButtonControl* retryButton = [[ButtonControl alloc] 
            initAt:pos withTexture:kTexture_RetryButton andString:nil];
        [retryButton setResponder:self andSelector:@selector(playAgainAction:)];
        [retryButton setFade:kFade_In];
        [retryButton bounce];
        [self addControl:retryButton];
        [retryButton release];
        retryButton = nil;
        
        pos.x = 80.0f;
        ButtonControl* menuButton = [[ButtonControl alloc] 
            initAt:pos withTexture:kTexture_MenuButton andString:nil];
        [menuButton setResponder:self andSelector:@selector(menuAction:)];
        [menuButton setFade:kFade_In];
        [menuButton bounce];
        [self addControl:menuButton];
        [menuButton release];
        menuButton = nil; 
        
        static NSString* sLastFail = nil;
        static int sTimesTried = 0;
        
        if (sLastFail && [sLastFail isEqualToString:game.gameLevel.uniqueID]) {         
            ++sTimesTried;
        }
        else {
            [sLastFail release];
            sLastFail = game.gameLevel.uniqueID; 
            [sLastFail retain];          
            sTimesTried = 1;
        }
        
        int nextLevelIndex = game.level+1;
        if (sTimesTried==2 && METAGAME_MANAGER.money >= LEVEL_PURCHASE_PRICE
            && nextLevelIndex < [LevelLoader getNumLevelsInEpisode:game.episodePath]
            && [LevelLoader getLevel:nextLevelIndex inEpisode:game.episodePath].achievement == kAchievement_Locked) {
            
            [sLastFail release];
            sLastFail = nil;
            sTimesTried = 0;
            
            ButtonControl* purchaseButton = [[ButtonControl alloc] 
                initAt:ZeroVector() withTexture:kTexture_BuyButton andString:nil];
            [purchaseButton setResponder:self andSelector:@selector(purchaseAction:)];

            // already retained
            purchaseModal = [ModalControl createModalWithMessage:kLocalizedString_BuyNextLevel 
                            andArg:[NSNumber numberWithInt:LEVEL_PURCHASE_PRICE]
                            andButton:purchaseButton];
            [self addControl:purchaseModal];
            [purchaseButton release];
            
            purchaseModal.visible = true;
        }
    }
    return self;    
}

-(void)dealloc {
    [purchaseModal release];
    [super dealloc];
}

-(void)playAgainAction:(ButtonControl*)owner {
    [flowManager changeFlowState:kFlowState_Pregame];     
}

-(void)menuAction:(ButtonControl*)owner {
    [flowManager changeFlowState:kFlowState_LevelSelection];
}

-(void)purchaseAction:(ButtonControl *)owner {    
    int nextLevelIndex = game.level+1;
    GameLevel* lvl = [LevelLoader getLevel:nextLevelIndex inEpisode:game.episodePath];
    lvl.achievement = kAchievement_Unlocked;
    [SaveGame saveLevelState:lvl];
    
    [METAGAME_MANAGER spendMoney:LEVEL_PURCHASE_PRICE];
    [SaveGame saveMetagame:METAGAME_MANAGER andUpdateCrystal:true];

    [game nextLevel];
}

@end
