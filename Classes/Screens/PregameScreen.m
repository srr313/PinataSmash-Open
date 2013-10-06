//
//  PregameScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/17/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import "PregameScreen.h"
#import "BankComponent.h"
#import "CrystalSession.h"
#import "DebugActions.h"
#import "EAGLView.h"
#import "FlowManager.h"
#import "Game.h"
#import "GameCommon.h"
#import "MetagameManager.h"
#import "ModalControl.h"
#import "SaveGame.h"
#import "Tool.h"

#ifdef DO_ANALYTICS
    #import "FlurryAPI.h"
#endif

@interface ToolButton : ButtonControl {
    eTool tool;
    eAchievement    achievement;
    ImageControl*   giftImage;
    ImageControl*   priceTag;
    TextControl* 	price;    
}
@property (nonatomic) eTool tool;
@property (nonatomic) eAchievement achievement;
@property (nonatomic,assign) ImageControl* priceTag;
@property (nonatomic,assign) ImageControl* giftImage;
@property (nonatomic,assign) TextControl* price;
-(id)initAt:(Vector2D)pos withTool:(eTool)t andAchievement:(eAchievement)a;
@end

@implementation ToolButton
@synthesize tool, achievement, priceTag, giftImage, price;
-(id)initAt:(Vector2D)pos withTool:(eTool)t andAchievement:(eAchievement)a {

    if (self == [super initAt:pos withTexture:[Tool getTexture:t] andText:kLocalizedString_Null]) {        
        tool        = t;
        achievement = a;
        giftImage   = nil;
        priceTag    = nil;
        price       = nil;
        
        if (achievement==kAchievement_Locked) {   
            Boolean purchasable = ([Tool getPrice:tool] < INT_MAX);
            
            if (purchasable) { 
                Vector2D pricePosition = Vector2DMake(0.0f,-32.0f);
                priceTag = [[ImageControl alloc] 
                            initAt:pricePosition
                            withTexture:kTexture_LevelPriceTag];
                priceTag.hasShadow = false;
                [self addChild:priceTag];     
                
                int cost = [Tool getPrice:tool];
                
                price = [[TextControl alloc] 
                         initAt:pricePosition 
                         withString:[NSString stringWithFormat:@"%d", cost]
                         andDimensions:Vector2DMake(64.0f,22.0f) 
                         andAlignment:UITextAlignmentCenter 
                         andFontName:DEFAULT_FONT 
                         andFontSize:22];
                price.hasShadow = false;
                price.color = COLOR3D_BLACK;
                [self addChild:price];                 
            }
            else {                
                if (![METAGAME_MANAGER wasItemGifted:SUPER_BAT_GIFT_ID]) {
                    giftImage = [[ImageControl alloc] 
                                 initAt:Vector2DMake(0.0f,-32.0f) 
                                 withTexture:kTexture_Gift];
                    giftImage.baseScale = 0.75f;
                    giftImage.hasShadow = true;
                    giftImage.tilting = true;
                    [self addChild:giftImage];                 
                }            
            }
        }        
        [self setPosition:pos];
    }
    return self;
}
-(void)dealloc {
    [price      release];
    [priceTag   release];
    [giftImage 	release];
    [super dealloc];
}
@end

////////////////////////////////////////////

@interface PregameScreen()
-(void)initToolButtons;
-(void)initMetricControls;
-(void)playAction:(ButtonControl *)owner;
-(void)menuAction:(ButtonControl *)owner;
-(void)toolAction:(ButtonControl *)owner;
-(void)purchaseToolAction:(ButtonControl *)owner;
-(void)giftToolAction:(ButtonControl *)owner;
-(void)bankAction:(ButtonControl *)control;
-(void)setSelectedTool:(ToolButton*)toolButton;
-(void)crystalPlayerInfoUpdatedWithSuccess:(BOOL)success;
@end

@implementation PregameScreen

