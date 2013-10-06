//
//  CrystalSession+PullTab.h
//  Crystal
//
//  Created by Duane Bradbury on 13/01/2011.
//  Copyright 2011 Chillingo Ltd. All rights reserved.
//

#import "CrystalSession.h"

/**
 * @brief The interface to all of the Crystal pull tab functionality.
 * The pull tab can be activated on any screen edge ("right", "left", "top", "bottom") but please ensure the theme has been updated to support 
 * the appropriate screen edge(s) to be used.
 * The pull tab UI is generally functional but not yet supported on the iPad. If you wish to use the pull tabs on the ipad consider the standard UI with popovers
 * or contact devsupport@crystalsdk.com for more information and advice.
 */
@interface CrystalSession (PullTab)


/**
 * @brief Activates the Crystal pull tab user interface on the 'News' screen.  
 * This is a basic news feed that features adverts and three modes of display.
 * @ingroup ui
 * @param edgeString The edge to display the pull tab interface from, one of "right", "left", "top" or "bottom"
 */
+ (void) activateCrystalPullTabOnNewsFromScreenEdge:(NSString*)edgeString;


/**
 * @brief Activates the Crystal pull tab user interface on the 'News' screen in the specified closed state.  
 * This is a basic news feed that features adverts and three modes of display.
 * @ingroup ui
 * @param edgeString The edge to display the pull tab interface from, one of "right", "left", "top" or "bottom"
 * @param closed Whether the news feed is initially closed or not
 */
+ (void) activateCrystalPullTabOnNewsFromScreenEdge:(NSString*)edgeString closed:(BOOL)closedState;


/**
 * @brief Activates the Crystal pull tab user interface on the 'Leaderboards' screen
 * @ingroup ui
 * @param edgeString The edge to display the pull tab interface from, one of "right", "left", "top" or "bottom"
 */
+ (void) activateCrystalPullTabOnLeaderboardsFromScreenEdge:(NSString*)edgeString;

/**
 * @brief Activates the Crystal pull tab user interface with a specific leaderboard to be displayed
 * @ingroup ui
 * @param leaderboardId The Id of the leaderboard to be displayed
 * @param edgeString The edge to display the pull tab interface from, one of "right", "left", "top" or "bottom"
 */
+ (void) activateCrystalPullTabOnLeaderboardWithId:(NSString*)leaderboardId fromScreenEdge:(NSString*)edgeString;

/**
 * @brief Activates the Crystal pull tab user interface on the 'Gifting' screen
 * @ingroup ui
 */
+ (void) activateCrystalPullTabOnGiftsFromScreenEdge:(NSString*)edgeString;

/**
 * @brief Activates the Crystal pull tab user interface on the 'challenges' screen
 * @ingroup ui
 */
+ (void) activateCrystalPullTabOnChallengesFromScreenEdge:(NSString*)edgeString;


/**
 * @brief Activates the Crystal pull tab user interface on the 'achievements' screen
 * @ingroup ui
 */
+ (void) activateCrystalPullTabOnAchievementsFromScreenEdge:(NSString*)edgeString;



/**
 * @brief Deactivates the Crystal pull tab user interface.  This will animate the pull tab off screen.
 * @ingroup ui
 */
+ (void) deactivateCrystalPullTab;


@end
