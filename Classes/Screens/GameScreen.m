//
//  GameScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/25/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "GameScreen.h"
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "GameCommon.h"
#import "JiggleAnimation.h"
#import "Localize.h"
#import "MetagameManager.h"
#import "ModalControl.h"
#import "Particles.h"
#import "Sounds.h"
#import "Tool.h"

#define LEVEL_TEXT_TIME 1.25f
#define MESSAGE_TEXT_TIME 5.0f

@interface MultiplierControl : ScreenControl
{
    float t;
    Vector2D startPosition;
}
-(id)initAt:(Vector2D)pos withMultiplier:(int)value withColor:(Color3D)col;
-(void)tick:(float)timeElapsed;
-(Boolean)done;
@end

@implementation MultiplierControl
-(id)initAt:(Vector2D)pos withMultiplier:(int)value withColor:(Color3D)col {
    if (self == [super init]) {
        t = 0.0f;
        dimensions = Vector2DMake(96.0f,52.0f);

        // keep multiplier in gl bounds
        startPosition = pos;
        startPosition.x = fminf(GetGLWidth()-dimensions.x, pos.x);
        startPosition.y = fminf(GetGLHeight()-dimensions.y, pos.y);
        position = startPosition;
        
        color = col;
        shadowColor = Color3DMake(0.0f,0.0f,0.0f,0.4f);

        TextControl* multiplier = [[TextControl alloc] 
            initAt:pos 
            withText:kLocalizedString_Multiplier
            andArg:[NSNumber numberWithInt:value]
            andDimensions:dimensions 
            andAlignment:UITextAlignmentRight 
            andFontName:DEFAULT_FONT 
            andFontSize:52];
        multiplier.hasShadow = false;
        [multiplier setColor:color];
        [self addChild:multiplier];
        [multiplier release];
        
        self.jiggling = true;
        [self bounce: fminf(sqrtf(value),3.0f) ];
    }
    return self;
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];

    t += 1.2f*timeElapsed;
    float tSq = t*t;
    position.x = (1.0f-tSq)*startPosition.x+tSq*GetGLWidth()/2;
    position.y = (1.0f-tSq)*startPosition.y+20.0f;
    color.alpha = 4.0f*(1.0f-t)*t;
    
    for (ScreenControl* control in children) {
        control.position = position;
        control.color = color;
        control.scale = scale;
    }
}

-(Boolean)done {
    return t >= 1.0f;
}

@end

//////////////////////////////////////////////////

@interface PauseButton : ButtonControl
{
    int hits;
    float timeSinceHit;
    TextControl* info;
}
-(id)initAt:(Vector2D)pos;
-(Boolean)processEvent:(TapEvent)evt;
-(void)tick:(float)timeElapsed;
-(void)setHits:(int)h;
@end

@implementation PauseButton
-(id)initAt:(Vector2D)pos {
    if (self == [super initAt:pos withTexture:kTexture_PauseButton0 andText:kLocalizedString_Null]) {
        hits = 0;
        timeSinceHit = 0.0f;
        jiggling = true;
        info = [[TextControl alloc] initAt:         Vector2DMake(pos.x,pos.y-48.0f)
                                    withString:     @"(Triple-Tap)" 
                                    andDimensions:  Vector2DMake(96.0f,16.0f)
                                    andAlignment:   UITextAlignmentCenter 
                                    andFontName:    DEFAULT_FONT    
                                    andFontSize:    16];
        info.jiggling   = true;
        info.color      = COLOR3D_BLACK;
        info.baseAlpha  = 0.0f;
        [self addChild:info];
    }
    return self;
}
-(Boolean)processEvent:(TapEvent)evt {
    if (evt.type == kTapEventType_Start) {    
        [self setHits:hits+1];
        timeSinceHit = 0.0f;
        int confetti = 3;
        if (hits >= 3) {
            [info setFade:kFade_Out];
            confetti = 5;
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PinataDestroy)];
        }
        else {
            if (hits == 1 && info.baseAlpha <= 0.0f) {
                [info setFadeDelay:0.0f];
                [info setFade:kFade_In];                
                [info bounce];
            }
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PinataDamage)];
        }
        
        [PARTICLE_MANAGER createConfettiAt:position withAmount:confetti withLayer:kLayer_Game];    
        [self bounce];
        
        if (hits >= 3) {
            return [super processEvent:evt];
        }
                
        return true;
    }
    return false;
}
-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    timeSinceHit += timeElapsed;
    if (timeSinceHit > 0.4f) {
        [self setHits:hits-1];
        timeSinceHit = 0.0f;
        
        if (hits == 0 && info.baseAlpha > 0.0f) {         
            [info setFade:kFade_Out];                
        }
    }
}
-(void)setHits:(int)h {
    hits = MIN(MAX(h, 0), 3);
    texture = kTexture_PauseButton0+MIN(hits,2);
}

