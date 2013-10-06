//
//  EpisodeSelectionScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/19/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//
//

#import "EpisodeSelectionScreen.h"
#import "BankComponent.h"
#import "CrystalSession.h"
#import "DebugActions.h"
#import "EAGLView.h"
#import "GameCommon.h"
#import "GameLevel.h"
#import "LevelLoader.h"
#import "MetagameManager.h"
#import "ModalControl.h"
#import "SaveGame.h"
#import "ScrollComponent.h"

#ifdef DO_ANALYTICS
    #import "FlurryAPI.h"
#endif

static int sLastEpisodeHighlighted = 0;

@interface EpisodeData : NSObject
{
@public
    NSString* path;
    NSString* displayName;
    eTexture texture;
    eAchievement achievement;
    int cost;
}
@property (nonatomic,copy) NSString* path;
@property (nonatomic,copy) NSString* displayName;
@property (nonatomic) eAchievement achievement;
@property (nonatomic) eTexture texture;
@property (nonatomic) int cost;
@end

@implementation EpisodeData
@synthesize path, displayName, achievement, texture, cost;
-(void)dealloc {
    [path release];
    [displayName release];
    [super dealloc];
}
@end


//////////////////////////////////////////////

@interface EpisodeButton : ButtonControl {
    EpisodeData* data;
    ImageControl* lock;
    ButtonControl* priceTag;
    int index;
}
@property (nonatomic,assign) EpisodeData* data;
@property (nonatomic) int index;
-(id)initAt:(Vector2D)pos withData:(EpisodeData*)episodeData;
-(void)purchase;
@end

@implementation EpisodeButton
@synthesize data, index;

-(id)initAt:(Vector2D)pos withData:(EpisodeData*)episodeData {
    if (self == [super initAt:pos withTexture:episodeData.texture andText:kLocalizedString_Null]) {
        data = episodeData;
        [data retain];
        
        Vector2D center = Vector2DMake(0.0f,0.0f);
        Vector2D buttonDim = GetImageDimensions(data.texture);

        Vector2D popupDimensions = GetImageDimensions(kTexture_GamePopup);
        Vector2D popupPosition = Vector2DMake(
                                    center.x,
                                    center.y-0.5f*buttonDim.y-0.5f*popupDimensions.y);
        ImageControl* popupBackground = [[ImageControl alloc] 
            initAt:popupPosition 
            withTexture:kTexture_GamePopup]; 
//        [popupBackground setColor:COLOR3D_BLUE];
        popupBackground.hasShadow = true;
        popupBackground.baseScale = 0.6f;
        [self addChild:popupBackground];
        [popupBackground release];
        
        Vector2D textDimensions = Vector2DMul(popupDimensions, 0.4f);
        textDimensions.x *= 0.75f;
        TextControl* episodeText = [[TextControl alloc] 
                                    initAt:popupPosition
                                    withText:data.displayName 
                                    andArg:nil 
                                    andDimensions:textDimensions
                                    andAlignment:UITextAlignmentCenter 
                                    andFontName:DEFAULT_FONT 
                                    andFontSize:24];
        episodeText.hasShadow = false;
        episodeText.tilting = false;
        [episodeText setColor:Color3DMake(0.0f, 0.0f, 0.0f, 1.0f)];
        
        [self addChild:episodeText];
        [episodeText release];
                  
        if (data.achievement==kAchievement_Locked) {
            lock = [[ImageControl alloc] 
                initAt:center withTexture:kTexture_LevelLock];
            lock.hasShadow = true;
            lock.tilting = true;
            
            [self addChild:lock];
            
            priceTag = [[ButtonControl alloc] 
                initAt:Vector2DMake(center.x,center.y-144.0f)
                withTexture:kTexture_EpisodePriceTag
                andString:[NSString stringWithFormat:@"%d", data.cost]];
            [priceTag setResponder:self andSelector:@selector(enterAction:)];
            
            [self addChild:priceTag];
        }   
//        else {
//            NSMutableArray* medalCounts = [LevelLoader getNumAchievementsInEpisode:episodeData.path];
//            NSString* medals = [NSString stringWithFormat:@"%@G/%@S/%@B of %@", 
//                                    [medalCounts objectAtIndex:0],
//                                    [medalCounts objectAtIndex:1],
//                                    [medalCounts objectAtIndex:2],
//                                    [medalCounts objectAtIndex:3] ];
//            [medalCounts release];
//                                    
//            TextControl* medalsText = [[TextControl alloc] 
//                                        initAt:Vector2DMake(center.x,center.y)
//                                        withString:medals 
//                                        andDimensions:Vector2DMake(0.5f*GetGLWidth(),80.0f) 
//                                        andAlignment:UITextAlignmentCenter 
//                                        andFontName:DEFAULT_FONT 
//                                        andFontSize:18];
//            medalsText.hasShadow = false;
//            medalsText.tilting = false;
//            [medalsText setColor:Color3DMake(0.0f, 0.0f, 0.0f, 1.0f)];
//            
//            [self addChild:medalsText];
//            [medalsText release];
//        }     
    }
    return self;
}