-(void)toolAction:(ButtonControl*)control {
    ToolButton* toolButton = (ToolButton*)control;
    lastToolButtonPressed = toolButton;
    
    if (toolButton.priceTag && DEBUG_ACTIONS.useLocks) {
        if (purchaseOffer) {
            [self removeControl:purchaseOffer];
            [purchaseOffer release];
            purchaseOffer = nil;
        }
        
        int price = [Tool getPrice:toolButton.tool];
        if (METAGAME_MANAGER.money >= price) {                  
            ButtonControl* purchaseButton = [[ButtonControl alloc] 
                initAt:ZeroVector() withTexture:kTexture_BuyButton andString:nil];
            [purchaseButton setPressSound:kSound_Money];                
            [purchaseButton setResponder:self andSelector:@selector(purchaseToolAction:)];

            // already retained
            purchaseOffer = [ModalControl createModalWithMessage:kLocalizedString_ToolCanPurchaseInfo 
                            andArg:[NSNumber numberWithInt:price]
                            andButton:purchaseButton];
            purchaseButton.tilting = true;
            [purchaseButton release];
        }
        else {
            ImageControl* bankImage = [[ImageControl alloc] initAt:ZeroVector() withTexture:kTexture_BankPanel];
            NSArray* imageControls = [NSArray arrayWithObject:bankImage];
            purchaseOffer = [ModalControl createModalWithMessage:kLocalizedString_ToolCannotPurchaseInfo 
                                        andArg:[NSNumber numberWithInt:price] 
                                        andImages:imageControls];    
            [self addControl:bankTip];
            [bankImage release];            
        }
        
        [self addControl:purchaseOffer];   
    
        purchaseOffer.visible = true;        
    }
    else if (toolButton.giftImage && DEBUG_ACTIONS.useLocks) {
        if (purchaseOffer) {
            [self removeControl:purchaseOffer];
            [purchaseOffer release];
            purchaseOffer = nil;
        }
        
        ButtonControl* giftButton = [[ButtonControl alloc] 
                                        initAt:         ZeroVector() 
                                        withTexture:    kTexture_Gift 
                                        andString:      nil];                 
        [giftButton setResponder:self andSelector:@selector(giftToolAction:)];
        
        purchaseOffer = [ModalControl 
                            createModalWithMessage: @"Give away\nthe Spiked Club\nto three friends...\n\nand get yours\n\nFREE!" 
                            andArg:                 nil
                            andButton:              giftButton];
        giftButton.tilting = true;                
        [giftButton release];  
        
        [self addControl:purchaseOffer];   
        purchaseOffer.visible = true;                
    }
    else if (!(toolButton.giftImage || toolButton.priceTag) || !DEBUG_ACTIONS.useLocks) {
        [self setSelectedTool:toolButton];
    }
}

-(void)setSelectedTool:(ToolButton*)toolButton {    
    for (ToolButton* button in toolButtons) {
        button.pulsing = false;
        button.baseAlpha = 1.0f;
        button.baseScale = 1.0f;
    }

    [flowManager setTool:toolButton.tool];
    toolButton.pulsing = true;
    toolButton.baseScale = 1.25f;    
}

-(void)giftToolAction:(ButtonControl *)owner {
    if (lastToolButtonPressed) {        
        purchaseOffer.visible = false;
        [CrystalSession activateCrystalUIAtGifting];   
        if (!IsDeviceIPad()) {
            [[SimpleAudioEngine sharedEngine] pauseBackgroundMusic];
        }            
    }    
}