-(void)dealloc {
    [info release];
    [super dealloc];
}
@end


//////////////////////////////////////////////////

@interface GameScreen()
-(void)dealloc;
-(void)tick:(float)timeElapsed;
-(Boolean)doneLevelTransition;
-(void)updateMessage:(float)timeElapsed;
-(void)pauseAction:(ButtonControl*)button;
-(void)setMetricValue:(NSString*)value
        withPosition:(Vector2D)position 
        andAlignment:(UITextAlignment)alignment
        andAchievement:(eAchievement)achievement;
-(void)updateMetricBuffer:(float)timeElapsed;
-(void)updateMissPenalty:(float)timeElapsed;
@end

@implementation GameScreen

@synthesize game;

-(id)initWithFlowManager:(id <FlowManager>)fm andGame:(Game*)g; {
    if (self == [super initWithFlowManager:fm]) {
        game = g;
    
        messageTime = LEVEL_TEXT_TIME;
        multipliers = [[NSMutableArray alloc] init];
        multiplierCheerText = nil;
        multiplierCheerTimeleft = 0.0f;
        lastTextAlignment = kMessageAlignment_Top;
        achievementTime = 0.0f;
        
        Vector2D pauseDimensions = GetImageDimensions(kTexture_PauseButton0);
        pauseButton = [[PauseButton alloc] 
                            initAt:Vector2DMake(pauseDimensions.x/2+10.0f,
                                                GetGLHeight()-pauseDimensions.y/2-10.0f)];
        pauseButton.parent = self;
        [pauseButton setResponder:self andSelector:@selector(pauseAction:)];
        pauseButton.tilting = true;
        pauseButton.visible = false;
        [self addControl:pauseButton];
        
        eTexture toolTexture = kTexture_BatTool;
        Vector2D toolDimensions = GetImageDimensions(toolTexture);
        toolIcon = [[ImageControl alloc] 
            initAt:Vector2DMake(GetGLWidth()-toolDimensions.x/2-10.0f,
                                GetGLHeight()-toolDimensions.y/2-10.0f) 
            withTexture:toolTexture];
        toolIcon.hasShadow = true;
        toolIcon.jiggling = true;
        [self addControl:toolIcon];
            
        Vector2D achievementDimensions = GetImageDimensions(kTexture_AchievementIcon);
        achievementIcon = [[ImageControl alloc] 
            initAt:Vector2DMake(achievementDimensions.x/2,GetGLHeight()/2) 
            withTexture:kTexture_AchievementIcon];
        achievementIcon.jiggling = true;
        achievementIcon.tilting = true;
        achievementIcon.hasShadow = true;
        achievementIcon.baseAlpha = 0.0f;
        [self addControl:achievementIcon];
                        
        Vector2D popupDim = GetImageDimensions(kTexture_GamePopup);
        Vector2D popupPosition = Vector2DMake(  GetGLWidth()/2,
                                                GetGLHeight()-popupDim.y/2-10.0f);
        popupBackground = [[ImageControl alloc] 
            initAt:popupPosition withTexture:kTexture_GamePopup]; 
        popupBackground.baseAlpha = 0.0f;
        [self addControl:popupBackground];
        
        lastTimeSet = INT_MAX;
        lastToolSet = INT_MAX;
        missPenalty = nil;
    }
    return self;
}

-(void)dealloc {
    [tutorialMessage release];
    [beginText release];
    [multipliers release];
    [messageText release];
    [multiplierCheerText release];
    [popupBackground release];
    [achievementIcon release];
    [toolIcon release];
    [timeIcon release];
    [metricCount release];
    [metricBuffer release];    
    [bonusMetricText release];
    [pauseButton release];
    [missPenalty release];
    [super dealloc];
}