-(void)purchase {
    [lock setFade:kFade_Out];
    priceTag.pulsing = false;
    [priceTag setFade:kFade_Out];
}

-(void)dealloc {
    [data release];
    [lock release];
    [priceTag release];
    [super dealloc];
}

@end

//////////////////////////////////////////////

@interface EpisodeSelectionScreen()
-(void)initEpisodes;
-(void)enterAction:(ButtonControl*)control;
-(void)backAction:(ButtonControl*)control;
-(void)bankAction:(ButtonControl*)control;
-(void)purchaseAction:(ButtonControl *)control;
-(void)giftMoneyOption:(ButtonControl*)control;
-(void)giftMoneyAction:(ButtonControl*)control;
-(void)crystalPlayerInfoUpdatedWithSuccess:(BOOL)success;
@end

@implementation EpisodeSelectionScreen

-(void)purchaseAction:(ButtonControl*)control {
    if (lastEpisodeButtonPressed) {    
#ifdef DO_ANALYTICS
    [FlurryAPI logEvent:[NSString stringWithFormat:@"EPISODE_BOUGHT:%d", lastEpisodeButtonPressed.data.path]];
#endif    
            
        [lastEpisodeButtonPressed purchase];
        
        lastEpisodeButtonPressed.data.achievement = kAchievement_Unlocked;
        
        [bank adjustAmountBy:-lastEpisodeButtonPressed.data.cost];
        
        [METAGAME_MANAGER spendMoney:lastEpisodeButtonPressed.data.cost];
        [SaveGame saveMetagame:METAGAME_MANAGER andUpdateCrystal:false];
        [SaveGame saveEpisodeState:kAchievement_Unlocked andName:lastEpisodeButtonPressed.data.path];
                
        purchaseOffer.visible = false;
    }    
}

-(void)enterAction:(ButtonControl*)control {
    EpisodeButton* episodeButton = (EpisodeButton*)control;
    lastEpisodeButtonPressed = episodeButton;
    
    if (episodeButton.data.achievement == kAchievement_Locked && DEBUG_ACTIONS.useLocks) {
        if (purchaseOffer) {
            [self removeControl:purchaseOffer];
            [purchaseOffer release];
            purchaseOffer = nil;
        }
        
        int episodePrice = episodeButton.data.cost;
        if (METAGAME_MANAGER.money >= episodePrice) {                  
            ButtonControl* purchaseButton = [[ButtonControl alloc] 
                initAt:ZeroVector() withTexture:kTexture_BuyButton andString:nil];
            [purchaseButton setPressSound:kSound_Money];
            [purchaseButton setResponder:self andSelector:@selector(purchaseAction:)];
            purchaseButton.tilting = true;

            purchaseOffer = [ModalControl createModalWithMessage:kLocalizedString_EpisodeCanPurchaseInfo 
                            andArg:[NSNumber numberWithInt:episodePrice]
                            andButton:purchaseButton];
            [purchaseButton release];
        }
        else {                            
            ImageControl* bankImage = [[ImageControl alloc] initAt:ZeroVector() withTexture:kTexture_BankPanel];
            NSArray* imageControls = [NSArray arrayWithObject:bankImage];
            purchaseOffer = [ModalControl createModalWithMessage:kLocalizedString_EpisodeCannotPurchaseInfo 
                                        andArg:[NSNumber numberWithInt:episodePrice] 
                                        andImages:imageControls];    
            [self addControl:bankTip];
            [bankImage release];                            
        }
        
        [self addControl:purchaseOffer];    
    
        purchaseOffer.visible = true;
    }
    else {
        [flowManager setEpisodeIndex:episodeButton.index];
        [flowManager setEpisodePath:episodeButton.data.path]; 
        [flowManager changeFlowState:kFlowState_LevelSelection];
        sLastEpisodeHighlighted = episodeButton.index;
    }
}

