//
//  LevelSelectionScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/15/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "LevelSelectionScreen.h"
#import "BankComponent.h"
#import "CrystalSession.h"
#import "DebugActions.h"
#import "EAGLView.h"
#import "GameCommon.h"
#import "GameLevel.h"
#import "LevelLoader.h"
#import "MetagameManager.h"
#import "ModalControl.h"
#import "Particles.h"
#import "SaveGame.h"
#import "Tool.h"

#ifdef DO_ANALYTICS
    #import "FlurryAPI.h"
#endif

#define LEVEL_SPAWN_SPEED 0.0625f

////////////////////////////////////////////

@interface LevelButton : ButtonControl {
    NSString* levelPath;
    ImageControl* lockImage;
    ImageControl* medalImage;
    ImageControl* priceTag;
    TextControl* price;
    int levelIndex;
}
@property (nonatomic,copy) NSString* levelPath;
@property (nonatomic) int levelIndex;
@property (nonatomic,assign) ImageControl* priceTag;
@property (nonatomic,assign) ImageControl* lockImage;
@property (nonatomic,assign) TextControl* price;
-(id)initAt:(Vector2D)pos 
    withAchievement:(eAchievement)achievement 
    withPreviousAchievement:(eAchievement)prevoiusAchievement 
    withPath:(NSString*)path 
    withIndex:(int)index
    withEpisode:(int)episode;
@end

@implementation LevelButton
@synthesize levelPath, levelIndex, lockImage, priceTag, price;
-(id)initAt:(Vector2D)pos 
    withAchievement:(eAchievement)achievement 
    withPreviousAchievement:(eAchievement)previousAchievement
    withPath:(NSString*)path
    withIndex:(int)index
    withEpisode:(int)episode {
    NSString* levelString = [NSString stringWithFormat:@"%d", index+1];
    
    eTexture buttonTexture = kTexture_LevelButton1 + MIN(episode,NUM_EPISODES-1);
    if (self == [super initAt:pos withTexture:buttonTexture andText:levelString]) {        
        levelPath = path;
        levelIndex = index;
        medalImage = nil;
        lockImage = nil;
        priceTag = nil;
        price = nil;
        
        if (achievement==kAchievement_Locked) {
            lockImage = [[ImageControl alloc] 
                initAt:ZeroVector() withTexture:kTexture_LevelLock];
            lockImage.hasShadow = false;
            lockImage.tilting = true;
            [self addChild:lockImage];         
        
            // previous level was unlocked
            if (previousAchievement==kAchievement_Unlocked) {
                Vector2D pricePosition = Vector2DMake(0.0f,-32.0f);
                priceTag = [[ImageControl alloc] 
                    initAt:pricePosition
                    withTexture:kTexture_LevelPriceTag];
                priceTag.hasShadow = false;
                [self addChild:priceTag]; 
                
                price = [[TextControl alloc] 
                    initAt:pricePosition 
                    withString:[NSString stringWithFormat:@"%d", LEVEL_PURCHASE_PRICE]
                    andDimensions:Vector2DMake(64.0f,22.0f) 
                    andAlignment:UITextAlignmentCenter 
                    andFontName:DEFAULT_FONT andFontSize:22];
                price.hasShadow = false;
                price.color = COLOR3D_BLACK;
                [self addChild:price];
            }        
        }
        else if (achievement >= kAchievement_Bronze) {
            medalImage = [[ImageControl alloc] 
                initAt:Vector2DMake(0.0f,-40.0f)
                withTexture:(kTexture_LevelBronze+achievement-kAchievement_Bronze)];
            medalImage.hasShadow = true;
            medalImage.tilting = true;
            [self addChild:medalImage]; 
        }   
        
        [self setPosition:pos];
    }
    return self;
}
-(void)dealloc {
    [price release];
    [priceTag release];
    [lockImage release];
    [medalImage release];
    [super dealloc];
}
@end

////////////////////////////////////////////

