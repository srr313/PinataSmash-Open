/*
 *  AppController+Crystal.mm
 *
 *  Created by Gareth Reese
 *  Copyright 2009 Chillingo Ltd. All rights reserved.
 *
 */


// From Unity
#import "AppController.h"

// From Crystal
#import "CrystalSession.h"

// Unity functions
void UnitySetAudioSessionActive(bool active);
void UnityPause(bool pause);

static const NSTimeInterval KCrystalCommandProcessingPerSecond = 5.0;
static NSString* KCrystalCommandChannel = @"CCCommands";
static NSString* KCrystalChallengeNotificationChannel = @"CCChallengeNotification";
static NSString* KCrystalAppStartedFromChallenge = @"CCStartedFromChallenge";
static NSString* KCrystalPopoversActivated = @"CCPopoversActivated";

static UIDeviceOrientation currentOrientation = UIDeviceOrientationLandscapeLeft;

static BOOL _gameCenterEnabled = NO;


typedef enum
{
	StandardUi,
	ChallengesUi,
	LeaderboardsUi,
	AchievementsUi,
	ProfileUi
} ActivateUiType;


@interface AppController (Crystal) <CrystalSessionDelegate>

- (void) clearCommandChannels;

- (void) cmdActivateUiWithType:(NSString*)type;
- (void) cmdDeactivateUi;
- (void) cmdPostChallengeResultForLastChallengeWithResult:(NSString*)result;
- (void) cmdPostAchievementWithId:(NSString*)idString wasObtained:(NSString*)wasObtained description:(NSString*)description alwaysPopup:(NSString*)alwaysPopup;
- (void) cmdPostLeaderboardResultWithId:(NSString*)idString result:(NSString*)result lowestValFirst:(NSString*)lowestValFirst;
- (void) cmdLockToOrientation:(NSString*)orientationString;
- (void) cmdDisplaySplashScreen;
- (void) cmdActivateCrystalSetting:(NSString*)setting value:(NSString*)value;
- (void) cmdAuthenticateLocalPlayer;

@end


@implementation AppController (Crystal)


// Overrides AppController
- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	printf_console("[Crystal] applicationDidFinishLaunching\n");
	
	// >> From AppController
	[self startUnity:application];
	// <<
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Crystal Setup 
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	[CrystalSession initWithAppID:@"23613" delegate:self version:1.0 theme:@"iPadIndigo_006" secretKey:@"etepe4u7hg667ub5hl5ahtngcvsejh"];
	[CrystalSession lockToOrientationList:[NSArray arrayWithObjects:[NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft], [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight], nil]];
	[CrystalSession activateCrystalSetting:CrystalSettingSingleiPadPopover value:@"YES"];
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	[self clearCommandChannels];
	[NSTimer scheduledTimerWithTimeInterval:(1.0 / KCrystalCommandProcessingPerSecond) target:self selector:@selector(processCommandChannels:) userInfo:nil repeats:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}


- (void)didRotate:(NSNotification *)notification
{
	UIDeviceOrientation newOrientation = [[UIDevice currentDevice] orientation];
	[CrystalSession willRotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation duration:0];
	[CrystalSession didRotateFromInterfaceOrientation:(UIInterfaceOrientation)currentOrientation];
	currentOrientation = newOrientation;
}


#pragma mark -
#pragma mark CrystalSessionDelegate

- (void) challengeStartedWithGameConfig:(NSString*)gameConfig
{	
	// Set a key that will be picked up in the c#
	NSLog(@"[Crystal] challengeStartedWithGameConfig %@", gameConfig);
	[[NSUserDefaults standardUserDefaults] setObject:gameConfig forKey:KCrystalChallengeNotificationChannel];
}


- (void) splashScreenFinishedWithActivateCrystal:(BOOL)activateCrystal
{
	if (activateCrystal)
	{
		// The user clicked YES to activate Crystal
		
		// If you're running on iPhone only you might want to completely pause Unity while Crystal is running
		// It's always best to handle this yourself though as when paused Unity won't handle screen rotations
		// UnitySetAudioSessionActive(false);
		// UnityPause(true);
		
		[CrystalSession activateCrystalUIAtProfile];
	}
}


- (void) crystalUiDeactivated
{
	// You won't need to unpause anything here if there are no other pauses enabled in this file (the default behaviour)
	// UnitySetAudioSessionActive(true);
	// UnityPause(false);
}


- (void) crystaliPadPopoversActivated:(BOOL)activated
{
	// Set a key that will be picked up in the c#
	NSLog(@"[Crystal] crystaliPadPopoversActivated %d", activated);
	if (activated)
		[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:KCrystalPopoversActivated];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:KCrystalPopoversActivated];
}