-(void)backAction:(ButtonControl *)control {
    [flowManager changeFlowState:kFlowState_Title];
    sLastEpisodeHighlighted = [episodeList currentPage];
}

-(void)bankAction:(ButtonControl *)control {
    bankTip.visible = true;
}

-(id)initWithFlowManager:(id<FlowManager>) fm {
    if (self == [super initWithFlowManager:fm]) {
        lastEpisodeButtonPressed = nil;
            
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:Vector2DMul(GetGLDimensions(), 0.5f) withTexture:kTexture_MenuBackground];
        [self addControl:bgImage]; 
        [bgImage bounce];
//        bgImage.tiled = true;
        bgImage.jiggling = true; 
        bgImage.alphaEnabled = false;               
        [bgImage release];
        bgImage = nil;           
        
        Vector2D center = Vector2DMul(GetGLDimensions(),0.5f);
                               
        [self initEpisodes];
        
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
                        
        Vector2D backPosition = Vector2DMake(35.0f,440.0f);
        ButtonControl* backButton = [[ButtonControl alloc] 
            initAt:backPosition withTexture:kTexture_BackButton andText:nil];
        [backButton setResponder:self andSelector:@selector(backAction:)];
        backButton.tilting = false;
        [self addControl:backButton];
        [backButton release];
        backButton = nil;
        
        [CrystalPlayer sharedInstance].delegate = self;        
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

-(void)initEpisodes {
    static eTexture episodeTex[NUM_EPISODES] = {
        kTexture_Episode1,
        kTexture_Episode2,
        kTexture_Episode3,        
    };

    Boolean previousEpisodeComplete = false;
    NSMutableArray* episodes = [NSMutableArray array];
    NSMutableArray* episodeStates = [SaveGame getEpisodeStates];
    BodyLoad* body = [[BodyLoad alloc] initWithPath:@"Episodes"];
    int index = 0;
    for (GroupLoad* group in body.groups) {
        if ([group.typeName caseInsensitiveCompare:@"EPISODE"]==NSOrderedSame) {
            EpisodeData* episode = [[EpisodeData alloc] init];        
            
            episode.displayName = [[group getAttributeString:@"DISPLAY_NAME"] retain];
            episode.path = [[group getAttributeString:@"PATH"] retain];
            episode.achievement = [group getAttributeInt:@"STATE"];
            episode.cost = [group getAttributeInt:@"COST"];
            episode.texture = episodeTex[MIN(index,NUM_EPISODES-1)];
            [episodes addObject:episode];
            [episode release]; 
            
            if (previousEpisodeComplete) {
                episode.achievement = kAchievement_Unlocked;
            }
            else {
                for (NSDictionary* episodeState in episodeStates) {
                    NSString* episodeName = [episodeState objectForKey:ID_KEY];
                    if ([episodeName compare:episode.path]==NSOrderedSame) {
                        episode.achievement = [[episodeState objectForKey:ACHIEVEMENT_KEY] intValue];
                        break;
                    }
                }
            }
            
            previousEpisodeComplete = ([LevelLoader getEpisodeCompletion:episode.path] >= 1.0f);
            ++index;
        }
    }
    
    [body release];
    [episodeStates release];
    
    episodeList = [[ScrollComponent alloc] init];
    episodeList.lockToNearestPage = true;
    episodeList.highlightCurrentPage = true;
    [self addControl:episodeList];
            
    Vector2D screenDimensions = GetGLDimensions();
    Vector2D center = Vector2DMul(screenDimensions, 0.5f);
            
    for (int i = 0; i < episodes.count; ++i) { 
        EpisodeData* data = [episodes objectAtIndex:i];
        EpisodeButton* button = [[EpisodeButton alloc] initAt:center
                                                    withData:data];
        button.index = i;
        [button setResponder:self andSelector:@selector(enterAction:)];
        [episodeList addControl:button toPage:i];
                
        [button release];
        button = nil;        
    } 

    [episodeList setPage:(float)sLastEpisodeHighlighted];
}

-(void)dealloc {
    [CrystalPlayer sharedInstance].delegate = nil;            
    [CrystalSession deactivateCrystalUI];        
    
    [bank           release];
    [bankTip        release];
    [purchaseOffer  release];
    [episodeList    release];
    [moneyGiftButton release];
    [super dealloc];
}

-(Boolean)processEvent:(TapEvent)evt {
    if ([super processEvent:evt]==false && ![flowManager changingFlowState]) {
//        if (evt.type == kTapEventType_Move) {
//            evt.location;
//        }        
        return true;   
    }
    return false;    
}

@end

