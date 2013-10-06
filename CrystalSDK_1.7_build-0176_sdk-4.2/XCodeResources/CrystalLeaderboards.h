//
//  CrystalLeaderboards.h
//  Crystal
//
//  Created by Gareth Reese on 16/04/2010.
//  Copyright 2010 Chillingo Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @brief The data categories available to clients of CrystalLeaderboards
 * This is used in the categoriesToGet property of CrystalLeaderboards and specifies which data will be requested from the server for each leaderboard.
 * Metadata for the leaderboard will always be retrieved.
 */
typedef enum
{
	CLCTop20			= 0x1,		///< Get via top20EntriesForLeaderboardID:
	CLCTop20Friends		= 0x2,		///< Get via top20FriendsForLeaderboardID:
	CLCRandom20			= 0x4,		///< Get via random20ForLeaderboardID:
	CLCCurrentUser		= 0x8,		///< Get via currentUserDataForLeaderboardID:
} CrystalLeaderboardCategories;
 

@protocol CrystalLeaderboardDelegate <NSObject>
@required
/**
 * @brief Reports to the client that a leaderboard has been updated
 * @param leaderboardId The leaderboard ID that has been updated. This will match the leaderboard ID on the Developer Dashboard
 */
- (void) crystalLeaderboardUpdated:(NSString*)leaderboardId;

@end

/**
 * @brief The Crystal interface to the Crystal direct leaderboard access API.
 * THIS IS AN API PREVIEW AND NOT FUNCTIONAL AT THIS TIME.
 * The categoriesToGet proporty must be consistent throughout the lifetime of this class, i.e. the same data must be retrieved for each of the leaderboards.
 * This allows the Crystal SDK to cache the data more consistently and eases the use of the APIs.
 * The categoriesToGet property must also be set before calling downloadLeaderboardDataForID:
 */
@interface CrystalLeaderboards : NSObject 
{
@public
	CrystalLeaderboardCategories categoriesToGet;	///< @see CrystalLeaderboardCategories for details. Must be set before calling downloadLeaderboardDataForID:.
	id<CrystalLeaderboardDelegate> delegate;		///< @see CrystalLeaderboardDelegate. Set this to get notifications for downloaded leaderboard data via crystalLeaderboardUpdated:.
}

@property (nonatomic)								CrystalLeaderboardCategories categoriesToGet;
@property (nonatomic, assign, setter=setDelegate:)	id<CrystalLeaderboardDelegate> delegate;


/**
 * @defgroup get Geting an array of leaderboard entries
 * @defgroup query Accessing leaderboard data
 */

/**
 * @brief Returns the shared singleton instance of CrystalLeaderboards
 */
+ (CrystalLeaderboards*) sharedInstance;

/**
 * @ingroup get
 * @brief Initiate the download of leaderboard data for the supplied leaderboard ID
 * If the leaderboard data for the specified leaderboardID is already downloaded for this game session the data will not be updated from the server to avoid excessive server load.
 * When the leaderboard data has been downloaded the crystalLeaderboardUpdated: method will be called on CrystalLeaderboardDelegate.
 * There is no indication of an error while downloading the leaderboard data and there is no need to manually retry the process.
 */
- (void) downloadLeaderboardDataForID:(NSString*)leaderboardID;


//////////////////////////////////////////////////////////////////////////////////////
// Get an array of leaderboard entries

/**
 * @ingroup get
 * @brief Retrieve the top 20 entries for the specified leaderboard
 * @return An array of leaderboard entries or nil if the leaderboard data is not available
 */
- (NSArray*) top20EntriesForLeaderboardID:(NSString*)leaderboardID;

/**
 * @ingroup get
 * @brief Retrieve the top 20 friends for the specified leaderboard, including the current user
 * @return An array of leaderboard entries or nil if the leaderboard data is not available
 */
- (NSArray*) top20FriendsForLeaderboardID:(NSString*)leaderboardID;

/**
 * @ingroup get
 * @brief Retrieve a random selection of 20 entries for the specified leaderboard
 * @return An array of leaderboard entries or nil if the leaderboard data is not available
 */
- (NSArray*) random20ForLeaderboardID:(NSString*)leaderboardID;

/**
 * @ingroup get
 * @brief Retrieve the data for the current user for the specified leaderboard
 * @return An array of leaderboard entries or nil if the leaderboard data is not available
 */
- (NSDictionary*) currentUserEntryForLeaderboardID:(NSString*)leaderboardID;


//////////////////////////////////////////////////////////////////////////////////////
// Accessing leaderboard entry data

/**
 * @ingroup query
 * @brief Get the username from a leaderboard entry.
 * @return The username or nil if no username available
 */
- (NSString*) usernameForLeaderboardEntry:(NSDictionary*)leaderboardEntry;

/**
 * @ingroup query
 * @brief Get the position of a leaderboard entry.
 * This is a convenience method to extract data from the array items returned from top20EntriesForLeaderboardID: et al
 * @return -1 if the position is not available (for instance for random entries)
 */
- (int) positionForLeaderboardEntry:(NSDictionary*)leaderboardEntry;

/**
 * @ingroup query
 * @brief Returns the score for the supplied entry as a numeric value
 * This is a convenience method to extract data from the array items returned from top20EntriesForLeaderboardID: et al
 * Note that you should use timeForLeaderboardEntry: for time-based scores
 * @return The leaderboard score
 */
- (double) scoreForLeaderboardEntry:(NSDictionary*)leaderboardEntry;

/**
 * @ingroup query
 * @brief Returns the score of the supplied entry as a time-based value
 * This is a convenience method to extract data from the array items returned from top20EntriesForLeaderboardID: et al
 * Note that you should use scoreForLeaderboardEntry: for numeric scores
 * @return the leaderboard time value
 */
- (NSTimeInterval) timeForLeaderboardEntry:(NSDictionary*)leaderboardEntry;

@end