#pragma mark -
#pragma mark UIApplicationDelegate

- (void) application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	[CrystalSession application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}


- (void) application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	[CrystalSession application:application didFailToRegisterForRemoteNotificationsWithError:error];
}


- (void) application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	[CrystalSession application:application didReceiveRemoteNotification:userInfo];
}


- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[CrystalSession application:application didFinishLaunchingWithOptions:launchOptions];
	[self applicationDidFinishLaunching:application];
	return YES;
}


#pragma mark -
#pragma mark Command Handling

- (void) updateStartedFromChallenge
{
	if ([CrystalSession appWasStartedFromPendingChallenge])
	{
		[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:KCrystalAppStartedFromChallenge];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalAppStartedFromChallenge];
	}
}


- (void) processCommandChannels:(NSTimer*)theTimer
{
	NSString* commandChannel = [[NSUserDefaults standardUserDefaults] objectForKey:KCrystalCommandChannel];
	[self updateStartedFromChallenge];
	
	// Finish quickly if there's no command to process
	if (!commandChannel || ([commandChannel length] == 0))
		return;
	
	// Find each of the commands
	NSArray* commands = [commandChannel componentsSeparatedByString:@"!<->!"];
	
	for (NSString* command in commands)
	{
		NSArray* commandParameters = [command componentsSeparatedByString:@"|"];
		NSLog(@"[Crystal] processing command %@ from '%@'", commandParameters, command);
		
		NSString* commandParam0 = nil;
		NSString* commandParam1 = nil;
		NSString* commandParam2 = nil;
		NSString* commandParam3 = nil;
		NSString* commandParam4 = nil;
		int count = [commandParameters count];
		
		if (count > 0) commandParam0 = [commandParameters objectAtIndex:0];
		if (count > 1) commandParam1 = [commandParameters objectAtIndex:1];
		if (count > 2) commandParam2 = [commandParameters objectAtIndex:2];
		if (count > 3) commandParam3 = [commandParameters objectAtIndex:3];
		if (count > 4) commandParam4 = [commandParameters objectAtIndex:4];
		
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalCommandChannel];
		
		if (commandParam0 && ([commandParam0 compare:@"ActivateUi"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 2 params on ActivateUi");
			[self cmdActivateUiWithType:commandParam1];
		}

		if (commandParam0 && ([commandParam0 compare:@"DeactivateUi"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 1 param on ActivateUi");
			[self cmdDeactivateUi];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostChallengeResultForLastChallenge"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 2 params on PostChallengeResultForLastChallenge");
			[self cmdPostChallengeResultForLastChallengeWithResult:commandParam1];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostAchievement"] == NSOrderedSame))
		{
			NSAssert(count == 5, @"[Crystal] require 4 params on PostAchievement");
			[self cmdPostAchievementWithId:commandParam1 wasObtained:commandParam2 description:commandParam3 alwaysPopup:commandParam4];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostLeaderboardResult"] == NSOrderedSame))
		{
			NSAssert(count == 4, @"[Crystal] require 3 params on PostLeaderboardResult");
			[self cmdPostLeaderboardResultWithId:commandParam1 result:commandParam2 lowestValFirst:commandParam3];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"LockToOrientation"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 1 params on LockToOrientation");
			[self cmdLockToOrientation:commandParam1];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"DisplaySplashScreen"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 0 params on DisplaySplashScreen");
			[self cmdDisplaySplashScreen];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"ActivateCrystalSetting"] == NSOrderedSame))
		{
			NSAssert(count == 3, @"[Crystal] require 2 params on ActivateCrystalSetting");
			[self cmdActivateCrystalSetting:commandParam1 value:commandParam2];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"AuthenticateLocalPlayer"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 0 params on AuthenticateLocalPlayer");
			[self cmdAuthenticateLocalPlayer];
		}
	}
	
	// Swallow the processed set of commands
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalCommandChannel];
}


- (void) cmdActivateUiWithType:(NSString*)type
{
	ActivateUiType uiType = (ActivateUiType)[type intValue];
	
	// If you're running on iPhone only you might want to completely pause Unity while Crystal is running
	// It's always best to handle this yourself though as when paused Unity won't handle screen rotations
	// UnitySetAudioSessionActive(false);
	// UnityPause(true);
	
	switch (uiType) {
		case StandardUi:
			[CrystalSession activateCrystalUI];
			break;
			
		case ChallengesUi:
			[CrystalSession activateCrystalUIAtChallenges];
			break;
			
		case LeaderboardsUi:
			[CrystalSession activateCrystalUIAtLeaderboards];
			break;
			
		case AchievementsUi:
			[CrystalSession activateCrystalUIAtAchievements];
			break;
			
		case ProfileUi:
			[CrystalSession activateCrystalUIAtProfile];
			break;
			
		default:
			NSAssert(NO, @"[Crystal] unsupported UI type in cmdActivateUiWithType");
			break;
	}
}


- (void) cmdDeactivateUi
{
	NSLog(@"[Crystal] DeactivateUi");
	[CrystalSession deactivateCrystalUI];
}


- (void) cmdPostChallengeResultForLastChallengeWithResult:(NSString*)result
{
	float resultFloat = [result floatValue];
	NSLog(@"[Crystal] PostChallengeResultForLastChallengeWithResult %f", resultFloat);
	
	[CrystalSession postChallengeResultForLastChallenge:resultFloat withCrystalDialog:NO];
}


- (void) cmdPostAchievementWithId:(NSString*)idString wasObtained:(NSString*)wasObtained description:(NSString*)description alwaysPopup:(NSString*)alwaysPopup
{
	BOOL obtainedBool = [wasObtained boolValue];
	BOOL alwaysPopupBool = [alwaysPopup boolValue];
	NSLog(@"[Crystal] PostAchievementWithId %@ obtained %d desc %@ alwaysPopup", idString, wasObtained, description, alwaysPopup);
	
	if (_gameCenterEnabled)
		[CrystalSession postAchievement:idString wasObtained:obtainedBool withDescription:description alwaysPopup:alwaysPopupBool forGameCenterAchievementId:idString];
	else
		[CrystalSession postAchievement:idString wasObtained:obtainedBool withDescription:description alwaysPopup:alwaysPopupBool];
}


- (void) cmdPostLeaderboardResultWithId:(NSString*)idString result:(NSString*)result lowestValFirst:(NSString*)lowestValFirst
{
	float resultFloat = [result floatValue];
	BOOL lowestValBool = [lowestValFirst boolValue];
	NSLog(@"[Crystal] PostLeaderboardResultWithId %@ result %f", idString, resultFloat, lowestValFirst);
	
	if (_gameCenterEnabled)
		[CrystalSession postLeaderboardResult:resultFloat forLeaderboardId:idString lowestValFirst:lowestValBool forGameCenterLeaderboardId:idString];
	else
		[CrystalSession postLeaderboardResult:resultFloat forLeaderboardId:idString lowestValFirst:lowestValBool];
}


- (void) cmdLockToOrientation:(NSString*)orientationString
{
	if (orientationString && ([orientationString compare:@"portrait"] == NSOrderedSame))
	{
		[CrystalSession lockToOrientation:UIDeviceOrientationPortrait];
	}
	else if (orientationString && ([orientationString compare:@"landscapeLeft"] == NSOrderedSame))
	{
		[CrystalSession lockToOrientation:UIDeviceOrientationLandscapeLeft];
	}
	else if (orientationString && ([orientationString compare:@"landscapeRight"] == NSOrderedSame))
	{
		[CrystalSession lockToOrientation:UIDeviceOrientationLandscapeRight];
	}
}


- (void) cmdDisplaySplashScreen
{
	[CrystalSession displaySplashScreen];
}


- (void) cmdActivateCrystalSetting:(NSString*)setting value:(NSString*)value
{
	int intSetting = [setting intValue];
	
	[CrystalSession activateCrystalSetting:(CrystalSetting)intSetting value:value];
	
	if ((intSetting == CrystalSettingEnableGameCenterSupport) && 
		([value compare:@"YES"] == NSOrderedSame))
	{
		_gameCenterEnabled = YES;
	}
	else if ((intSetting == CrystalSettingEnableGameCenterSupport) && 
			 ([value compare:@"NO"] == NSOrderedSame))
	{
		_gameCenterEnabled = NO;		
	}
}


- (void) cmdAuthenticateLocalPlayer
{
	[CrystalSession authenticateLocalPlayerWithCompletionHandler:^ (NSError* error) 
	 {
		 if (error) 
		 {
			 // Handle errors here if needed
			 NSLog(@"An error occured authenticating the local game center player");
			 NSLog(@"Error: %@", [error localizedDescription]);
		 }
		 else 
		 {
			 // Handle success here if needed
		 }
	 }];
}


- (void) clearCommandChannels
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalCommandChannel];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalChallengeNotificationChannel];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalAppStartedFromChallenge];
}

@end