-(void)purchaseToolAction:(ButtonControl*)control {
    if (lastToolButtonPressed) {
        #ifdef DO_ANALYTICS
            [FlurryAPI logEvent:[NSString stringWithFormat:@"TOOL_BOUGHT:%d", lastToolButtonPressed.tool]];
        #endif
    
        
        [lastToolButtonPressed.priceTag setFade:kFade_Out];
        [lastToolButtonPressed.price    setFade:kFade_Out];        
        
        [lastToolButtonPressed.priceTag release];  
        lastToolButtonPressed.priceTag = nil;
        
        [lastToolButtonPressed.price release];  
        lastToolButtonPressed.price = nil;        
        
        int price = [Tool getPrice:lastToolButtonPressed.tool];

        [bank adjustAmountBy:-price];

        [METAGAME_MANAGER unlockTool:lastToolButtonPressed.tool];
        [METAGAME_MANAGER spendMoney:price];
        [SaveGame saveMetagame:METAGAME_MANAGER andUpdateCrystal:false];
        
        purchaseOffer.visible = false;
        
        [self setSelectedTool:lastToolButtonPressed];
    }
}

-(void)playAction:(ButtonControl *)owner {
    [flowManager changeFlowState:kFlowState_Game];
}

-(void)menuAction:(ButtonControl*)owner {
    [flowManager changeFlowState:kFlowState_LevelSelection];
}

-(void)bankAction:(ButtonControl *)control {
    bankTip.visible = true;
}

-(void)crystalPlayerInfoUpdatedWithSuccess:(BOOL)success {    
    if ([METAGAME_MANAGER wasItemGifted:SUPER_BAT_GIFT_ID]) {
        ToolButton* toolButton = [toolButtons objectAtIndex:kTool_SuperBat];            
        [toolButton.giftImage setFade:kFade_Out];            
        [toolButton.giftImage release];  
        toolButton.giftImage = nil;
    }
}        

-(id)initWithFlowManager:(id<FlowManager>)fm andGame:(Game*)g {
    if (self == [super initWithFlowManager:fm]) {
                
        game = g;
    
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:Vector2DMul(GetGLDimensions(), 0.5f) withTexture:kTexture_GamePanel];
        bgImage.jiggling = true;
        [bgImage bounce];
        [self addControl:bgImage]; 
        [bgImage release];
        bgImage = nil;     
    
        int fontSize = ([game.gameLevel.title length]>11)?28:36;
    
        Vector2D center = Vector2DMul(GetGLDimensions(), 0.5f);
        Vector2D levelPosition = Vector2DMake(center.x, 420.0f);
        TextControl* levelText = [[TextControl alloc] 
            initAt: levelPosition
            withText:game.gameLevel.title
            andArg:nil
            andDimensions:Vector2DMake(GetGLWidth(),80.0f) 
            andAlignment:UITextAlignmentCenter 
            andFontName:DEFAULT_FONT andFontSize:fontSize];
        levelText.tilting = true;
        levelText.hasShadow = true;
        levelText.jiggling = true;
        [levelText shadowScale:1.03f];
        [levelText setFade:kFade_In];
        [levelText bounce:1.0f];
        [self addControl:levelText];
        [levelText release];
        levelText = nil;
        
        [self initMetricControls];
        
        float menuX = IsDeviceIPad() ? 60.0f : 40.0f; 
        ButtonControl* menuButton = [[ButtonControl alloc] 
            initAt:Vector2DMake(menuX, 50.0f)
            withTexture:kTexture_MenuButton 
            andString:nil];
        [menuButton setResponder:self andSelector:@selector(menuAction:)];
        [menuButton setFade:kFade_In];
        [menuButton bounce];
        menuButton.hasShadow = false;
        [self addControl:menuButton];
        [menuButton release];
        menuButton = nil;         
                
        float playX = IsDeviceIPad() ? 188.0f : 194.0f;                 
        ButtonControl* playButton = [[ButtonControl alloc] 
            initAt:Vector2DMake(playX, 50.0f)
            withTexture:kTexture_PlayButton 
            andString:nil];
        [playButton setResponder:self andSelector:@selector(playAction:)];
        [playButton setFade:kFade_In];
        [playButton bounce];
        playButton.hasShadow = false;
        [self addControl:playButton];
        [playButton release];
        playButton = nil;
        
        bank = [[BankComponent alloc] 
                    initAt:Vector2DMake(center.x,210.0f) 
                    withAmount:METAGAME_MANAGER.money];
        [bank setResponder:self andSelector:@selector(bankAction:)];
        [self addControl:bank];
        
        // fit between to address layering issues
        [self initToolButtons];
        
        ImageControl* bankImage = [[ImageControl alloc] initAt:ZeroVector() withTexture:kTexture_BankPanel];
        NSArray* imageControls = [NSArray arrayWithObject:bankImage];
        bankTip = [ModalControl createModalWithMessage:kLocalizedString_BankInfo 
                                    andArg:nil 
                                    andImages:imageControls];    
        [self addControl:bankTip];
        [bankImage release];
                
        if (game.gameLevel.displayCurrencyTip) {
            bankTip.visible = true;
        }
        
        [CrystalPlayer sharedInstance].delegate = self;        
    }
    return self;    
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
        
    Vector2D position = Vector2DMake(startPosition,GetGLHeight()-110.0f);
    for (int i = 0; i < 3; ++i) {
        ImageControl* medalImage = [[ImageControl alloc] 
            initAt:Vector2DMake(position.x,position.y-10.0f)
            withTexture:(kTexture_LevelGold-i)];
        medalImage.hasShadow = true;
        medalImage.tilting = true;
        medalImage.jiggling = true;
        medalImage.baseScale = 0.75f;
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
        [metricText setColor:COLOR3D_WHITE];
        [metricText setFade:kFade_In];
        [metricText bounce];
        [self addControl:metricText];
        [metricText release];

        position.x = startPosition;
        position.y -= 50.0f;
    }
}

