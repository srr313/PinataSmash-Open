//
//  CrystalAchievements.h
//  Crystal
//
//  Created by willeeh on 18/01/2011.
//  Copyright 2011 Chillingo Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CrystalAchievementDelegate <NSObject>
@required
/**
 * @brief Reports to the client that achievements has been updated
 */
- (void) crystalAchievementsUpdated;

@end

/**
 * @brief The Crystal interface to the Crystal direct achievement access API.
 */
@interface CrystalAchievements : NSObject 
{
@public
	id<CrystalAchievementDelegate> delegate;		/// Set this to get notifications for downloaded achievement data via crystalAchievementUpdated:.
}

@property (nonatomic, assign)	id<CrystalAchievementDelegate> delegate;


/**
 * @defgroup get Getting an array of achievements unlocked
 * @defgroup query Accessing achievement data
 */

/**
 * @brief Returns the shared singleton instance of CrystalLeaderboards
 */
+ (CrystalAchievements*) sharedInstance;

/**
 * @ingroup get
 * @brief Retrieve the achievements unlocked, including the current user
 * @return An array of achievements ID or nil if the achievement data is not available
 */
- (NSArray*) getAchievementsUnlocked;


@end
