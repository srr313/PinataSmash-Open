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
#import "CrystalVirtualGoods.h"
#import "CrystalPlayer.h"
#import "CrystalLeaderboards.h"
#import "CrystalSession+UnityHelper.h"

//#define ENABLE_PLAYER_DATA
//#define ENABLE_VIRTUAL_GOODS

// Unity functions
void UnitySetAudioSessionActive(bool active);
void UnityPause(bool pause);

static const NSTimeInterval KCrystalCommandProcessingPerSecond = 5.0;

static NSString* KCrystalCommandChannel = @"CCCommands";
static NSString* KCrystalChallengeNotificationChannel = @"CCChallengeNotification";
static NSString* KCrystalAppStartedFromChallenge = @"CCStartedFromChallenge";
static NSString* KCrystalPopoversActivated = @"CCPopoversActivated";
static NSString* KCrystalUiDeactivated = @"CCUIDeactivated";

static NSString* KCrystalPlayerInfoUpdated = @"CCPlayerInfoUpdated";

static NSString* KCrystalVirtualGoodsUpdated = @"CCVirtualGoodsUpdated";
static NSString* KCrystalVirtualBalancesUpdated = @"CCVirtualBalancesUpdated";

static NSString* KCrystalLeaderboardsTop20EntriesForLeaderboardIDUpdated = @"CCTop20EntriesForLeaderboardIDUpdated";
static NSString* KCrystalLeaderboardsTop20FriendsForLeaderboardIDUpdated = @"CCTop20FriendsForLeaderboardIDUpdated";
static NSString* KCrystalLeaderboardsRandom20ForLeaderboardIDUpdated = @"CCRandom20ForLeaderboardIDUpdated";
static NSString* KCrystalLeaderboardsCurrentUserEntryForLeaderboardIDUpdated = @"CCCurrentUserEntryForLeaderboardIDUpdated";


static UIDeviceOrientation currentOrientation = UIDeviceOrientationLandscapeLeft;

static BOOL _gameCenterEnabled = NO;



typedef enum
{
	StandardUi,
	ProfileUi,
	ChallengesUi,
	LeaderboardsUi,
	AchievementsUi,
	AddFriends,
	Settings,
	Gifting,
	VirtualGoods,
	VirtualCurrencies
} ActivateUiType;



typedef enum
{
	NewsTab,
	ChallengesTab,
	LeaderboardsTab,
	AchievementsTab,
	GiftingTab,	
} ActivatePullTabUiType;



@interface AppController (Crystal) <CrystalSessionDelegate, CrystalPlayerDelegate, CrystalVirtualGoodsDelegate, CrystalLeaderboardDelegate>

- (void) clearCommandChannels;

- (void) cmdActivateUiWithType:(NSString*)type;
- (void) cmdActivateUiAtLeaderboardWithId:(NSString*)leaderboardId;
- (void) cmdDeactivateUi;

- (void) cmdActivatePullTabUiWithType:(NSString*)type fromScreenEdge:(NSString*)screenEdge;
- (void) cmdActivatePullTabUiAtLeaderboardWithId:(NSString*)leaderboardId fromScreenEdge:(NSString*)screenEdge;
- (void) cmdDeactivatePullTabUi;

- (void) cmdPostChallengeResultForLastChallengeWithResult:(NSString*)result withCrystalDialog:(NSString*)doDialog;;
- (void) cmdPostAchievementWithId:(NSString*)idString wasObtained:(NSString*)wasObtained description:(NSString*)description alwaysPopup:(NSString*)alwaysPopup forGameCenterId:(NSString*)gcAchievementId;
- (void) cmdPostLeaderboardResultWithId:(NSString*)idString result:(NSString*)result lowestValFirst:(NSString*)lowestValFirst forGameCenterId:(NSString*)gcLeaderboardId;
- (void) cmdLockToOrientation:(NSString*)orientationString;
- (void) cmdDisplaySplashScreen;
- (void) cmdActivateCrystalSetting:(NSString*)setting value:(NSString*)value;
- (void) cmdAuthenticateLocalPlayer;
- (void) cmdCloseCrystalSession;
- (void) cmdPostAchievementProgressWithId:(NSString*)crystalId gameCenterId:(NSString*)gameCenterId percentageComplete:(NSString*)percentageComplete achievementDescription:(NSString*)achievementDescription;
- (void) cmdWillRotateToInterfaceOrientation:(NSString*)toInterfaceOrientation duration:(NSString*)duration;
- (void) cmdDidRotateFromInterfaceOrientation:(NSString*)fromInterfaceOrientation;
- (void) cmdDownloadLeaderboardDataForID:(NSString*)leaderboardID;
- (void) cmdPostVirtualBalances:(NSString*)balances;
- (void) cmdPostVirtualGoods:(NSString*)goods;
- (void) cmdPostVirtualBalances:(NSString*)balances;
- (void) cmdPostVirtualGoodsAndBalances:(NSString*)goods andBalances:(NSString*)balances;
- (void) cmdSetLockedGoods:(NSString*)lockedGoods;
- (void) cmdCrystalPlayerStartUpdating;
- (void) cmdVirtualGoodsStartUpdating;
- (void) cmdVirtualGoodsUpdateNow;
- (UIDeviceOrientation)orientationFromString:(NSString*)orientationString;

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
	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"CCCommandWithReturn" options:0 context:nil];
	