-(Boolean)doneLevelTransition {
    return (levelTextTime <= 0.0f);
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    
    for (ScreenControl* control in controls) {
        control.shadowColor = [game shadowColor];
    }
    
    if (game.tutorialMode) {   
        return;
    }
    
    if (bonusMetricText.fade == kFade_Stop && bonusMetricText.color.alpha >= 1.0f) {
        [bonusMetricText setFadeDelay:0.75];
        [bonusMetricText setFade:kFade_Out];
    }

    [self updateMetricBuffer:timeElapsed];
    [self updateMissPenalty:timeElapsed];    
    
    if (displayLevelText) {
        [self showLevelText];
        displayLevelText = false;
    }
        
    if ( ![self doneLevelTransition] ) {
        levelTextTime -= timeElapsed;
        
        if ([self doneLevelTransition]) {
            [beginText setFade:kFade_Out];
            [beginText bounce:1.0f];           
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_LevelTip)];            
        }
    }
    
    {   // update multiplier cheer text
        if (multiplierCheerTimeleft > 0.0f) {
            multiplierCheerTimeleft -= timeElapsed;
            multiplierCheerText.position = 
                Vector2DMake(   multiplierCheerText.position.x,
                                multiplierCheerText.position.y-60.0f*timeElapsed);
            if (multiplierCheerTimeleft <= 0.0f) {
                [multiplierCheerText setFade:kFade_Out];
            }
        }
    }
    
    
    {   // update multipliers
        NSMutableArray* multipliersDone = [NSMutableArray array];
        for (MultiplierControl* control in multipliers) {
            if ([control done]) {
                [multipliersDone addObject:control];
            }
        }
        [controls removeObjectsInArray:multipliersDone];
        [multipliers removeObjectsInArray:multipliersDone];
    }
    
    {
//        if (METAGAME_MANAGER.justEarnedNewAchievement) {
//            [achievementIcon setFade:kFade_In];
//            [achievementIcon bounce:1.25f];
//            achievementTime = 1.5f;
//        }
        
        if (achievementTime > 0.0f) {
            achievementTime -= timeElapsed;
        }
        else if (achievementIcon.fade == kFade_Stop && achievementIcon.baseAlpha > 0.0f) {
            [achievementIcon setFade:kFade_Out];
        }
    }
    
    [self updateMessage:timeElapsed];
}

-(Boolean)processEvent:(TapEvent)evt {
    if (evt.type == kTapEventType_Start && !game.tutorialMode) {
        [toolIcon bounce];
    }
    return [super processEvent:evt];
}

-(void)setMetric:(eGameMetric)metric {
    if (metric == kGameRule_Time) {
        Vector2D timeDimensions = GetImageDimensions(kTexture_TimeIcon);
        timeIcon = [[ImageControl alloc] 
            initAt:Vector2DMake(    (GetGLWidth()-timeDimensions.x)/2,
                                    GetGLHeight()-timeDimensions.y/2-10.0f) 
            withTexture:kTexture_TimeIcon];
        [timeIcon setColor:COLOR3D_WHITE];
        timeIcon.hasShadow = true;
        timeIcon.jiggling  = true;
        [controls insertObject:timeIcon atIndex:0];
    }
}

-(void)setTool:(eTool)tool {
    toolIcon.texture = [Tool getTexture:tool];
}

-(void)setToolCount:(int)count { 
    int toolCount = MAX((game.gameLevel.rule.bronze-count+metricBonusAdded), 0);
    if (game.gameLevel.rule.metric == kGameRule_Shots && toolCount != lastToolSet) {
        toolIcon.tilting = true;
        lastToolSet = toolCount;
        Vector2D toolDimensions = GetImageDimensions(kTexture_BatTool);
        NSString* value = [NSString stringWithFormat:@"%d", lastToolSet+metricBonusAdded];
        [self setMetricValue:value
                withPosition:Vector2DMake(
                    GetGLWidth()-1.5f*toolDimensions.x-ToGameScaleX(10.0f),
                    GetGLHeight()-ToGameScaleY(42.0f))
                andAlignment:UITextAlignmentRight
                andAchievement:[game getMedalForMetric:count-metricBonusAdded] ];
        if (lastToolSet < 10) {
            toolIcon.pulsing = true;
        }
    }    
}

