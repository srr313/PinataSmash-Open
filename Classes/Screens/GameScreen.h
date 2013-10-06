//
//  GameScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/25/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"
#import "Screen.h"

@class ModalControl;
@class PauseButton;

typedef enum {
    kMessageAlignment_Top = 0,
    kMessageAlignment_Bottom,
    kMessageAlignment_Count,
} eMessageAlignment;

@interface GameScreen : Screen {
    TextControl*        beginText;
    ImageControl*       popupBackground;
    
    float               levelTextTime;
    Boolean             displayLevelText;
    
    NSMutableArray*     multipliers;
    TextControl*        multiplierCheerText;
    float               multiplierCheerTimeleft;
    
    eMessageAlignment   lastTextAlignment;
    TextControl*        messageText;
    float               messageTime;
    
    ModalControl*       tutorialMessage;
    
    float               achievementTime;
    ImageControl*       achievementIcon;
    
    TextControl*        metricCount;
    TextControl*        metricBuffer;
    int                 metricBonusAdded;
    int                 metricBufferDisplayed;
    int                 metricBufferValue;
    float               lastBufferUpdate;
    
    ImageControl*       timeIcon;
    ImageControl*       toolIcon;
    
    TextControl*        bonusMetricText;
    
    PauseButton*        pauseButton;
    
    int                 lastTimeSet;
    int                 lastToolSet;
    
    TextControl*       missPenalty;
    float              lastMissTime;
        
    Game* game;
}

@property (nonatomic, assign) Game* game;

-(id)initWithFlowManager:(id <FlowManager>)fm andGame:(Game*)g;
-(Boolean)processEvent:(TapEvent)evt;
-(void)setLevelText:(NSString*)level;
-(void)showLevelText;
-(void)showMultiplier:(int)value withColor:(Color3D)col atPosition:(Vector2D)pos;
-(void)showMissPenalty:(int)value atPosition:(Vector2D)pos;
-(void)displayMessage:(eLocalizedString)textEnum;
-(void)displayTutorialMessage:(eLocalizedString)textEnum withImages:(NSMutableArray*)images;
-(void)setMetric:(eGameMetric)metric;
-(void)setTool:(eTool)tool;
-(void)setToolCount:(int)count;
-(void)setTimeCount:(int)count;
-(void)setMetricBonus:(int)bonus atPosition:(Vector2D)position;
-(void)addMetricBuffer:(int)bonus;
-(Boolean)messageDone;
-(void)hideMessages;
@end