#ifdef ENABLE_PLAYER_DATA
	
	[[CrystalPlayer sharedInstance] startUpdating];
	[CrystalPlayer sharedInstance].delegate = self;
	
#endif
	
	
#ifdef ENABLE_VIRTUAL_GOODS
	
	[[CrystalVirtualGoods sharedInstance] startUpdating];
	[CrystalVirtualGoods sharedInstance].delegate = self;
	
	// Set the IAP IDs here:
	
	NSSet* iapSet = [NSSet setWithObjects:@"com.clickgamer.crystaltestsnow.100crystals", 
					 @"com.clickgamer.crystaltestsnow.200crystals", @"com.clickgamer.crystaltestsnow.300crystals", nil];
	
	[CrystalSession activateCrystalSetting:CrystalSettingEnableVirtualGoods value:iapSet];
	
#endif
	
	[CrystalLeaderboards sharedInstance].delegate = self;
	[CrystalLeaderboards sharedInstance].categoriesToGet = (CrystalLeaderboardCategories)(CLCTop20 | CLCTop20Friends | CLCRandom20 | CLCCurrentUser);
	
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
	
	// Set a key that will be picked up in the c#
	NSLog(@"[Crystal] crystalUiDeactivated");
	
	[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:KCrystalUiDeactivated];
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
#pragma mark CrystalPlayerDelegate

- (void) crystalPlayerInfoUpdatedWithSuccess:(BOOL)success
{
	// Set a key that will be picked up in the c#
	NSLog(@"[Crystal] crystalPlayerInfoUpdatedWithSuccess %d", success);
	
	if (success)
	{
		CrystalPlayer* player = [CrystalPlayer sharedInstance];
		NSString* playerDataStr = [CrystalSession convertToNSString:player];
		[[NSUserDefaults standardUserDefaults] setObject:playerDataStr forKey:KCrystalPlayerInfoUpdated];		
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:KCrystalPlayerInfoUpdated];
	}
}

#pragma mark - 
#pragma mark CrystalVirtualGoodsDelegate

- (void) crystalVirtualGoodsInfoUpdatedWithSuccess:(BOOL)success
{
	// Set a key that will be picked up in the c#
	NSLog(@"[Crystal] crystalVirtualGoodsInfoUpdatedWithSuccess %d", success);
	if (success)
	{
		CrystalVirtualGoods* virtualGoods = [CrystalVirtualGoods sharedInstance];
		
		NSString* goodsDataStr = [CrystalSession convertToNSString:[virtualGoods goods]];
		NSString* balancesDataStr = [CrystalSession convertToNSString:[virtualGoods balances]];
		
		[[NSUserDefaults standardUserDefaults] setObject:goodsDataStr forKey:KCrystalVirtualGoodsUpdated];
		[[NSUserDefaults standardUserDefaults] setObject:balancesDataStr forKey:KCrystalVirtualBalancesUpdated];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:KCrystalVirtualGoodsUpdated];
		[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:KCrystalVirtualBalancesUpdated];
	}
}


#pragma mark - 
#pragma mark CrystalLeaderboardDelegate