-(void)setTimeCount:(int)count {
    int timeCount = MAX(game.gameLevel.rule.bronze-count+metricBonusAdded,0);
    if (game.gameLevel.rule.metric == kGameRule_Time && timeCount != lastTimeSet) {
        timeIcon.tilting        = true;
        lastTimeSet             = timeCount;
        Vector2D timeDimensions = GetImageDimensions(kTexture_TimeIcon);
            
        [self setMetricValue:GetGameTimeFormat(lastTimeSet, false)
                withPosition:Vector2DMake(  GetGLWidth()/2+0.75f*timeDimensions.x,
                                            GetGLHeight()-timeDimensions.y/2-10.0f)
                andAlignment:UITextAlignmentLeft
                andAchievement:[game getMedalForMetric:count-metricBonusAdded] ];
                
        float danger = lastTimeSet/(float)game.gameLevel.rule.bronze;
        [timeIcon setColor: Color3DMake(1.0f, danger, danger, timeIcon.color.alpha)];
                
        if (lastTimeSet < 10) {
            [timeIcon bounce];
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_ClockTick)];            
        }
        else {
            timeIcon.pulsing = false;
        }
    }    
}

-(void)setMetricValue:(NSString*)value 
        withPosition:(Vector2D)position 
        andAlignment:(UITextAlignment)alignment
        andAchievement:(eAchievement)achievement {

    Color3D color = COLOR3D_WHITE;
    if (achievement == kAchievement_Gold) {
        color = GetAchievementColor(achievement);
    }
    else if (achievement == kAchievement_Silver) {
        color = COLOR3D_BLUE;
    }
    else { 
//        color = Color3DMake(0.6f, 0.45f, 0.3f, 1.0f);
        color = COLOR3D_RED;
    }
        
    if (metricCount) {
        [self removeControl:metricCount];
        [metricCount release];
        metricCount = nil;
    }
    
    metricCount = [[TextControl alloc] 
        initAt:position 
        withString:value
        andDimensions:Vector2DMake(80.0f,32.0f) 
        andAlignment:alignment 
        andFontName:DEFAULT_FONT 
        andFontSize:32];
    metricCount.jiggling = true;
    metricCount.hasShadow = false;
    [metricCount setColor:color];
    [controls insertObject:metricCount atIndex:0];
    [metricCount bounce]; 
}

-(void)setMetricBonus:(int)bonus atPosition:(Vector2D)position {
    if (!bonusMetricText) {
        NSString* text = (game.gameLevel.rule.metric == kGameRule_Time) ? @"Time Bonus!" : @"Shots Bonus!";
        bonusMetricText = [[TextControl alloc] 
            initAt:ZeroVector()
            withText:text
            andArg:nil
            andDimensions:Vector2DMake(GetGLWidth()/2,28.0f) 
            andAlignment:UITextAlignmentCenter 
            andFontName:DEFAULT_FONT andFontSize:28];
        bonusMetricText.jiggling = true;
        bonusMetricText.hasShadow = false;
        [bonusMetricText setColor:COLOR3D_GREEN];
        
        [controls insertObject:bonusMetricText atIndex:0];
    }
        
    position.x = fminf(position.x, GetGLWidth()-ToGameScaleX(128.0f));
    position.x = fmaxf(position.x, ToGameScaleX(128.0f));
    bonusMetricText.position = position;
    
    [bonusMetricText setFadeDelay:0.0f];    
    [bonusMetricText setFade:kFade_In];
    [bonusMetricText bounce:1.25f];
    
    [self addMetricBuffer:bonus];
}

-(void)addMetricBuffer:(int)value { 
    metricBufferValue += value;
}

