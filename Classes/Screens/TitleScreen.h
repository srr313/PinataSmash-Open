//
//  TitleScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/21/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "FBConnect.h"
#import "Screen.h"

@class ButtonControl;
@class ModalControl;
@class LevelEnvironment;

@interface TitleScreen : Screen { //<FBSessionDelegate, FBDialogDelegate> {
    ModalControl*       rateMeModal;
    LevelEnvironment*   sceneEnvironment;
    ButtonControl*      achievementsButton;
}

-(id)initWithFlowManager:(id<FlowManager>)fm;
//-(void)dialogDidComplete:(FBDialog *)dialog;

@end