- (void) crystalLeaderboardUpdated:(NSString*)leaderboardId
{
	// Set a key that will be picked up in the c#
	NSLog(@"[Crystal] crystalLeaderboardUpdated %@", leaderboardId);
	
	CrystalLeaderboards* leaderBoard = [CrystalLeaderboards sharedInstance];
	
	NSArray* top20EntriesForLeaderboardID = [leaderBoard top20EntriesForLeaderboardID:leaderboardId];
	NSArray* top20FriendsForLeaderboardID = [leaderBoard top20FriendsForLeaderboardID:leaderboardId];
	NSArray* random20ForLeaderboardID = [leaderBoard random20ForLeaderboardID:leaderboardId];
	NSDictionary* currentUserEntryForLeaderboardID = [leaderBoard currentUserEntryForLeaderboardID:leaderboardId];	
	
	//	Convert JSON to NSString
	NSString* top20EntriesForLeaderboardIDDataStr = [CrystalSession convertToNSString:top20EntriesForLeaderboardID];
	NSString* top20FriendsForLeaderboardIDDataStr = [CrystalSession convertToNSString:top20FriendsForLeaderboardID];
	NSString* random20ForLeaderboardIDDataStr = [CrystalSession convertToNSString:random20ForLeaderboardID];
	NSString* currentUserEntryForLeaderboardIDDataStr = [CrystalSession convertToNSString:currentUserEntryForLeaderboardID];
	
	// Set keys that will be picked up in the c#
	if (top20EntriesForLeaderboardIDDataStr)
	{
		[[NSUserDefaults standardUserDefaults] setObject:top20EntriesForLeaderboardIDDataStr forKey:KCrystalLeaderboardsTop20EntriesForLeaderboardIDUpdated];
	}
	else 
	{
		[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:KCrystalLeaderboardsTop20EntriesForLeaderboardIDUpdated];
	}
	
	if (top20FriendsForLeaderboardIDDataStr)
	{
		[[NSUserDefaults standardUserDefaults] setObject:top20FriendsForLeaderboardIDDataStr forKey:KCrystalLeaderboardsTop20FriendsForLeaderboardIDUpdated];
	}
	else 
	{
		[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:KCrystalLeaderboardsTop20FriendsForLeaderboardIDUpdated];
	}
	
	if (random20ForLeaderboardIDDataStr)
	{
		[[NSUserDefaults standardUserDefaults] setObject:random20ForLeaderboardIDDataStr forKey:KCrystalLeaderboardsRandom20ForLeaderboardIDUpdated];
	}
	else 
	{
		[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:KCrystalLeaderboardsRandom20ForLeaderboardIDUpdated];
	}
	
	if (currentUserEntryForLeaderboardIDDataStr)
	{
		[[NSUserDefaults standardUserDefaults] setObject:currentUserEntryForLeaderboardIDDataStr forKey:KCrystalLeaderboardsCurrentUserEntryForLeaderboardIDUpdated];
	}
	else 
	{
		[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:KCrystalLeaderboardsCurrentUserEntryForLeaderboardIDUpdated];
	}
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context
{
	NSLog(@"[Crystal][observeValueForKeyPath]");
	
	if( [[[NSUserDefaults standardUserDefaults] objectForKey:@"CCCommandWithReturn"] isEqualToString:@"isCrystalPlayerSignedIn"] )
	{
		NSLog(@"[Crystal][observeValueForKeyPath] isCrystalPlayerSignedIn");
		
		// Return a result by setting the key here.
		BOOL isSignedIn = [[CrystalPlayer sharedInstance] isSignedIn];
		if (isSignedIn)
		{
			[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"Result"];
		}
		else
		{
			[[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"Result"];
		}
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
		NSString* commandParam5 = nil;
		int count = [commandParameters count];
		
		if (count > 0) commandParam0 = [commandParameters objectAtIndex:0];
		if (count > 1) commandParam1 = [commandParameters objectAtIndex:1];
		if (count > 2) commandParam2 = [commandParameters objectAtIndex:2];
		if (count > 3) commandParam3 = [commandParameters objectAtIndex:3];
		if (count > 4) commandParam4 = [commandParameters objectAtIndex:4];
		if (count > 5) commandParam5 = [commandParameters objectAtIndex:5];
		
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalCommandChannel];
		
		if (commandParam0 && ([commandParam0 compare:@"ActivateUi"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 2 params on ActivateUi");
			[self cmdActivateUiWithType:commandParam1];
		}
		
		else if( commandParam0 && ([commandParam0 compare:@"ActivateUiAtLeadboardWithId"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 1 params on ActivateUiAtLeaderboardId");
			[self cmdActivateUiAtLeaderboardWithId:commandParam1];			
		}
		
		if (commandParam0 && ([commandParam0 compare:@"DeactivateUi"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 0 param on ActivateUi");
			[self cmdDeactivateUi];
		}
		if (commandParam0 && ([commandParam0 compare:@"ActivatePullTabUi"] == NSOrderedSame))
		{
			NSAssert(count == 3, @"[Crystal] require 2 params on ActivatePulltabUi");
			[self cmdActivatePullTabUiWithType:commandParam1 fromScreenEdge:commandParam2];
		}
		
		else if( commandParam0 && ([commandParam0 compare:@"ActivatePullTabUiAtLeadboardWithId"] == NSOrderedSame))
		{
			NSAssert(count == 3, @"[Crystal] require 2 params on ActivatePullTabUiAtLeaderboardId");
			[self cmdActivatePullTabUiAtLeaderboardWithId:commandParam1 fromScreenEdge:commandParam2];			
		}
		
		if (commandParam0 && ([commandParam0 compare:@"DeactivatePullTabUi"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 0 param on deactivatePullTabUi");
			[self cmdDeactivatePullTabUi];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostChallengeResultForLastChallenge"] == NSOrderedSame))
		{
			NSAssert(count == 3, @"[Crystal] require 2 params on PostChallengeResultForLastChallenge");
			[self cmdPostChallengeResultForLastChallengeWithResult:commandParam1  withCrystalDialog:commandParam2];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostAchievement"] == NSOrderedSame))
		{
			NSAssert(count == 6, @"[Crystal] require 5 params on PostAchievement");
			[self cmdPostAchievementWithId:commandParam1 wasObtained:commandParam2 description:commandParam3 alwaysPopup:commandParam4 forGameCenterId:commandParam5];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostAchievementProgressWithId"] == NSOrderedSame))
		{
			NSAssert(count == 5, @"[Crystal] require 4 params on PostAchievementProgressWithId");
			[self cmdPostAchievementProgressWithId:commandParam1 gameCenterId:commandParam2 percentageComplete:commandParam3 achievementDescription:commandParam4];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostLeaderboardResult"] == NSOrderedSame))
		{
			NSAssert(count == 5, @"[Crystal] require 4 params on PostLeaderboardResult");
			[self cmdPostLeaderboardResultWithId:commandParam1 result:commandParam2 lowestValFirst:commandParam3 forGameCenterId:commandParam4];
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
		
		else if (commandParam0 && ([commandParam0 compare:@"CloseCrystalSession"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 1 param on CloseCrystalSession");
			[self cmdCloseCrystalSession];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"WillRotateToInterfaceWithOrientation"] == NSOrderedSame))
		{
			NSAssert(count == 3, @"[Crystal] require 2 params on WillRotateToInterfaceWithOrientation");
			[self cmdWillRotateToInterfaceOrientation:commandParam1 duration:commandParam2];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"DidRotateFromInterfaceOrientation"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 1 param on DidRotateFromInterfaceOrientation");
			[self cmdDidRotateFromInterfaceOrientation:commandParam1];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"DownloadLeaderboardDataForID"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 1 param on DownloadLeaderboardDataForID");
			[self cmdDownloadLeaderboardDataForID:commandParam1];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostVirtualBalances"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 1 param on PostVirtualBalances");
			[self cmdPostVirtualBalances:commandParam1];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"PostVirtualGoods"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 1 param on PostVirtualGoods");
			[self cmdPostVirtualGoods:commandParam1];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"SetLockedGoods"] == NSOrderedSame))
		{
			NSAssert(count == 2, @"[Crystal] require 1 params on SetLockedGoods");
			[self cmdSetLockedGoods:commandParam1];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"CrystalPlayerStartUpdating"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 0 param on CrystalPlayerStartUpdating");
			[self cmdCrystalPlayerStartUpdating];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"VirtualGoodsStartUpdating"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 0 param on VirtualGoodsStartUpdating");
			[self cmdVirtualGoodsStartUpdating];
		}
		
		else if (commandParam0 && ([commandParam0 compare:@"VirtualGoodsUpdateNow"] == NSOrderedSame))
		{
			NSAssert(count == 1, @"[Crystal] require 0 param on VirtualGoodsUpdateNow");
			[self cmdVirtualGoodsUpdateNow];
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
			
		case ProfileUi:
			[CrystalSession activateCrystalUIAtProfile];
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
			
		case AddFriends:
			[CrystalSession activateCrystalUIAtAddFriends];
			break;
			
		case Settings:
			[CrystalSession activateCrystalUIAtSettings];
			break;
			
		case Gifting:
			[CrystalSession activateCrystalUIAtGifting];
			break;
			
		case VirtualGoods:
			[CrystalSession activateCrystalUIAtVirtualGoods];
			break;
			
		case VirtualCurrencies:
			[CrystalSession activateCrystalUIAtVirtualCurrencies];
			break;
			
		default:
			NSAssert(NO, @"[Crystal] unsupported UI type in cmdActivateUiWithType");
			break;
	}
}

- (void) cmdActivateUiAtLeaderboardWithId:(NSString*)leaderboardId
{
	NSLog(@"[Crystal] ActivateUiAtLeaderboardWithId %@", leaderboardId);
	
	//UnitySetAudioSessionActive(false);
	//UnityPause(true);
	
	[CrystalSession activateCrystalUIAtLeaderboardWithId:leaderboardId];
}

- (void) cmdDeactivateUi
{
	NSLog(@"[Crystal] DeactivateUi");
	[CrystalSession deactivateCrystalUI];
}


- (void) cmdActivatePullTabUiWithType:(NSString*)type fromScreenEdge:(NSString*)edgeString
{
	ActivatePullTabUiType uiType = (ActivatePullTabUiType)[type intValue];
	
	// If you're running on iPhone only you might want to completely pause Unity while Crystal is running
	// It's always best to handle this yourself though as when paused Unity won't handle screen rotations
	// UnitySetAudioSessionActive(false);
	// UnityPause(true);
	
	switch (uiType) {
		case NewsTab:
			[CrystalSession activateCrystalPullTabOnNewsFromScreenEdge:edgeString];
			break;
			
		case ChallengesTab:
			[CrystalSession activateCrystalPullTabOnChallengesFromScreenEdge:edgeString];
			break;
			
		case LeaderboardsTab:
			[CrystalSession activateCrystalPullTabOnLeaderboardsFromScreenEdge:edgeString];
			break;
			
		case AchievementsTab:
			[CrystalSession activateCrystalPullTabOnAchievementsFromScreenEdge:edgeString];
			break;
			
		case GiftingTab:
			[CrystalSession activateCrystalPullTabOnGiftsFromScreenEdge:edgeString];
			break;
						
		default:
			NSAssert(NO, @"[Crystal] unsupported UI type in cmdActivatePullTabUiWithType");
			break;
	}
}

- (void) cmdActivatePullTabUiAtLeaderboardWithId:(NSString*)leaderboardId fromScreenEdge:(NSString*)edgeString
{
	NSLog(@"[Crystal] ActivatePullTabUiAtLeaderboardWithId %@", leaderboardId);
	
	//UnitySetAudioSessionActive(false);
	//UnityPause(true);
	
	[CrystalSession activateCrystalPullTabOnLeaderboardWithId:leaderboardId fromScreenEdge:edgeString];
}

- (void) cmdDeactivatePullTabUi
{
	NSLog(@"[Crystal] DeactivatePullTab");
	[CrystalSession deactivateCrystalPullTab];
}



- (void) cmdPostChallengeResultForLastChallengeWithResult:(NSString*)result withCrystalDialog:(NSString*)doDialog
{
	float resultFloat = [result floatValue];
	bool doDialogBool = [doDialog boolValue];
	NSLog(@"[Crystal] PostChallengeResultForLastChallengeWithResult %f %d", resultFloat, doDialogBool);
	
	[CrystalSession postChallengeResultForLastChallenge:resultFloat withCrystalDialog:doDialogBool];
}


- (void) cmdPostAchievementWithId:(NSString*)idString wasObtained:(NSString*)wasObtained description:(NSString*)description alwaysPopup:(NSString*)alwaysPopup forGameCenterId:(NSString*)gcAchievementId
{
	BOOL obtainedBool = [wasObtained boolValue];
	BOOL alwaysPopupBool = [alwaysPopup boolValue];
	NSLog(@"[Crystal] PostAchievementWithId %@ obtained %d desc %@ alwaysPopup %d Game Center ID %@", idString, wasObtained, description, alwaysPopup, gcAchievementId);
	
	if (_gameCenterEnabled)
		[CrystalSession postAchievement:idString wasObtained:obtainedBool withDescription:description alwaysPopup:alwaysPopupBool forGameCenterAchievementId:gcAchievementId];
	else
		[CrystalSession postAchievement:idString wasObtained:obtainedBool withDescription:description alwaysPopup:alwaysPopupBool];
}

- (void) cmdPostLeaderboardResultWithId:(NSString*)idString result:(NSString*)result lowestValFirst:(NSString*)lowestValFirst forGameCenterId:(NSString*)gcLeaderboardId
{
	float resultFloat = [result floatValue];
	BOOL lowestValBool = [lowestValFirst boolValue];
	NSLog(@"[Crystal] PostLeaderboardResultWithId %@ result %f lowestvalue %d Game Center ID %@", idString, resultFloat, lowestValFirst, gcLeaderboardId);
	
	if (_gameCenterEnabled)
		[CrystalSession postLeaderboardResult:resultFloat forLeaderboardId:idString lowestValFirst:lowestValBool forGameCenterLeaderboardId:gcLeaderboardId];
	else
		[CrystalSession postLeaderboardResult:resultFloat forLeaderboardId:idString lowestValFirst:lowestValBool];
}

- (void) cmdPostAchievementProgressWithId:(NSString*)crystalId gameCenterId:(NSString*)gameCenterId percentageComplete:(NSString*)percentageComplete achievementDescription:(NSString*)achievementDescription;
{
	double percentageCompleteDouble = [percentageComplete doubleValue];
	NSLog(@"[Crystal] PostAchievementProgressWithId %@][gameCenterId %@][percentageComplete %f][achievementDescription %@]", crystalId, gameCenterId, percentageCompleteDouble, achievementDescription);
	[CrystalSession postAchievementProgressWithCrystalId:crystalId gameCenterId:gameCenterId percentageComplete:percentageCompleteDouble achievementDescription:achievementDescription];
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
	else if (orientationString && ([orientationString compare:@"portraitUpsideDown"] == NSOrderedSame))
	{
		[CrystalSession lockToOrientation:UIDeviceOrientationPortraitUpsideDown];
	}
}


- (void) cmdDisplaySplashScreen
{
	NSLog(@"[Crystal] displaySplashScreen");
	[CrystalSession displaySplashScreen];
}


- (void) cmdActivateCrystalSetting:(NSString*)setting value:(NSString*)value
{
	int intSetting = [setting intValue];
	
	[CrystalSession activateCrystalSetting:(CrystalSetting)intSetting value:value];
	
	if ((intSetting == CrystalSettingEnableGameCenterSupport) && 
		([value compare:@"YES"] == NSOrderedSame))
	{
		NSLog(@"[Crystal] Game Center Enabled");
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
	NSLog(@"[Crystal] authenticateLocalPlayer");
	
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

- (void) cmdCloseCrystalSession
{
	NSLog(@"[Crystal] closeCrystalSession");
	[CrystalSession closeCrystalSession];
}


- (void) cmdWillRotateToInterfaceOrientation:(NSString*)toInterfaceOrientation duration:(NSString*)duration;
{
	UIDeviceOrientation orientation = [self orientationFromString:toInterfaceOrientation];
	NSTimeInterval durationTimeInterval = [duration doubleValue];
	
	NSLog(@"[Crystal] willRotateToInterfaceOrientation: [to %d][duration %f]", orientation, durationTimeInterval);
	[CrystalSession willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:durationTimeInterval];
}

- (void) cmdDidRotateFromInterfaceOrientation:(NSString*)fromInterfaceOrientation;
{
	UIDeviceOrientation orientation = [self orientationFromString:fromInterfaceOrientation];
	NSLog(@"[Crystal] didRotateFromInterfaceOrientation: [orientation %d]", orientation);
	[CrystalSession didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation];
}

- (void) cmdDownloadLeaderboardDataForID:(NSString*)leaderboardID
{
	NSLog(@"[Crystal] DownloadLeaderboardDataForID: [leaderboardID %@]", leaderboardID);
	
	if (leaderboardID != nil)
	{
		[[CrystalLeaderboards sharedInstance] downloadLeaderboardDataForID:leaderboardID];
	}
}

- (void) cmdPostVirtualGoods:(NSString*)goods
{
#ifdef ENABLE_VIRTUAL_GOODS	
	NSLog(@"[Crystal] PostVirtualGoods]");
	
	[self cmdPostVirtualGoodsAndBalances:goods andBalances:nil];
#endif
}

- (void) cmdPostVirtualBalances:(NSString*)balances
{
#ifdef ENABLE_VIRTUAL_GOODS	
	NSLog(@"[Crystal] PostVirtualBalances]");
	
	[self cmdPostVirtualGoodsAndBalances:nil andBalances:balances];
#endif
}

- (void) cmdPostVirtualGoodsAndBalances:(NSString*)goods andBalances:(NSString*)balances
{
#ifdef ENABLE_VIRTUAL_GOODS	
	NSLog(@"[Crystal] PostVirtualGoodsAndBalances]");
	
	NSDictionary* goodsDictionary = nil;
	NSDictionary* balancesDictionary = nil;	
	
	if (goods)
	{
		goodsDictionary = [CrystalSession convertDataStringToObject:goods];
		[[CrystalVirtualGoods sharedInstance] postGoods:goodsDictionary];
	}
	
	if (balances)
	{
		balancesDictionary = [CrystalSession convertDataStringToObject:balances];
		[[CrystalVirtualGoods sharedInstance] postBalances:balancesDictionary];
	}
#endif	
}


- (void) cmdSetLockedGoods:(NSString*)lockedGoods;
{
#ifdef ENABLE_VIRTUAL_GOODS	
	NSLog(@"[Crystal] SetLockedGoods]");
	
	NSArray* arr = nil;
	if (lockedGoods.length != 0)
	{
		arr = [CrystalSession convertDataStringToObject:lockedGoods];
	}
	
	NSMutableSet* set = [NSMutableSet setWithArray:arr];	
	[[CrystalVirtualGoods sharedInstance] setLockedGoods:set];
#endif
}

- (void) cmdCrystalPlayerStartUpdating
{	
	NSLog(@"[Crystal] CrystalPlayer StartUpdating");
	[[CrystalPlayer sharedInstance] startUpdating];
	[CrystalPlayer sharedInstance].delegate = self;
}

- (void) cmdVirtualGoodsStartUpdating
{
	NSLog(@"[Crystal] CrystalVirtualGoods StartUpdating");
	[[CrystalVirtualGoods sharedInstance] startUpdating];
	[CrystalPlayer sharedInstance].delegate = self;
}

- (void) cmdVirtualGoodsUpdateNow
{
	NSLog(@"[Crystal] CrystalVirtualGoods UpdateNow");
	[[CrystalVirtualGoods sharedInstance] updateNow];
}

- (void) clearCommandChannels
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalCommandChannel];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalChallengeNotificationChannel];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalAppStartedFromChallenge];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalUiDeactivated];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalPlayerInfoUpdated];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalVirtualGoodsUpdated];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalVirtualBalancesUpdated];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalLeaderboardsTop20EntriesForLeaderboardIDUpdated];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalLeaderboardsTop20FriendsForLeaderboardIDUpdated];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalLeaderboardsRandom20ForLeaderboardIDUpdated];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:KCrystalLeaderboardsCurrentUserEntryForLeaderboardIDUpdated];
}

#pragma mark - 
#pragma mark Helpers

- (UIDeviceOrientation)orientationFromString:(NSString*)orientationString
{
	UIDeviceOrientation orientation;
	
	if (orientationString && ([orientationString compare:@"portrait"] == NSOrderedSame))
	{
		orientation = UIDeviceOrientationPortrait;
	}
	else if (orientationString && ([orientationString compare:@"landscapeLeft"] == NSOrderedSame))
	{
		orientation = UIDeviceOrientationLandscapeLeft;
	}
	else if (orientationString && ([orientationString compare:@"landscapeRight"] == NSOrderedSame))
	{
		orientation = UIDeviceOrientationLandscapeRight;
	}
	else if (orientationString && ([orientationString compare:@"portraitUpsideDown"] == NSOrderedSame))
	{
		orientation = UIDeviceOrientationPortraitUpsideDown;
	}
	
	return orientation;
}

@end