-(void)updateMetricBuffer:(float)timeElapsed {
    lastBufferUpdate += timeElapsed;
    int delta = metricBufferValue-metricBufferDisplayed;
    if (lastBufferUpdate >= 0.05f) {    
        if (abs(delta) > 0) {
            int change = (delta>0)?1:-1;
            metricBufferDisplayed += change;
            lastBufferUpdate = 0.0f;
            
            if (metricBuffer) {
                [self removeControl:metricBuffer];
                [metricBuffer release];
                metricBuffer = nil;
            }
            
            NSString* metricBufferText = 
                [NSString stringWithFormat:(metricBufferDisplayed>0)?@"+%d":@"%d", 
                    metricBufferDisplayed];
            Vector2D position = Vector2DMake(   metricCount.position.x,
                                                metricCount.position.y-36.0f);
            metricBuffer = [[TextControl alloc] 
                initAt:position
                withText:metricBufferText
                andArg:nil
                andDimensions:Vector2DMake(64.0f,22.0f) 
                andAlignment:UITextAlignmentLeft 
                andFontName:DEFAULT_FONT 
                andFontSize:22];
            metricBuffer.jiggling = true;
            metricBuffer.hasShadow = false;
            
            Color3D color = (metricBufferDisplayed > 0) ? COLOR3D_GREEN : COLOR3D_RED;
            [metricBuffer setColor:color];
            [metricBuffer bounce];            
            [controls insertObject:metricBuffer atIndex:0];             
        }
        else if (lastBufferUpdate >= 0.5f 
                    && metricBuffer.fade == kFade_Stop
                    && metricBuffer.baseAlpha > 0.0f) {
            [metricBuffer setFade:kFade_Out];            
            metricBonusAdded += metricBufferValue;            
            metricBufferDisplayed = 0;
            metricBufferValue = 0;
            lastBufferUpdate = 0.0f;
            
            [timeIcon bounce];
        }
    }
}

-(void)showMultiplier:(int)value withColor:(Color3D)col atPosition:(Vector2D)pos {
    MultiplierControl* mc = [[MultiplierControl alloc] initAt:pos withMultiplier:value withColor:col];
    [multipliers addObject:mc];
    [self addControl:mc];
    [mc release];
    mc = nil;

    static const int multiplierIntervalSize = 5;
    if (value%multiplierIntervalSize==0) {
        if (multiplierCheerText) {
            [self removeControl:multiplierCheerText];
            [multiplierCheerText release];
            multiplierCheerText = nil;
        }
        
        static const int numCheers = 5;
        static const eLocalizedString sCheers[] = {
            kLocalizedString_MultiplierCheer1,
            kLocalizedString_MultiplierCheer2,
            kLocalizedString_MultiplierCheer3,
            kLocalizedString_MultiplierCheer4,
            kLocalizedString_MultiplierCheer5,
        };
    
        static int lastMessage = -1;
        lastMessage = (1+lastMessage)%numCheers;
        eLocalizedString randMessage = sCheers[lastMessage];
        Vector2D screenDimensions = GetGLDimensions();
        Vector2D messagePosition = Vector2DMake(screenDimensions.x/2, 60.0f);
        multiplierCheerText = [[TextControl alloc] 
            initAt:messagePosition 
            withText:LocalizeText(randMessage)
            andArg:nil
            andDimensions:Vector2DMake(screenDimensions.x,36.0f) 
            andAlignment:UITextAlignmentCenter 
            andFontName:DEFAULT_FONT andFontSize:32];
        multiplierCheerText.jiggling = true;
        multiplierCheerText.hasShadow = false;
        [multiplierCheerText setColor:col];
        [self addControl:multiplierCheerText];
        [multiplierCheerText bounce:1.25f]; 
        
        multiplierCheerTimeleft = 0.75f;
    }   
}

-(void)showMissPenalty:(int)value atPosition:(Vector2D)pos {
    if (missPenalty) {
        [self removeControl:missPenalty];        
        [missPenalty release];
        missPenalty = nil;
    }
        
    missPenalty = [[TextControl alloc] 
                    initAt:         pos 
                    withString:     [NSString stringWithFormat:@"%d", value]         
                    andDimensions:  Vector2DMake(64.0f,34.0f)
                    andAlignment:   UITextAlignmentCenter 
                    andFontName:    DEFAULT_FONT 
                    andFontSize:    32];
    missPenalty.hasShadow   = false;
    missPenalty.color       = COLOR3D_RED;
    missPenalty.jiggling    = true;
    lastMissTime            = 0.0f;
    [missPenalty setFade:kFade_In];
    [missPenalty bounce:1.0f];
    [self addControl:missPenalty];
}

-(void)updateMissPenalty:(float)timeElapsed {
    lastMissTime += timeElapsed;

    missPenalty.position = Vector2DAdd(missPenalty.position, Vector2DMake(0.0f,64.0f*timeElapsed));

    if (lastMissTime > 1.0f && missPenalty.fade == kFade_Stop && missPenalty.baseAlpha>0.0f) {
        [missPenalty setFade:kFade_Out];
    }
}