-(void)initToolButtons {    
    Vector2D buttonDimensions = GetImageDimensions(kTexture_LevelButton1);
    Vector2D screenDimensions = GetGLDimensions();
    float xSpace = (screenDimensions.x-(kTool_Count*buttonDimensions.x))/(float)(kTool_Count+1);    
    float x = xSpace+0.5f*buttonDimensions.x;        
    float y = 140.0f;
    
    // background
//    ImageControl* toolPanel = [[ImageControl alloc] 
//        initAt:Vector2DMake(0.5f*GetGLWidth(),y) withTexture:kTexture_GamePopup];
//    toolPanel.jiggling = true;
//    toolPanel.hasShadow = false;
//    toolPanel.baseScale = 0.9f; 
//    [toolPanel setFade:kFade_In]; 
//    [toolPanel bounce];
//    [self addControl:toolPanel]; 
//    [toolPanel release];
//    toolPanel = nil; 
    
    toolButtons = [[NSMutableArray alloc] init];

    for (int i = 0; i < kTool_Count; ++i) { 
        Vector2D position = Vector2DMake(x,y);
        eTool tool = (eTool)i;
        eAchievement achievement = ([METAGAME_MANAGER isToolLocked:tool]) ? kAchievement_Locked : kAchievement_Unlocked;
        ToolButton* button = [[ToolButton alloc] initAt:position
                                withTool:tool
                                andAchievement:achievement]; 
        [button setResponder:self andSelector:@selector(toolAction:)];

        button.pulseRate = 6.0f;
        button.jiggling = true;
        button.hasShadow = true; 
        [button bounce];

        [self addControl:button];
        [toolButtons addObject:button];

        [button release];
        button = nil;

        x += xSpace+buttonDimensions.x;
    } 
        
    ToolButton* currentTool = [toolButtons objectAtIndex:((EAGLView*)flowManager).tool];    
    [self setSelectedTool:currentTool];
}

-(void)dealloc {
    [CrystalPlayer sharedInstance].delegate = nil;        
    [CrystalSession deactivateCrystalUI];        
    
    [toolButtons release];
    [purchaseOffer release];
    [bankTip release];
    [bank release];
    [super dealloc];
}

@end