@interface LevelSelectionScreen()
-(void)initLevelButtons;
-(void)playAction:(ButtonControl*)control;
-(void)backAction:(ButtonControl*)control;
-(void)bankAction:(ButtonControl*)control;
-(void)purchaseLevelAction:(ButtonControl*)control;
-(void)giftMoneyOption:(ButtonControl*)control;
-(void)giftMoneyAction:(ButtonControl*)control;
-(void)crystalPlayerInfoUpdatedWithSuccess:(BOOL)success;
@end

@implementation LevelSelectionScreen

-(void)purchaseLevelAction:(ButtonControl*)control {
    if (lastLevelButtonPressed) {
#ifdef DO_ANALYTICS
    [FlurryAPI logEvent:@"LEVEL_BOUGHT"];
#endif    
        
        [lastLevelButtonPressed.lockImage setFade:kFade_Out];
        
        [lastLevelButtonPressed.priceTag    setFade:kFade_Out];
        [lastLevelButtonPressed.price       setFade:kFade_Out];        
        
        [lastLevelButtonPressed.lockImage release]; lastLevelButtonPressed.lockImage = nil;
        [lastLevelButtonPressed.priceTag release];  lastLevelButtonPressed.priceTag = nil;
        [lastLevelButtonPressed.price   release];  lastLevelButtonPressed.price = nil;        
        
        [bank adjustAmountBy:-LEVEL_PURCHASE_PRICE];
        
        GameLevel* lvl = [LevelLoader getLevel:lastLevelButtonPressed.levelIndex inEpisode:episodePath];
        lvl.achievement = kAchievement_Unlocked;
        [SaveGame saveLevelState:lvl];
        
        [METAGAME_MANAGER spendMoney:LEVEL_PURCHASE_PRICE];
        [SaveGame saveMetagame:METAGAME_MANAGER andUpdateCrystal:false];
        
        purchaseOffer.visible = false;
    }    
}

-(void)playAction:(ButtonControl*)control {    
    LevelButton* levelButton = (LevelButton*)control;
    lastLevelButtonPressed = levelButton;

    if (levelButton.priceTag && DEBUG_ACTIONS.useLocks) {
        if (purchaseOffer) {
            [self removeControl:purchaseOffer];
            [purchaseOffer release];
            purchaseOffer = nil;
        }
        
        if (METAGAME_MANAGER.money >= LEVEL_PURCHASE_PRICE) {                  
            ButtonControl* purchaseButton = [[ButtonControl alloc] 
                initAt:ZeroVector() withTexture:kTexture_BuyButton andString:nil];
            [purchaseButton setPressSound:kSound_Money];
            [purchaseButton setResponder:self andSelector:@selector(purchaseLevelAction:)];
            purchaseButton.tilting = true;

            // already retained
            purchaseOffer = [ModalControl createModalWithMessage:kLocalizedString_LevelCanPurchaseInfo 
                            andArg:[NSNumber numberWithInt:LEVEL_PURCHASE_PRICE]
                            andButton:purchaseButton];
            [purchaseButton release];
        }
        else {
            ImageControl* bankImage = [[ImageControl alloc] initAt:ZeroVector() withTexture:kTexture_BankPanel];
            NSArray* imageControls = [NSArray arrayWithObject:bankImage];
            purchaseOffer = [ModalControl createModalWithMessage:kLocalizedString_LevelCannotPurchaseInfo 
                                        andArg:[NSNumber numberWithInt:LEVEL_PURCHASE_PRICE] 
                                        andImages:imageControls];    
            [self addControl:bankTip];
            [bankImage release];
        }
        
        
        [self addControl:purchaseOffer];  

        purchaseOffer.visible = true;        
    }
    else if (!(levelButton.lockImage && DEBUG_ACTIONS.useLocks)) {
        [flowManager changeFlowState:kFlowState_Pregame];
        [flowManager setLevel:levelButton.levelIndex];
    }
}

-(void)backAction:(ButtonControl *)control {
    [flowManager changeFlowState:kFlowState_EpisodeSelection];
}

-(void)bankAction:(ButtonControl *)control {
    bankTip.visible = true;
}

