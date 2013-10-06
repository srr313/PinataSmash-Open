//
//  Electric_SpeciesAppDelegate.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright BlitShake LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CrystalSession.h"

@class EAGLView;
@class GameViewController;

@interface Electric_SpeciesAppDelegate : NSObject <UIApplicationDelegate,CrystalSessionDelegate> {
    UIWindow *window;
    GameViewController* viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *viewController;

@end

