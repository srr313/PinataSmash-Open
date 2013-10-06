//
//  FlowManager.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/21/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "GameCommon.h"

typedef enum {
    kFlowState_UICategory,
        kFlowState_CompanySplash = kFlowState_UICategory,
        kFlowState_CrystalSplash,
        kFlowState_Title,
        kFlowState_Tutorial,
        kFlowState_EpisodeSelection,
        kFlowState_LevelSelection,
        kFlowState_Achievement,
        kFlowState_Credits,
    kFlowState_UICategoryEnd,
    
    kFlowState_GameCategory,
        kFlowState_Pregame,
        kFlowState_Game,
        kFlowState_GameResume,
        kFlowState_LevelEnd,
        kFlowState_Gameover,
        kFlowState_Pause,
    kFlowState_GameCategoryEnd,
        
    kFlowState_Count,
    kFlowState_Undefined=kFlowState_Count,
} eFlowState;

@protocol FlowManager

-(void)changeFlowState:(eFlowState)newState;
-(void)setLevel:(int)level;
-(void)setTool:(eTool)tool;
-(void)setEpisodePath:(NSString*)path;
-(void)setEpisodeIndex:(int)index;
-(Boolean)changingFlowState;
-(eFlowState)previousFlowState;

@end