-(id)initWithFlowManager:(id<FlowManager>) fm andEpisodePath:(NSString*)path {
    if (self == [super initWithFlowManager:fm]) {
        episodePath = path;
        
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:Vector2DMul(GetGLDimensions(), 0.5f) 
            withTexture:kTexture_Episode1Background+MIN(((EAGLView*)fm).episodeIndex,NUM_EPISODES-1)];
        [self addControl:bgImage]; 
        [bgImage bounce];
        bgImage.jiggling = true;  
        bgImage.alphaEnabled = false;      
        [bgImage release];
        bgImage = nil;           
        
        Vector2D center = Vector2DMul(GetGLDimensions(),0.5f);
//        Vector2D titleTextPos = Vector2DMake(center.x, 430.0f);
//        TextControl* titleText = [[TextControl alloc] 
//            initAt:titleTextPos 
//            withText:kLocalizedString_LevelSelection
//            andArg:nil
//            andDimensions:Vector2DMake(256.0f,64.0f) 
//            andAlignment:UITextAlignmentCenter 
//            andFontName:DEFAULT_FONT andFontSize:32];
//        titleText.hasShadow = true;
//        titleText.tilting = true;
//        titleText.jiggling = true;
//        [titleText setColor:Color3DMake(0.0f, 0.0f, 0.0f, 1.0f)];
//        [titleText setShadowColor:Color3DMake(0.0f, 0.0f, 0.0f, 0.2f)];
//        [titleText shadowScale:1.03f];
//        [titleText bounce:1.0f];
//        [self addControl:titleText];  
//        [titleText release];
//        titleText = nil;        
        
        Vector2D backPosition = Vector2DMake(35.0f,440.0f);
        
        ButtonControl* backButton = [[ButtonControl alloc] 
            initAt:backPosition withTexture:kTexture_BackButton andText:kLocalizedString_Null];
        [backButton setResponder:self andSelector:@selector(backAction:)];
        backButton.tilting = false;
        [self addControl:backButton];
        [backButton release];
        backButton = nil;
        
        [self initLevelButtons];
        
        bank = [[BankComponent alloc] 
                    initAt:Vector2DMake(center.x,430.0f) 
                    withAmount:METAGAME_MANAGER.money];
        [bank setResponder:self andSelector:@selector(bankAction:)];
        [self addControl:bank];
        
        // already retained
        ImageControl* bankImage = [[ImageControl alloc] initAt:ZeroVector() withTexture:kTexture_BankPanel];
        NSArray* imageControls = [NSArray arrayWithObject:bankImage];
        bankTip = [ModalControl createModalWithMessage:kLocalizedString_BankInfo 
                                    andArg:nil 
                                    andImages:imageControls];    
        [self addControl:bankTip];
        [bankImage release];
        
        
        if (![METAGAME_MANAGER wasItemGifted:MONEY_20_GIFT_ID]) {                
            moneyGiftButton = [[ButtonControl alloc] 
                               initAt:         Vector2DMake(280.0f,430.0f)
                               withTexture:    kTexture_Gift 
                               andString:      nil];                 
            [moneyGiftButton setResponder:self andSelector:@selector(giftMoneyOption:)];
            moneyGiftButton.pulsing = true;
            moneyGiftButton.tilting = true;
            [self addControl:moneyGiftButton];
        }
        else if (!METAGAME_MANAGER.giftMoneyAwarded) {
            [METAGAME_MANAGER awardMoneyGift];        
            [SaveGame saveMetagame:METAGAME_MANAGER andUpdateCrystal:false];
            [bank adjustAmountBy:MONEY_GIFT_AMOUNT];                        
        }
        
        [CrystalPlayer sharedInstance].delegate = self;         
        
        totalTimeElapsed = 0.0f;
        currentLevelIndex = -1;
    }
    return self;
}

-(void)crystalPlayerInfoUpdatedWithSuccess:(BOOL)success {
    if ([METAGAME_MANAGER wasItemGifted:MONEY_20_GIFT_ID]) {
        [METAGAME_MANAGER awardMoneyGift];        
        [SaveGame saveMetagame:METAGAME_MANAGER andUpdateCrystal:false];
        [bank adjustAmountBy:MONEY_GIFT_AMOUNT];        
        
        moneyGiftButton.pulsing = false;
        [moneyGiftButton setFade:kFade_Out];            
    }
}        

