//
//  Electric_SpeciesAppDelegate.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright BlitShake LLC 2010. All rights reserved.
//

#import "Electric_SpeciesAppDelegate.h"
#import "EAGLView.h"
#import "GameCommon.h"
#import "GameViewController.h"
#import "CrystalPlayer.h"

#ifdef DO_ANALYTICS
    #import "FlurryAPI.h"
#endif

//#define USE_CRYSTAL_SPLASH

@implementation Electric_SpeciesAppDelegate

@synthesize viewController;
@synthesize window;


void uncaughtExceptionHandler(NSException *exception) {
#ifdef DO_ANALYTICS
    [FlurryAPI logError:@"Uncaught" message:@"Crash!" exception:exception];
#endif
}

- (void)startApp {
#ifdef DO_ANALYTICS
    [FlurryAPI startSession: ENTER_FLURRY_CODE ];
#endif

    [window addSubview:[viewController view]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

     [self startApp];
    
    [CrystalSession application:application
                    didFinishLaunchingWithOptions:launchOptions];
             
             
    NSString* themeName = @"pinatasmash_04"; //@"UniversalIndigo_002";
     
    [CrystalSession initWithAppID:  ENTER_CRYSTAL_APP_ID
                        delegate:   self 
                        version:    1.0 
                        theme:      themeName
                        secretKey:  ENTER_CRYSTAL_SECRET_KEY];
         
    [CrystalSession lockToOrientationList:
     [NSArray arrayWithObjects:
      [NSNumber numberWithInt:UIDeviceOrientationPortrait],
      [NSNumber numberWithInt:UIDeviceOrientationPortraitUpsideDown], nil]];    
  
    [[CrystalPlayer sharedInstance] startUpdating];    
    
#ifdef USE_CRYSTAL_SPLASH    
    // only display crystal splash screen once
    if ( ![[NSUserDefaults standardUserDefaults] objectForKey:@"crystal_start"] ) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"crystal_start"];        
        [[NSUserDefaults standardUserDefaults] synchronize];    
        
        [CrystalSession displaySplashScreen];                        
        g_bInBackground = true;
    }
    else 
#endif
    {
        [viewController.glView changeFlowState:kFlowState_CompanySplash];            
    }
    
    return YES;
}

- (void) application:(UIApplication*)application
         didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    [CrystalSession application:application
        didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void) application:(UIApplication*)application
         didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    [CrystalSession application:application
        didReceiveRemoteNotification:userInfo];
}

- (void) application:(UIApplication*)application
         didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [CrystalSession application:application
        didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [viewController stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    srandom(time(NULL));
    [viewController startAnimation];    
    [viewController didBecomeActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Save the state of your app, just as you would have in applicationWillTerminate.
    // You may also want to set a variable to indicate that the app has been put in the
    // background.  I check this variable in my OpenGL loop to prevent rendering when
    // in this state.  A single OpenGL call to a backgrounded app will cause it to crash.
    g_bInBackground = true;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // The app was successfully restored.  If you saved game state that is no longer
    // needed, you can delete that data now.
    g_bInBackground = false;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [viewController stopAnimation];
}

- (void)dealloc
{
    [window release];
    [viewController release];
    [super dealloc];
}

@end
