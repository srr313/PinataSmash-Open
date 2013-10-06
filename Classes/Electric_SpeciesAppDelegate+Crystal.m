/*
 *  Electric_SpeciesAppDelegate+Crystal.cpp
 *  Electric Species
 *
 *  Created by Sean Rosenbaum on 2/14/11.
 *  Copyright 2011 BlitShake LLC. All rights reserved.
 *
 */

#include "Electric_SpeciesAppDelegate.h"

#import "EAGLView.h"
#import "GameCommon.h"
#import "GameViewController.h"
#import "Sounds.h"

@implementation Electric_SpeciesAppDelegate(Crystal)

- (void) splashScreenFinishedWithActivateCrystal:(BOOL)activateCrystal
{
    if (activateCrystal) {
        [CrystalSession activateCrystalUIAtProfile];
        [viewController.glView changeFlowState:kFlowState_CrystalSplash];
        g_bInBackground = true;         
    }   
    else {
        [viewController.glView changeFlowState:kFlowState_CompanySplash];    
        g_bInBackground = false;     
    }
}

- (void) crystalUiDeactivated {
    g_bInBackground = false;      
    
    if (viewController.glView.flowState == kFlowState_CrystalSplash) {
        [viewController.glView changeFlowState:kFlowState_CompanySplash];        
    }
    else {
        [viewController.glView crystalUiDeactivated];
        [[SimpleAudioEngine sharedEngine] resumeBackgroundMusic];
    }
}

- (void) challengeStartedWithGameConfig:(NSString*)gameConfig
{
 // Start a challenge with the specified game config
 // The game config will match the config shown in the Developer Dashboard
}

@end