-(void)giftMoneyOption:(ButtonControl*)control {
    if (purchaseOffer) {
        [self removeControl:purchaseOffer];
        [purchaseOffer release];
        purchaseOffer = nil;
    }
    
    ButtonControl* giftButton = [[ButtonControl alloc] 
                                 initAt:         ZeroVector() 
                                 withTexture:    kTexture_Gift 
                                 andString:      nil];                 
    [giftButton setResponder:self andSelector:@selector(giftMoneyAction:)];
    
    purchaseOffer = [ModalControl 
                     createModalWithMessage: @"Give away candy\nto three friends...\n\nand get 20 candies\n\nFREE!" 
                     andArg:                 nil
                     andButton:              giftButton];
    giftButton.tilting = true;                
    [giftButton release];  
    
    [self addControl:purchaseOffer];   
    purchaseOffer.visible = true; 
}

-(void)giftMoneyAction:(ButtonControl *)control {
    purchaseOffer.visible = false;
    [CrystalSession activateCrystalUIAtGifting];   
    if (!IsDeviceIPad()) {
        [[SimpleAudioEngine sharedEngine] pauseBackgroundMusic];
    }        
}

-(void)initLevelButtons {    
    Vector2D buttonDimensions = GetImageDimensions(kTexture_LevelButton1);
    Vector2D screenDimensions = GetGLDimensions();
    
    int rows = 4;        
    float ySpace = (screenDimensions.y+40.0f-(rows*buttonDimensions.y))/(float)(rows+1);
    float y = screenDimensions.y-150.0f;

    int cols = 4;
    float xSpace = (screenDimensions.x-(cols*buttonDimensions.x))/(float)(cols+1);    
    float x = xSpace+0.5f*buttonDimensions.x;
        
    int numLevels = [LevelLoader getNumLevelsInEpisode:episodePath];
    eAchievement previousAchievement = kAchievement_Unlocked;
    
    levelButtons = [[NSMutableArray alloc] initWithCapacity:numLevels];
    
    for (int i = 0; i < numLevels; ++i) {     
        GameLevel* level = [LevelLoader getLevel:i inEpisode:episodePath];
        Vector2D position = Vector2DMake(x,y) ;
        LevelButton* button = [[LevelButton alloc] initAt:position
                                                    withAchievement:level.achievement 
                                                    withPreviousAchievement:previousAchievement
                                                    withPath:level.uniqueID
                                                    withIndex:i
                                                    withEpisode:((EAGLView*)flowManager).episodeIndex ];
        [button setResponder:self andSelector:@selector(playAction:)];
        [button setFade:kFade_In];
        [button setFadeDelay:LEVEL_SPAWN_SPEED*i];
        [self addControl:button];
        [levelButtons addObject:button];
        [button release];
        button = nil;

        previousAchievement = level.achievement;
        
        x += xSpace+buttonDimensions.x;
        if ((i+1)%cols == 0) {
//            if (numLevels-(i+1) < cols) {
//                cols = numLevels-(i+1);
//                xSpace = (screenDimensions.x-(cols*buttonDimensions.x))/(float)(cols+1);     
//            }
            x = xSpace+0.5f*buttonDimensions.x;
            y -= ySpace+buttonDimensions.y;
        } 
    }    
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    totalTimeElapsed += timeElapsed;
    int index = (int)(totalTimeElapsed / LEVEL_SPAWN_SPEED - 0.2f);
    if (index != currentLevelIndex && index < levelButtons.count) {
        ButtonControl* levelButton = [levelButtons objectAtIndex:index];
        [PARTICLE_MANAGER createSmokePuffAt:levelButton.position withScale:1.25f withLayer:kLayer_UI];
        currentLevelIndex = index;
    }
}

-(void)dealloc {
    [PARTICLE_MANAGER clear];
    
    [CrystalPlayer sharedInstance].delegate = nil;       
    [CrystalSession deactivateCrystalUI];        

    [moneyGiftButton release];
    [levelButtons release];
    [bank release];
    [bankTip release];
    [purchaseOffer release];
    [super dealloc];
}

@end