-(void)setLevelText:(NSString*)level {
    Vector2D screenDimensions = GetGLDimensions();
    Vector2D position = Vector2DMul(screenDimensions,0.5f);    
    beginText = [[TextControl alloc] 
        initAt:position
        withText:kLocalizedString_LevelStart
        andArg:nil
        andDimensions:Vector2DMake(96,64.0f) 
        andAlignment:UITextAlignmentCenter 
        andFontName:DEFAULT_FONT andFontSize:64];
    beginText.jiggling = true;
    beginText.hasShadow = true;
    [beginText setColor:COLOR3D_RED];
    displayLevelText = true;
}

-(void)showLevelText {    
    if (beginText) {
        [self addControl:beginText];  
        [beginText setFade:kFade_In];
        [beginText setFadeDelay:0.2f];
        [beginText bounce:1.0f];        
        levelTextTime = LEVEL_TEXT_TIME;
        
        pauseButton.visible = true;
        [pauseButton setFade:kFade_In];
    }
}

-(void)updateMessage:(float)timeElapsed {
    messageTime -= timeElapsed;
    if (messageTime <= 1.0f) {
        if (messageText.fade == kFade_Stop && messageText.baseAlpha > 0.0f) {
            [messageText setFade:kFade_Out];
            [messageText bounce:0.25f];
        }
        if (popupBackground.fade == kFade_Stop && popupBackground.baseAlpha > 0.0f) {           
            [popupBackground setFade:kFade_Out];
            [popupBackground bounce:0.25f];
        }
    }
}

-(void)displayMessage:(eLocalizedString)textEnum {            
    Vector2D screenDimensions = GetGLDimensions();
            
    Vector2D positions[2];
    positions[0].x = positions[1].x = screenDimensions.x/2;
    positions[0].y = screenDimensions.y-80.0f;
    positions[1].y = 50.0f;
        
    NSString* text = LocalizeText(textEnum);
    
    if (messageText) {
        [self removeControl:messageText];
        [messageText release];
        messageText = nil;
    }
    
    float messageWidth = IsDeviceIPad() ? 260 : 300.0f;    
    messageText = [[TextControl alloc] 
        initAt:positions[lastTextAlignment] 
        withString:text
        andDimensions:Vector2DMake(messageWidth,100.0f) 
        andAlignment:UITextAlignmentCenter 
        andFontName:DEFAULT_FONT andFontSize:24];
    messageText.jiggling = true;
    messageText.hasShadow = false;
    [messageText setColor:COLOR3D_WHITE];
    [self addControl:messageText];
    [messageText bounce:0.25f];
    
    [popupBackground setFade:kFade_In];
    [popupBackground bounce:0.25f];
        
    messageTime = MESSAGE_TEXT_TIME;
    
    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_PinataSplit)];
}

-(void)tutorialClosedAction:(ButtonControl*)control {
    game.tutorialMode = false;
    pauseButton.visible = true;
}

-(void)displayTutorialMessage:(eLocalizedString)textEnum 
        withImages:(NSMutableArray*)images {

    if (tutorialMessage) {
        [self removeControl:tutorialMessage];
        [tutorialMessage release];
    }
    
    if (images) {
        NSMutableArray* imageControls = [[NSMutableArray alloc] initWithCapacity:images.count];
        for (NSString* img in images) {
            ImageControl* image = [[ImageControl alloc] initAt:ZeroVector() withTexture:GetTextureId(img)];
            [imageControls addObject:image];
            [image release];
        }
        tutorialMessage = [ModalControl createModalWithMessage:textEnum 
                                        andArg:nil 
                                        andImages:imageControls];    
        [imageControls release];
    }
    else {
        tutorialMessage = [ModalControl createModalWithMessage:textEnum 
                                        andArg:nil 
                                        andFontSize:24];
    }
    
    tutorialMessage.visible = true;
    [self addControl:tutorialMessage];
    
    [tutorialMessage setCloseResponder:self andSelector:@selector(tutorialClosedAction:)];                
    game.tutorialMode = true;
    
    pauseButton.visible = false;
}

-(Boolean)messageDone {
    return messageTime <= 0.0f;
}

-(void)pauseAction:(ButtonControl*)button {
    [flowManager changeFlowState:kFlowState_Pause];
}

-(void)hideMessages {
    messageText.visible     = false;
    popupBackground.visible = false;
}

@end
