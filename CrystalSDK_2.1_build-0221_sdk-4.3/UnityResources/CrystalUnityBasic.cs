/*
 *  CrystalUnityBasic.cs
 *
 *  Created by Gareth Reese
 *  Copyright 2009 Chillingo Ltd. All rights reserved.
 *
 */


using System;
using System.Collections;
using System.Collections.Generic;

using UnityEngine; 

using Procurios.Public;

/**
 * @brief Class describing the CrystalPlayer
 */
public class CrystalPlayer
{
	/// set to true if the user has signed into Crystal	
	public bool isCrystaluser;
	
	/// Returns true if the user has signed into Crystal and entered their Facebook details
	public bool isFacebookUser;
	
	/// Returns YES if the user has signed into Crystal and entered their Twitter details
	public bool isTwitterUser;
	
	/// The number of friends this user has	
	public int numCrystalFriends;
	
	/// The number of friends this user has that also own the game	
	public int numCrystalFriendsWithGame;
	
	/// An array of string IDs for each of the gifts owned by the user, or null if the user doesn't have any gifts	
	public IList<int> gifts;
	
	/// The player's current alias in Crystal	
	public string alias;
	
	/// The badge number that Crystal will set for the application icon and that can be shown over the Crystal button in-game.
	/// If you don't want to go to the effort of implementing the badges a >0 value can be used to highlight the Crystal button somehow.
	/// The badge number will indicate that the user has outstanding gifts, friend requests or challenges.	
	public int badgeNumber;
	
	/// An array of string IDs for each friend of the user, or nil if the user doesn't have any friends
	public IList<string> crystalfriendIds;
	
	
	///	Unique identifier for player
	public string crystalPlayerId;
}

/**
 * @brief Class describing an entry in a Leaderboard
 *
 */
public class LeaderboardEntry
{
	public string username;
	public string position;
	public double score;	
}

/**
 * @brief The interface to all of the Crystal SDK functionality.
 */
public class CrystalUnityBasic : MonoBehaviour 
{
	public string iLastIncomingChallenge = "";
	public string iStartedFromChallenge = "";
	public bool iPopoversActivated = false;
	public bool iVirtualGoodsUpdated = false;
	public bool iPlayerInfoUpdated = false;
	public string iPlayerInfoUpdate = "";
	public string iLastLeaderboardUpdateId = "";
	private static CrystalUnityBasic _singleton = null;

	private CrystalPlayer iPlayer = null;
	private IDictionary<string, int> iVirtualGoods = null;
	private IDictionary<string, int> iVirtualBalances = null;
	private IList<string> iAchievements = null;	
	private CrystalLeaderboardType iLeaderboardType;
	private IList<LeaderboardEntry> iTop20EntriesForLeaderboard = null;
	private IList<LeaderboardEntry> iTop20FriendsForLeaderboard = null;
	private IList<LeaderboardEntry> iRandom20ForLeaderboard = null;
	private LeaderboardEntry iCurrentUserEntryForLeaderboard = new LeaderboardEntry();
	
	private DeviceOrientation iDeviceOrientation = DeviceOrientation.Unknown;
		
	/**
	 * @brief Get hold of the singleton instance
	 */	
	public static CrystalUnityBasic Instance
	{ 
        get {
            if (_singleton == null)
            {
                Debug.Log("CrystalUnityBasic : instantiate");
                GameObject go = new GameObject();
                _singleton = go.AddComponent<CrystalUnityBasic>();
                go.name = "singleton";
            }

            return _singleton; 
        } 
    } 
    
    
    private bool isOkToRun()
    {
	if ( (Application.platform == RuntimePlatform.IPhonePlayer) && !Application.isEditor )
		return true;
	else		
		return false;
    }
	
	/**
	 * @brief The section (tab) of the Crystal UI to display to the user by default
	 */
	public enum ActivateUiType
	{
		StandardUi,			///< Opens up the Crystal UI at the default tab on iPhone and without and popovers open on iPad
		ProfileUi,			///< Opens up the Profile tab
		ChallengesUi,		///< Opens up the Challenges tab
		LeaderboardsUi,		///< Opens up the Leaderboards tab
		AchievementsUi,		///< Opens up the Achievements tab
		AddFriends,			///< Opens up the AddFriends tab
		Settings,			///< Opens up the Settings tab
		Gifting,			///< Opens up the Gifts and Promotions tab
		VirtualGoods,		///< Opens up the Virtual Goods tab
		VirtualCurrencies,	///< Opens up the Virtual Currencies tab
		FindFriends,		///< Opens up the Find Friends tab
		InviteFriends,		///< Opens up the Invite Friends tab
		GiftsAndMarket		///< Opens up the Gifts and Market tab
	}

	private enum LeaderboardType
	{
		Top20Entries,
		Top20Friends,
		Random20
	}

	public enum ActivatePullTabUiType
	{
		Profile,			///< Opens up the Profile tab
		Challenges,			///< Opens up the Challenges tab
		Leaderboards,		///< Opens up the Leaderboards tab
		Achievements,		///< Opens up the Achievements tab
		Friends,			///< Opens up the Friends tab
		Settings,			///< Opens up the Settings tab
		Gifting,			///< Opens up the Gifting tab
		VirtualGoods,		///< Opens up the VirtualGoods tab
		VirtualCurrencies,	///< Opens up the VirtualCurrencies tab
		FindFriends,		///< Opens up the FindFriends tab
		GiftsAndMarket,		///< Opens up the GiftsAndMarket tab
		News,				///< Opens up the news inbox tab
	}	
	
	/**
 	* @brief The leaderboard types available for request in CrystalLeaderboards
 	* By default the CLTGlobal leaderboard type is assumed, and this is the leaderboard type requested before this API was introduced.
 	* The Crystal back-end will only generate leaderboards that are configured through the developer dashboard, so attempting to request a leaderboard type
 	* for a leaderboard ID that does not have the type configured will return no data.
 	*/
	public enum CrystalLeaderboardType
	{
		CLTGlobal,			///< The standard 'all time' global leaderboard
		CLTNational,		///< The national 'all time' leaderboard for the current user's configured location
		CLTLocal,			///< The local 'all time' leaderboard for the current user's configured location
		CLTThisMonth,		///< This month's leaderboard
		CLTLastMonth,		///< The previous month's leaderboard
		CLTThisWeek,		///< This week's leaderboard
		CLTLastWeek,		///< The previous week's leaderboard
		CLTToday,			///< Today's leaderboard
		CLTYesterday,		///< The previous day's leaderboard
	}
	
	/**
	 * @brief Crystal settings that enable workaround functionality within the system.
	 * You should only enable these settings if you're seeing a specific problem that you think may be resolved by one of these options.
	 * In general you will be instructed to use one of these settings by an FAQ article or directly by the Crystal SDK support team.
	 */
	public enum CrystalSetting
	{
		/** @brief Activate the CrystalSettingCocosAchievementWorkaround setting if you're seeing a vertical bar instead of the achievement popup.
		 *  value:"YES" activates the setting
		 */
		CrystalSettingCocosAchievementWorkaround = 1,
		
		/** @brief Activate the CrystalSettingAvoidBackgroundActivity setting if you're seeing occasional slowdowns during high-CPU activity.
		 *  This setting is intended to be used sparingly during 3D cut scenes and similar and will affect achievement posting etc.
		 *  The setting should be returned to the NO state as soon as possible and the NO state should be the game's default.
		 *  No user data should be lost while the setting is set to NO however.
		 *  value:"YES" - Crystal will avoid any background processing or network activity.
		 *  value:"NO"  - Return Crystal to its default state.
		 */
		CrystalSettingAvoidBackgroundActivity = 2,
		
		/** @brief Activate this setting for framework crashes in [UIWindow _shouldAutorotateToInterfaceOrientation:].
		 *  You'll most commonly see this problem while rotating the device in projects with no UIViewController instance
		 *  such as purely OpenGL-based games.
		 *  value:"YES" activates this setting
		 */
		CrystalSettingShouldAutorotateWorkaround = 3,
		
		/** 
		 *  @brief Activate this setting to restrict Crystal on iPad to one popover, rather than the hierarchical popover method.
		 *  The hierarchical popoevers are more visually appealing but ma contradict some recent Apple Human Interface Guideline changes.
		 *  value:"YES" activates this setting
		 */
		CrystalSettingSingleiPadPopover = 4,


		/** 
		 *  @brief Activate this setting to enable the Game Center support within Crystal.
		 *  This setting can be called as a result of an enable/disable Game Center switch in the game UI if desired.
		 *  value:"YES" activates this setting
		 */
		CrystalSettingEnableGameCenterSupport = 5,
		
	}
	
	public void Start()
	{
		// 	Used for initialistation
	}
	
	
	public void Update()
	{
		// Called every frame so we need to make sure that we only check what we need to to ensure good performance
		// If you're not using challenges then you can comment out the CCChallengeNotification & CCStartedFromChallenge code below
		// If you're not using the popoversActivated property you can comment out the CCStartedFromChallenge code
		// If you're not using VirtualGoods/VirtualBalances then you can comment out the CCVirtualGoodsUpdated/CCVirtualBalancesUpdated code
		// If you're not using Leaderboards then you can comment out the CCTop20EntriesForLeaderboardIDUpdated code etc.
		
		if (Time.frameCount % 30 == 0)
		{
			string incomingChallenge = PlayerPrefs.GetString("CCChallengeNotification");
			if (incomingChallenge != "")
			{
				iLastIncomingChallenge = incomingChallenge;
				PlayerPrefs.SetString("CCChallengeNotification", "");
				
				//////////////////////////////////////////////////////////////////////////////
				// The user has started a challenge from the Crystal UI
				//
				// Call your incoming challenge handler script here or check 
				// the incomingChallenge attribute for an ID every so often
				//////////////////////////////////////////////////////////////////////////////
			}


			string uiDeactivatedString = PlayerPrefs.GetString("CCUIDeactivated");
			
			if (uiDeactivatedString != "")
			{
				Debug.Log("> CrystalUnity_Basic UI Deactivated");				
				PlayerPrefs.SetString("CCUIDeactivated", "");
				//////////////////////////////////////////////////////////////////////////////
				// The Crystal UI has been deactivated
				//
				// Call your UI Deactivated handler script here
				//////////////////////////////////////////////////////////////////////////////							
			}
			
			string incomingAchievements = PlayerPrefs.GetString("CCAchievementsUpdated");
			
			if (incomingAchievements != "")
			{
				Debug.Log("> CrystalUnity_Basic Achievments activated " + incomingAchievements);
				PopulateAchievements(incomingAchievements);
				PlayerPrefs.SetString("CCAchievementsUpdated", "");
				
				//////////////////////////////////////////////////////////////////////////////
				// Achievements have been updated
				//
				// Call your Achievements updated handler script here or check 
				// the CurrentAchievements property every so often
				//////////////////////////////////////////////////////////////////////////////								
			}			
		}

		else if (Time.frameCount % 30 == 5)	
		{
			string incomingVirtualGoods = PlayerPrefs.GetString("CCVirtualGoodsUpdated");
			string incomingVirtualBalances = PlayerPrefs.GetString("CCVirtualBalancesUpdated");
		
			if (incomingVirtualGoods != "")
			{
				Debug.Log("> CrystalUnity_Basic virtualgoods [goods] activated " + incomingVirtualGoods);
				PopulateVirtualGoods(incomingVirtualGoods);
				PlayerPrefs.SetString("CCVirtualGoodsUpdated", "");
				
				//////////////////////////////////////////////////////////////////////////////
				// Virtual Goods have been updated
				//
				// Call your virtual goods updated handler script here or check 
				// the CurrentVirtualGoods property every so often
				//////////////////////////////////////////////////////////////////////////////				
			}
			
			if (incomingVirtualBalances != "")
			{
				Debug.Log("> CrystalUnity_Basic virtualgoods [balances] activated " + incomingVirtualBalances);
				PopulateVirtualBalances(incomingVirtualBalances);
				PlayerPrefs.SetString("CCVirtualBalancesUpdated", "");
				
				//////////////////////////////////////////////////////////////////////////////
				// Virtual Balances have been updated
				//
				// Call your virtual balances updated handler script here or check 
				// the CurrentVirtualBalances property every so often
				//////////////////////////////////////////////////////////////////////////////								
			}
		}		
		
		else if (Time.frameCount % 30 == 10)	
		{
			if (iStartedFromChallenge == "")
				iStartedFromChallenge = PlayerPrefs.GetString("CCStartedFromChallenge");
				
			if (iStartedFromChallenge != "")
			{
				//////////////////////////////////////////////////////////////////////////////
				// The game was started from a push notification, with the intention
				// of playing a challenge
				//
				// Call your challenge handler script here or check 
				// the incomingChallenge attribute for an ID every so often
				//////////////////////////////////////////////////////////////////////////////
			}
		}

		if (Time.frameCount % 30 == 15)
		{
			string incomingPlayerInfo = PlayerPrefs.GetString("CCPlayerInfoUpdated");
			if (incomingPlayerInfo != "")
			{
				Debug.Log("> CrystalUnity_Basic player info activated " + incomingPlayerInfo);
				PopulateCrystalPlayer(incomingPlayerInfo);
				PlayerPrefs.SetString("CCPlayerInfoUpdated", "");
				
				//////////////////////////////////////////////////////////////////////////////
				// Crystal Player has been updated
				//
				// Call your Crystal Player updated handler script here or check 
				// the CurrentCrystalPlayer property every so often
				//////////////////////////////////////////////////////////////////////////////				
			}						
		}	
		
		else if (Time.frameCount % 30 == 20)
		{
			string popoversActivatedString = PlayerPrefs.GetString("CCPopoversActivated");
			bool popoversActivatedBool = (popoversActivatedString == "YES") ? true : false;
			
			if (popoversActivatedBool != iPopoversActivated)
			{
				Debug.Log("> CrystalUnity_Basic popovers activated " + popoversActivatedBool);
				iPopoversActivated = popoversActivatedBool;
				
				//////////////////////////////////////////////////////////////////////////////
				// The Crystal popovers have either been activated or deactivated
				// If you'd prefer to grey-out your main menu buttons when the popovers are
				// activated you can do it from here or check the popoversActivated property
				//////////////////////////////////////////////////////////////////////////////
			}
		}
				
		else if (Time.frameCount % 30 == 25)	
		{
			string incomingLeaderboardType = PlayerPrefs.GetString("CCLeaderboardTypeUpdated");
			string incomingTop20EntriesForLeaderboard = PlayerPrefs.GetString("CCTop20EntriesForLeaderboardIDUpdated");
			string incomingTop20FriendsForLeaderboard = PlayerPrefs.GetString("CCTop20FriendsForLeaderboardIDUpdated");
			string incomingRandom20ForLeaderboard = PlayerPrefs.GetString("CCRandom20ForLeaderboardIDUpdated");
			string incomingCurrentUserEntryForLeaderboard = PlayerPrefs.GetString("CCCurrentUserEntryForLeaderboardIDUpdated");

			if (incomingLeaderboardType != "")
			{
				iLeaderboardType = (CrystalLeaderboardType)(Convert.ToInt32(incomingLeaderboardType));
				Debug.Log("> CrystalUnity_Basic LeaderboardTypeUpdated activated " + iLeaderboardType );
				PlayerPrefs.SetString("CCLeaderboardTypeUpdated", "");				
			}
			
			if (incomingTop20EntriesForLeaderboard != "")
			{
				Debug.Log("> CrystalUnity_Basic Top20EntriesForLeaderboardIDUpdated activated " + incomingTop20EntriesForLeaderboard);
				PopulateLeaderBoardEntries(incomingTop20EntriesForLeaderboard, LeaderboardType.Top20Entries);
				PlayerPrefs.SetString("CCTop20EntriesForLeaderboardIDUpdated", "");
											
				//////////////////////////////////////////////////////////////////////////////
				// Top20 Entries for leaderboard have been updated
				//
				// Call your Top20 Entries for leaderboard updated handler script here or check 
				// the CurrentTop20EntriesForLeaderboard property every so often
				//////////////////////////////////////////////////////////////////////////////
			}
			
			if (incomingTop20FriendsForLeaderboard != "")
			{
				Debug.Log("> CrystalUnity_Basic incomingTop20FriendsForLeaderboard activated " + incomingTop20FriendsForLeaderboard);
				PopulateLeaderBoardEntries(incomingTop20FriendsForLeaderboard, LeaderboardType.Top20Friends);
				PlayerPrefs.SetString("CCTop20FriendsForLeaderboardIDUpdated", "");
											
				//////////////////////////////////////////////////////////////////////////////
				// Top20 Friends for leaderboard have been updated
				//
				// Call your Top20 Entries for leaderboard updated handler script here or check 
				// the CurrentTop20FriendsForLeaderboard property every so often
				//////////////////////////////////////////////////////////////////////////////									

			}
			
			if (incomingRandom20ForLeaderboard != "")
			{
				Debug.Log("> CrystalUnity_Basic Random20ForLeaderboardIDUpdated activated " + incomingRandom20ForLeaderboard);
				PopulateLeaderBoardEntries(incomingRandom20ForLeaderboard, LeaderboardType.Random20);
				PlayerPrefs.SetString("CCRandom20ForLeaderboardIDUpdated", "");
											
				//////////////////////////////////////////////////////////////////////////////
				// Random20 for leaderboard have been updated
				//
				// Call your Random Entries for leaderboard updated handler script here or check 
				// the CurrentRandom20ForLeaderboard property every so often
				//////////////////////////////////////////////////////////////////////////////								
					
			}
			
			if (incomingCurrentUserEntryForLeaderboard != "")
			{
				Debug.Log("> CrystalUnity_Basic CurrentUserEntryForLeaderboardIDUpdated activated " + incomingCurrentUserEntryForLeaderboard);
				
				Hashtable ht = (Hashtable)JSON.JsonDecode(incomingCurrentUserEntryForLeaderboard);

				if (ht != null)
				{
					iCurrentUserEntryForLeaderboard.username = (string)ht["username"];
					iCurrentUserEntryForLeaderboard.position = (string)ht["position"];
					iCurrentUserEntryForLeaderboard.score = (double)ht["score"];
				}
				
				PlayerPrefs.SetString("CCCurrentUserEntryForLeaderboardIDUpdated", "");
									
				//////////////////////////////////////////////////////////////////////////////
				// CurrentUserEntry for leaderboard have been updated
				//
				// Call your Current User Entry for leaderboard updated handler script here or check 
				// the CurrentUserEntryForLeaderboard property every so often
				//////////////////////////////////////////////////////////////////////////////	
			}
		}
	}
	
	/**
	 * @brief Ask the session whether the application was started from an incoming challenge (push) notification
 	 * @return true if the application was started from an incoming challenge
 	 */
	public bool AppWasStartedFromPendingChallenge()
	{
		if (iStartedFromChallenge != "")
			return true;
		else
			return false;
	}
	
	/**
	 * @brief Ask the session whether there is an incoming challenge from the Crystal UI.
	 * This will occur when the user initiates a challenge from the Crystal UI and reactivates the game.
 	 * @return true if the user initiated a challenge in the Crystal UI
 	 */
	public bool HaveIncomingChallengeFromCrystal()
	{
		if (iLastIncomingChallenge != "")
			return false;
		else
			return true;
	}
	
	/**
	 * Activates the Crystal UI
	 */
	public void ActivateUi()
	{
		Debug.Log("> CrystalUnityBasic ActivateUi");
		ActivateUi(CrystalUnityBasic.ActivateUiType.StandardUi);
	}
	
	/**
	 * Activates the Crystal UI at the specified UI area where possible
	 * @param type The ActivateUiType as specified above
	 */
	public void ActivateUi(CrystalUnityBasic.ActivateUiType type)
	{
		if (isOkToRun())
		{
			Debug.Log("> CrystalUnityBasic ActivateUi, " + type + ", isOkToRun");
			AddCommand("ActivateUi|" + (int)type);
		}
		else	
			Debug.Log("> CrystalUnityBasic ActivateUi, " + type);
	}
	
	/**
	 * @brief Activate the Crystal UI at a specific leaderboard
	 * @param leaderboardId The id of the leaderboard to open the UI on
	 */
	public void ActivateUiAtLeadboardWithId(string leaderboardId)
	{
		if (isOkToRun())
		{
			AddCommand("ActivateUiAtLeadboardWithId|" + leaderboardId);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic ActivateUiAtLeadboardWithId" + leaderboardId);
		}
	}
	
	/**
	 * Deactivates the Crystal UI at the specified UI area where possible
	 * @param type The ActivateUiType as specified above
	 */
	public void DeactivateUi()
	{
		if (isOkToRun())
		{
			AddCommand("DeactivateUi");
		}
		else	
			Debug.Log("> CrystalUnityBasic DeactivateUi");
	}
	
	
	/**
	 * Activates the Crystal pull tab UI at the specified UI area
	 * @param type The ActivateUiType as specified above
	 * @param edge The edge to come from.  One of "top", "bottom", "left", "right"
	 */
	public void ActivatePullTabUi(CrystalUnityBasic.ActivatePullTabUiType type, string edge)
	{
		ActivatePullTabUi(type, edge, true);
	}
		
	/**
	 * Activates the Crystal pull tab UI at the specified UI area
	 * @param type The ActivateUiType as specified above
	 * @param edge The edge to come from.  One of "top", "bottom", "left", "right"
 	 * @param closedState The initial closed state of the tab	 
	 */
	public void ActivatePullTabUi(CrystalUnityBasic.ActivatePullTabUiType type, string edge, bool closedState)
	{
		if (isOkToRun())
		{
			Debug.Log("> CrystalUnityBasic ActivatePullTabUi, "+ type + ", " + edge + ", " + closedState + ", isOkToRun");
			AddCommand("ActivatePullTabUi|" + (int)type + "|" + edge + "|" + closedState);
		}
		else	
			Debug.Log("> CrystalUnityBasic ActivatePullTabUi, " + type + ", " +  edge + ",  " +  closedState);
	}


	/**
	 * @brief Activate the Crystal pull tab UI at a specific leaderboard
	 * @param leaderboardId The id of the leaderboard to open the UI on
	 * @param edge The edge to come from.  One of "top", "bottom", "left", "right"
	 */
	public void ActivatePullTabUiAtLeadboardWithId(string leaderboardId, string edge)
	{
		ActivatePullTabUiAtLeadboardWithId(leaderboardId, edge, true);
	}

	/**
	 * @brief Activate the Crystal pull tab UI at a specific leaderboard
	 * @param leaderboardId The id of the leaderboard to open the UI on
	 * @param edge The edge to come from.  One of "top", "bottom", "left", "right"
	 * @param closedState The initial closed state of the tab	 
	 */
	public void ActivatePullTabUiAtLeadboardWithId(string leaderboardId, string edge, bool closedState)
	{
		if (isOkToRun())
		{
			Debug.Log("> CrystalUnityBasic ActivatePullTabUiAtLeadboardWithId, "+ leaderboardId + ", " + edge + ", " + closedState + ", isOkToRun");
			AddCommand("ActivatePullTabUiAtLeadboardWithId|" + leaderboardId + "|" + edge + "|" + closedState);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic ActivatePullTabUiAtLeadboardWithId" + leaderboardId + ",  " +  closedState);
		}
	}
	
	/**
 	* @brief Activates the Crystal pull tab user interface on a custom set of multiple tabs
 	* @ingroup ui
 	* @param tabs Array of tabs as strings in lowercase. 
 	*			   Valid tab strings are: 
 	*					"news"
 	*					"profile"
 	*					"settings"
 	*					"leaderboards", 
 	*					"achievements", 
 	*					"challenges", 
 	*					"gifting", 
 	*					"virtualgoods",
 	*					"virtualcurrencies"  
 	*					"giftsandmarket", 
 	*					"friends"  
 	*					"findfriends"
 	*			   NOTE: A maximum of four tabs will be parsed from the array and any invalid tabs will be ignored.  
 	* @param edge The edge to display the pull tab interface from, one of "right", "left", "top" or "bottom"
 	*/	
	public void ActivateCrystalPullTabOn(IList<string> tabs, string edge)
	{
		ActivateCrystalPullTabOn(tabs, edge, true);
	}
	
	/**
 	* @brief Activates the Crystal pull tab user interface on a custom set of multiple tabs
 	* @ingroup ui
 	* @param tabs Array of tabs as strings in lowercase. 
 	*			   Valid tab strings are: 
 	*					"news"
 	*					"profile"
 	*					"settings"
 	*					"leaderboards", 
 	*					"achievements", 
 	*					"challenges", 
 	*					"gifting", 
 	*					"virtualgoods",
 	*					"virtualcurrencies"  
 	*					"giftsandmarket", 
 	*					"friends"  
 	*					"findfriends" 
 	*			   NOTE: A maximum of four tabs will be parsed from the array and any invalid tabs will be ignored.  
 	* @param edge The edge to display the pull tab interface from, one of "right", "left", "top" or "bottom"
 	* @param closedState The initial closed state of the tab
 	*/	
	public void ActivateCrystalPullTabOn(IList<string> tabs, string edge, bool closedState)
	{
		if (isOkToRun())
		{
			string str = null;

			if (tabs != null)
			{
				ArrayList tabsList = new ArrayList();
			
				foreach(string tab in tabs)
				{
					tabsList.Add(tab);
				}

            	str = JSON.JsonEncode(tabsList);
			}
			
			AddCommand("ActivateCrystalPullTabOn|" + str + "|" + edge + "|" + closedState);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic ActivateCrystalPullTabOn" + edge + ",  " +  closedState);
		}
	}
	
	/**
 	* @brief Deactivates the Crystal pull tab user interface.  This will animate the pull tab off screen.
 	* @ingroup ui
 	*/
	public void DeactivatePullTabUi()
	{
		if (isOkToRun())
		{
			AddCommand("DeactivatePullTabUi");
		}
		else	
			Debug.Log("> CrystalUnityBasic DeactivatePullTabUi");
	}

	/**
 	* @brief This will animate the Crystal pull tab to the default closed position. 
 	* @ingroup ui
 	*/
	public void ResetCrystalPullTabState()
	{
		if (isOkToRun())
		{
			AddCommand("ResetCrystalPullTabState");
		}
		else	
			Debug.Log("> CrystalUnityBasic ResetCrystalPullTabState");
	}

	/**
	 * @brief Post the result of the last challenge that the game was notified for
	 * The game will be notified of the challenge via the challengeStartedWithGameConfig: method of CrystalSessionDelegate.
	 * @param result The result of the challenge, either as a numerical value or as a number of seconds for time-based scores
	 * @param doDialog If true Crystal will display a dialog over the game user interface
	 */
	public void PostChallengeResultForLastChallenge(double result, bool doDialog)
	{
		if (isOkToRun())
		{
			AddCommand("PostChallengeResultForLastChallenge|" + result + "|" + doDialog);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostChallengeResultForLastChallenge " + result + ", " + doDialog);
		}
	}
	
	/**
	 * @brief Notify the Crystal servers and the user (via a popup notification) that an achievement has been completed.
	 * The game designer should not attempt to cache, buffer or otherwise restrict the number of times this method is called.
	 * All logic with regards to reducing server load, handling multiple users and avoiding excessive popups is handled within the Crystal SDK.
	 * Please call this method whenever an achievement is achieved. Failure to do so will almost certainly cause problems for multiple Crystal users on the same device.
	 * @param achievementId The ID of the achievement as shown in the Crystal control panel
	 * @param wasObtained true if the achievement has been obtained or NO to 'unobtain' it.
	 * @param description A description of the achievement to be displayed to the user. Supplying the description here allows the developer to localize the description. Crystal may not necessarily have a network connection so the only way to get the achievement description is here. If no desctiption is supplied then no notification will be displayed to the user.
	 * @param alwaysPopup if true the achievement popup will always be displayed to the user. If false (the most common choice) the popup will only be displayed the first time that the achievement is achieved.
	 */
	public void PostAchievement(string achievementId, bool wasObtained, string description, bool alwaysPopup)
	{
		// Call the PostAchievement with the Game Center ID the same as the Crystal one
		PostAchievement(achievementId, wasObtained, description, alwaysPopup, achievementId);
	}
	
	/**
	 * @brief Notify the Crystal servers of a leaderboard result for the specified leaderboard ID.
	 * The game designer should not attempt to cache, buffer or otherwise restrict the number of times this method is called.
	 * All logic with regards to reducing server load, handling multiple users and avoiding unneeded posts is handled within the Crystal SDK.
	 * Please call this method whenever a score is scored. Failure to do so will almost certainly cause problems for multiple Crystal users on the same device.
	 * @param result The score to publish, either as a numerical value or as a number of seconds for time-based scores
	 * @param leaderboardId The ID of the leaderboard to post to, which should be taken from the Developer Dashboard
	 * @param lowestValFirst Set this if you have YES set for lowest value first in the developer dashboard. This parameter MUST match the flag in the developer dashboard!
 	 * @param isTimeBased Set this if the leaderboard ID is set to have 'time based' leaderboards in the developer dashboard. This setting creates server load and must not be set for leaderboards that are not time-based.
	 */
	public void PostLeaderboardResult(string leaderboardId, float result, bool lowestValFirst, bool isTimeBased)
	{
		// Call the PostLeaderboardResult with the Game Center ID the same as the Crystal one
		PostLeaderboardResult(leaderboardId, result, lowestValFirst, leaderboardId, isTimeBased);
	}
	
	/**
	 * @brief Notify the Crystal servers and the user (via a popup notification) that an achievement has been completed.
	 * The game designer should not attempt to cache, buffer or otherwise restrict the number of times this method is called.
	 * All logic with regards to reducing server load, handling multiple users and avoiding excessive popups is handled within the Crystal SDK.
	 * Please call this method whenever an achievement is achieved. Failure to do so will almost certainly cause problems for multiple Crystal users on the same device.
	 * @param achievementId The ID of the achievement as shown in the Crystal control panel
	 * @param wasObtained true if the achievement has been obtained or NO to 'unobtain' it.
	 * @param description A description of the achievement to be displayed to the user. Supplying the description here allows the developer to localize the description. Crystal may not necessarily have a network connection so the only way to get the achievement description is here. If no desctiption is supplied then no notification will be displayed to the user.
	 * @param alwaysPopup if true the achievement popup will always be displayed to the user. If false (the most common choice) the popup will only be displayed the first time that the achievement is achieved.
	 * @param gcAchievementId The ID of the achievement as shown in the Crystal control panel
	 */
	public void PostAchievement(string achievementId, bool wasObtained, string description, bool alwaysPopup, string gcAchievementId)
	{
		if (isOkToRun())
		{
			AddCommand("PostAchievement|" + achievementId + "|" + wasObtained + "|" + description + "|" + alwaysPopup + "|" + gcAchievementId);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostAchievement" + achievementId + ", " + wasObtained + ", " + description + ", " + alwaysPopup + ", " + gcAchievementId);
		}
	}
	
	/**
	 * @brief Notify the Crystal servers of a leaderboard result for the specified leaderboard ID.
	 * The game designer should not attempt to cache, buffer or otherwise restrict the number of times this method is called.
	 * All logic with regards to reducing server load, handling multiple users and avoiding unneeded posts is handled within the Crystal SDK.
	 * Please call this method whenever a score is scored. Failure to do so will almost certainly cause problems for multiple Crystal users on the same device.
	 * @param result The score to publish, either as a numerical value or as a number of seconds for time-based scores
	 * @param leaderboardId The ID of the leaderboard to post to, which should be taken from the Developer Dashboard
	 * @param lowestValFirst Set this if you have YES set for lowest value first in the developer dashboard. This parameter MUST match the flag in the developer dashboard!
	 * @param gcLeaderboardId The ID of the Game Center leaderboard to post to, which should be taken from the Developer Dashboard
 	 * @param isTimeBased Set this if the leaderboard ID is set to have 'time based' leaderboards in the developer dashboard. This setting creates server load and must not be set for leaderboards that are not time-based.
	 */
	public void PostLeaderboardResult(string leaderboardId, float result, bool lowestValFirst, string gcLeaderboardId, bool isTimeBased)
	{
		if (isOkToRun())
		{
			AddCommand("PostLeaderboardResult|" + leaderboardId + "|" + result + "|" + lowestValFirst + "|" + gcLeaderboardId + "|" + isTimeBased);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostLeaderboardResult" + leaderboardId + ", " + result + ", " + lowestValFirst + ", " + gcLeaderboardId + ", " + isTimeBased);
		}
	}

	/**
 	* @brief Report progress made towards an achievement both to Crystal and Game Center
 	* This method updates the Crystal UI to show the progress that the player has made towards an achievement in plain text.
 	* This method also updates Game Center to report the percentage complete for the achievement.
 	* Achievement popups are not shown if this method is called.
 	* @param crystalId The ID of the achievement as shown in the Crystal control panel
 	* @param gameCenterId The ID of the Game Center achievement to use.  This will be defined in iTunes Connect for the application.
 	* @param percentageComplete The percentage complete for the achievement, i.e. 40.0 (passed to Game Center)
 	* @param achievementDescription A textual description of the achievement progress, i.e. "4 out of 10 coins collected" (shown in Crystal UI)
 	*/
	public void PostAchievementProgressWithId(string crystalId, string gameCenterId, double percentageComplete, string achievementDescription )
	{
		if (isOkToRun())
		{
			AddCommand("PostAchievementProgressWithId|" + crystalId + "|" + gameCenterId + "|" +  percentageComplete + "|" + achievementDescription);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostAchievementProgressWithId, " + crystalId + ", " + gameCenterId + ", " +  percentageComplete + ", " + achievementDescription);
		}		
	}
		
	/**
	 * @brief Lock the crystal interface to the specified interface orientation
	 * This method will override any call to lockToOrientation: in AppController+Crystal.mm
	 * Supported orientations are Portrait, LandscapeLeft and LandscapeRight
	 * @param orientation The orientation to lock the interface to
	 */
	public void LockToOrientation(iPhoneScreenOrientation orientation)
	{
		string orientationString = ScreenOrientationToString(orientation);
		
		if (isOkToRun() && orientationString != null)
		{
			AddCommand("LockToOrientation|" + orientationString);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic LockToOrientation" + orientationString);
		}
	}
	

	/**
	 * @brief Displays the Crystal splash screen
	 * This method displays the Crystal splash screen to the user above the current game UI.
	 * It is the responsibility of the developer to ensure that this dialog is displayed at an appropriate time, generally just after the game is started.
	 * When the splash screen has been dismissed splashScreenFinishedWithActivateCrystal: will be called in the delegate.
	 * Normally the game would only display this splash screen once to the user.
	 */
	public void DisplaySplashScreen()
	{
		if (isOkToRun())
		{
			AddCommand("DisplaySplashScreen");
		}
		else
		{
			Debug.Log("> CrystalUnityBasic DisplaySplashScreen");
		}
	}
	
	/**
	 * @brief Sets values for various internal Crystal settings.
	 * This method is provided for developers to activate workarounds for bugs on the iPhone and the graphics libraries used by developers
	 * @param setting the CrystalSetting to set
	 * @param settingValue the value to set for this setting, which will generally be @"YES" to activate a setting
	 */
	public void ActivateCrystalSetting(CrystalSetting setting, string settingValue)
	{
		if (isOkToRun() && settingValue != null)
		{
			AddCommand("ActivateCrystalSetting|" + (int)setting + "|" + settingValue);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic ActivateCrystalSetting, " + (int)setting + ", " + settingValue);
		}
	}
	
	/**
	 * @brief Call this after your game has loaded to initiate login to Game Center
	 * Calling this method can initiate the Game Center login dialog, so ensure that you call this at a suitable moment.
	 * After the user has signed up to Game Center this method will display a 'welcome back' overlay.
	 * At the time of writing (iOS 4.1 beta 3) the iOS APIs used by this method must be called before scores and achievements can be posted.
	 * As a result of this you must be careful of the timing of this call.
	 */
	public void AuthenticateLocalPlayer()
	{
		if (isOkToRun())
		{
			AddCommand("AuthenticateLocalPlayer");
		}
		else
		{
			Debug.Log("> CrystalUnityBasic AuthenticateLocalPlayer");
		}
	}
	
	/**
 	* @brief Closes the Crystal session.
 	* This should only be called when absolutely necessary for memory usage reasons. The Crystal session without the UI is very small, so this should cause no problems.
 	* Without a running sesssion high scores, achievements and analytics will not be posted to the server.
 	*/	
	public void CloseCrystalSession()
	{
		if (isOkToRun())
		{
			AddCommand("CloseCrystalSession");
		}
		else
		{
			Debug.Log("> CrystalUnityBasic CloseCrystalSession");
		}		
	}
		
	/**
	 * @brief 
	 */	
	public void WillRotateToInterfaceWithOrientation(iPhoneScreenOrientation orientation, double orientationDuration)
	{
		string orientationString = ScreenOrientationToString(orientation);
		
		if (isOkToRun() && orientationString != null)
		{
			AddCommand("WillRotateToInterfaceWithOrientation|" + orientationString + "|" + orientationDuration);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic WillRotateToInterfaceWithOrientation" + orientationString + ", " + orientationDuration);
		}			
	}
	
	/**
	 * @brief 
	 */		
	public void DidRotateFromInterfaceOrientation(iPhoneScreenOrientation orientation)
	{
		string orientationString = ScreenOrientationToString(orientation);
		
		if (isOkToRun() && orientationString != null)
		{
			AddCommand("DidRotateFromInterfaceOrientation|" + orientationString);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic DidRotateFromInterfaceOrientation" + orientationString);
		}		
	}
	
	/**
 	* @brief Initiate the download of leaderboard data for the supplied leaderboard ID
 	* If the leaderboard data for the specified leaderboardID is already downloaded for this game session the data will not be updated from the server to avoid excessive server load.
 	* When the leaderboard data has been downloaded the crystalLeaderboardUpdated: method will be called on CrystalLeaderboardDelegate.
 	* There is no indication of an error while downloading the leaderboard data and there is no need to manually retry the process.
 	*/
 	[Obsolete("Use public void DownloadLeaderBoardDataForID(string leaderboardId, CrystalLeaderboardType leaderboardType)")]
	public void DownloadLeaderBoardDataForID(string leaderboardId)
	{
		if (isOkToRun())
		{
			AddCommand("DownloadLeaderboardDataForID|" + leaderboardId);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic DownloadLeaderboardDataForID, " + leaderboardId);
		}				
	}
		
	/**
 	* @ingroup get
 	* @brief Initiate the download of leaderboard data for the supplied leaderboard ID and leaderboard type
 	* If the leaderboard data for the specified leaderboardID is already downloaded for this game session the data will not be updated from the server to avoid excessive server load.
 	* When the leaderboard data has been downloaded the crystalLeaderboardUpdated: method will be called on CrystalLeaderboardDelegate.
 	* There is no indication of an error while downloading the leaderboard data and there is no need to manually retry the process.
 	* @param leaderboardId The ID of the leaderboard as shown in the developer dashboard
 	* @param leaderboardType The CrystalLeaderboardType of the leaderboard to retrieve. If this leaderboard type is not configured in the developer dashboard no data will be returned.
 	*/
	public void DownloadLeaderBoardDataForID(string leaderboardId, CrystalLeaderboardType leaderboardType)
	{
		DownloadLeaderBoardDataForID( leaderboardId, leaderboardType, false);	
	}		
	
	/**
 	* @ingroup get
 	* @brief Initiate the download of leaderboard data for the supplied leaderboard ID and leaderboard type
 	* If the leaderboard data for the specified leaderboardID is already downloaded for this game session the data will not be updated from the server to avoid excessive server load.
 	* When the leaderboard data has been downloaded the crystalLeaderboardUpdated: method will be called on CrystalLeaderboardDelegate.
 	* There is no indication of an error while downloading the leaderboard data and there is no need to manually retry the process.
 	* @param leaderboardId The ID of the leaderboard as shown in the developer dashboard
 	* @param leaderboardType The CrystalLeaderboardType of the leaderboard to retrieve. If this leaderboard type is not configured in the developer dashboard no data will be returned.
 	* @param force Set to true to attempt to force a server-side refresh of downloaded leaderboard data.
 	*/
	public void DownloadLeaderBoardDataForID(string leaderboardId, CrystalLeaderboardType leaderboardType, bool force)
	{
		if (isOkToRun())
		{
			AddCommand("DownloadLeaderboardDataForID|" + leaderboardId + "|" + (int)leaderboardType + "|" + force );
		}
		else
		{
			Debug.Log("> CrystalUnityBasic DownloadLeaderboardDataForID, " + leaderboardId + ", " + leaderboardType + ", " + force);
		}				
	}	
	
				
	/**
 	* @brief Post changes to the user's virtual goods record back to the server
 	* Use this method to post one or more changes to the user's virtual goods to the server.
 	* Changes will only be made to the virtual good that are supplied, and more than one virtual good can be updated at once. There is no need to replicate the information stored in the goods property in full.
 	* To avoid server load it is recommended to combine changes into one call by adding the info to the same dictionary.
 	* To remove the good from the user supply a 0 for the number of goods owned.
 	* When the virtual goods have been updated the client will be informed via crystalVirtualGoodsInfoUpdatedWithSuccess: and the results reflected in the goods property.
 	* @param goods The format of the information supplied is a dictionary, where the key is the virtual good ID (string) and the value is the number of goods owned (int).
 	*/			
	public void PostVirtualGoods(IDictionary<string, int> goods)
	{
		if (isOkToRun() && goods != null && goods.Count != 0 )
		{
			Debug.Log( ">CrystalUnityBasic PostVirtualGoods" );
			
			Hashtable ht = new Hashtable();
			
			foreach(KeyValuePair<string, int> entry in goods)
			{
				ht.Add(entry.Key, entry.Value);
			}
						
			string str = JSON.JsonEncode(ht);
  
			AddCommand("PostVirtualGoods|" + str);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostVirtualGoods, ");
		}		
	}
	
	/**
 	* @brief Set a list of goods that are not selectable and are shown with a 'locked' icon in the Crystal UI
 	* This method works differently from postGoods: and postBalances: in that it's not possible to 'update' items peacemeal.
 	* The client must send all locked goods in one call, and can remove the locks by passing nil as the parameter.
 	* @param lockedGoods An NSSet of NSString good IDs to lock or null to remove any locks
 	*/		
	public void SetLockedGoods(IList<string> lockedGoods)
	{
		if (isOkToRun())
		{
			Debug.Log( ">CrystalUnityBasic SetLockedGoods" );
			string str = null;

			if (lockedGoods != null && lockedGoods.Count != 0)
			{
				ArrayList lockedGoodsList = new ArrayList();
			
				foreach(string goodsId in lockedGoods)
				{
					lockedGoodsList.Add(goodsId);
				}
			
            	str = JSON.JsonEncode(lockedGoodsList);
			}
			
			Debug.Log("> CrystalUnityBasic SetLockedGoods, " +  str);
			AddCommand("SetLockedGoods|" + str);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic SetLockedGoods, ");
		}
	}
	
	/**
 	* @brief Post changes to the user's balances back to the server
 	* Use this method to post one or more changes to the user's wallet balances to the server.
 	* Changes will only be made to the balances that are supplied, and more than one balance can be updated at once. There is no need to replicate the information stored in the balances property in full.
 	* To avoid server load it is recommended to combine changes into one call by adding the info to the same dictionary.
 	* When the virtual currencies have been updated the client will be informed via crystalVirtualGoodsInfoUpdatedWithSuccess: and the results reflected in the goods property.
 	* @param balances The format of the information supplied is a dictionary, where the key is the currency ID (string) and the value is the balance (int).
 	*/	
	public void PostVirtualBalances(IDictionary<string, int> balances)
	{
		if (isOkToRun() && balances != null && balances.Count != 0 )
		{
			Debug.Log( ">CrystalUnityBasic PostVirtualBalances" );

			Hashtable ht = new Hashtable();
			
			foreach(KeyValuePair<string, int> entry in balances)
			{
				ht.Add(entry.Key, entry.Value);
			}
						
			string str = JSON.JsonEncode(ht);
  			
			AddCommand("PostVirtualBalances|" + str);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostVirtualBalances, ");
		}
	}
	
	/**
 	* @brief Instructs the SDK to start keeping the CrystalPlayer class up-to-date with the current player's info
 	* Because this method initiates network traffic and server load it is important that apps refrain from calling the method unless the CrystalPlayer data is used
 	*/
	public void CrystalPlayerStartUpdating()
	{
		if (isOkToRun())
		{
			AddCommand("CrystalPlayerStartUpdating");
		}
		else
		{
			Debug.Log("> CrystalUnityBasic CrystalPlayerStartUpdating");
		}		
	}
	
	/**
 	* @brief Instructs the SDK to start keeping the CrystalPlayer class up-to-date with the current player's info
 	* Because this method initiates network traffic and server load it is important that apps refrain from calling the method unless the CrystalPlayer data is used
 	*/
	public void VirtualGoodsStartUpdating()
	{
		if (isOkToRun())
		{
			AddCommand("VirtualGoodsStartUpdating");
		}
		else
		{
			Debug.Log("> CrystalUnityBasic VirtualGoodsStartUpdating");
		}		
	}	
	
	/**
 	* @brief Instructs the SDK to update the CrystalVirtualGoods info as soon as possible
 	* Ordinarily any activity relating to virtual goods or currencies inside the Crystal UI will automatically instruct CrystalVirtualGoods to update itself.
 	* The same is true when using APIs like postGoods:. If a post fails the client should always retry via the post calls and not call updateNow. 
 	* updateNow will retrieve updated information from the server and any information previously posted will be lost.
 	* It should be rare that the client will need to call this method but it is added for completeness.
 	*/	
	public void VirtualGoodsUpdateNow()
	{
		if (isOkToRun())
		{
			AddCommand("VirtualGoodsUpdateNow");
		}
		else
		{
			Debug.Log("> CrystalUnityBasic VirtualGoodsUpdateNow");
		}		
	}		

	/**
	 * @brief Instructs the SDK to request the achievement data for the current signed-in user.
	 * The CurrentAchievements property will store the result of the request
	 */	
	public void RequestAchievementData()
	{
		if (isOkToRun())
		{
			AddCommand("RequestAchievementData");
		}
		else
		{
			Debug.Log("> CrystalUnityBasic RequestAchievementData");
		}		
	}		
	
	/**
	 * @brief public property which returns a CrystalPlayer
	 */		
	public CrystalPlayer CurrentCrystalPlayer
	{
		get { return iPlayer; }
	}
	
	/**
	 * @brief public property which returns a dictionary, where the key is the virtual goods ID (string) and the value is the number of goods owned (int).
	 */		
	public IDictionary<string, int> CurrentVirtualGoods
	{
		get { return iVirtualGoods; }
	}

	/**
	 * @brief public property which returns a dictionary, where the key is the currency ID (string) and the value is the balance (int).
	 */		
	public IDictionary<string, int> CurrentVirtualBalances
	{
		get { return iVirtualBalances; }
	}
	
	/**
	 * @brief public property which returns a List of achievement IDs (string)
	 */		
	public IList<string> CurrentAchievements
	{
		get { return iAchievements; }
	}
		
	/**
 	* @brief Retrieve the top 20 entries for the specified leaderboard
 	* @return A List of leaderboard entries or nil if the leaderboard data is not available
 	*/		
	public IList<LeaderboardEntry> CurrentTop20EntriesForLeaderboard
	{
		get { return iTop20EntriesForLeaderboard; }	
	}
	
	/**
 	* @brief Retrieve the top 20 friends for the specified leaderboard, including the current user
 	* @return A List of leaderboard entries or nil if the leaderboard data is not available
 	*/	
	public IList<LeaderboardEntry> CurrentTop20FriendsForLeaderboard
	{
		get { return iTop20FriendsForLeaderboard; }	
	}
	
	/**
 	* @brief Retrieve a random selection of 20 entries for the specified leaderboard
 	* @return A List of leaderboard entries or nil if the leaderboard data is not available
 	*/		
	public IList<LeaderboardEntry> CurrentRandom20ForLeaderboard
	{
		get { return iRandom20ForLeaderboard; }	
	}
	
	/**
 	* @ingroup get
 	* @brief Retrieve the data for the current user for the specified leaderboard
 	* @return A leaderboardEntry
 	*/
	public LeaderboardEntry CurrentUserEntryForLeaderboard
	{
		get { return iCurrentUserEntryForLeaderboard; }	
	}
		
	/**
 	* @ingroup get
 	* @brief Retrieve the leaderboardType for the last download
 	* @return A CrystalLeaderboardType
 	*/
	public CrystalLeaderboardType DownloadedLeaderboardType
	{
		get { return iLeaderboardType; }	
	}		
		
	/**
	 * @brief returns true is the user is currently signed into Crystal
	 */		
	public bool IsCrystalPlayerSignedIn()
	{
		bool isCrystalPlayerSignedIn = false;
		Debug.Log("> CrystalUnityBasic IsCrystalPlayerSignedIn");

		if (isOkToRun())
		{				
   			PlayerPrefs.SetString("CCCommandWithReturn", "isCrystalPlayerSignedIn");  		
   			string res =  PlayerPrefs.GetString("Result");
			isCrystalPlayerSignedIn = (res == "YES") ? true : false;
		}
		return isCrystalPlayerSignedIn;
	}
		
		
	private void AddCommand(string newCommand)
	{
		string currentCommand = PlayerPrefs.GetString("CCCommands");
		
		if (currentCommand != "")
		{
			// We already have a command so we need to append this one to the end
			PlayerPrefs.SetString("CCCommands", currentCommand + "!<->!" + newCommand);
		}
		else
		{
			// This is the first
			PlayerPrefs.SetString("CCCommands", newCommand);
		}
	}
			
	private void PopulateCrystalPlayer(string incomingPlayerInfo)
	{	
 		Hashtable ht = (Hashtable)JSON.JsonDecode(incomingPlayerInfo); 
   		
   		if (ht == null)
   			return;
   		
   		if (ht.ContainsKey("data"))
   		{
 			if (iPlayer == null)
			{
				iPlayer = new CrystalPlayer();
			}  			
   			
   			Hashtable data = ht["data"] as Hashtable;
 
 			iPlayer.isFacebookUser = (bool)data["facebookuser"];
 			iPlayer.isTwitterUser = (bool)data["twitteruser"];
   			iPlayer.numCrystalFriends = Convert.ToInt32((double)data["crystalfriends"]);
 			iPlayer.numCrystalFriendsWithGame = Convert.ToInt32((double)data["gamefriends"]);
 			
 			if (iPlayer.gifts != null)
			{
				iPlayer.gifts.Clear();
			}
			else
			{
				iPlayer.gifts = new List<int>();	
			}
				
			ArrayList giftsList = (ArrayList)data["gifts"];
			
			if ( giftsList != null )
			{
				foreach (double giftValue in giftsList)
				{
					iPlayer.gifts.Add(Convert.ToInt32(giftValue));		 	
				}			
			}
					
 			iPlayer.alias = (string)data["crystaluser"];
			if (iPlayer.alias != "")
				iPlayer.isCrystaluser = true;
			
   			iPlayer.badgeNumber = Convert.ToInt32((double)data["badge"]);
   			
   			
    		if (iPlayer.crystalfriendIds != null)
			{
				iPlayer.crystalfriendIds.Clear();
			}
			else
			{
				iPlayer.crystalfriendIds = new List<string>();	
			}
						
			ArrayList crystalFriendsList = (ArrayList)data["crystalfriendids"];
			
			if ( crystalFriendsList != null )
			{
				foreach (string crystalFriend in crystalFriendsList)
				{
					iPlayer.crystalfriendIds.Add(crystalFriend);		 	
				}			
			}   			
   			
   			//	crystalplayerid is sent as a double at present but may be alphanumeric in future?
			iPlayer.crystalPlayerId = Convert.ToString((double)data["crystalplayerid"]);
   		}		
	}
	
	private void PopulateVirtualGoods(string incomingVirtualGoods)
	{
		Hashtable ht = (Hashtable)JSON.JsonDecode(incomingVirtualGoods); 

		if (ht == null)
			return;
			
		if (iVirtualGoods != null)
		{
			iVirtualGoods.Clear();	
		}
		else
		{
			iVirtualGoods = new Dictionary<string, int>();	
		}	

 
		ArrayList keys = new ArrayList(ht.Keys);
 		ArrayList values = new ArrayList(ht.Values);
 						
 		for (int i = 0 ; i < keys.Count ; i++)
 		{
 			iVirtualGoods.Add((string)keys[i], Convert.ToInt32(values[i]));
 		}
	}
	
	private void PopulateVirtualBalances(string incomingVirtualBalances)
	{
		Hashtable ht = (Hashtable)JSON.JsonDecode(incomingVirtualBalances); 

		if (ht == null)
			return;
			
		if (iVirtualBalances != null)
		{
			iVirtualBalances.Clear();	
		}
		else
		{
			iVirtualBalances = new Dictionary<string, int>();	
		}	
	
		ArrayList keys = new ArrayList(ht.Keys);
 		ArrayList values = new ArrayList(ht.Values);
 						
 		for (int i = 0 ; i < keys.Count ; i++)
 		{
 			iVirtualBalances.Add((string)keys[i], Convert.ToInt32(values[i]));
 		}
	}
	
	private void PopulateAchievements(string incomingAchievements)
	{
		ArrayList achievementsData = (ArrayList)JSON.JsonDecode(incomingAchievements); 

		if (achievementsData == null)
			return;
			
		if (iAchievements != null)
		{
			iAchievements.Clear();	
		}
		else
		{
			iAchievements = new List<string>();	
		}	
 						
 		for (int i = 0 ; i < achievementsData.Count ; i++)
 		{
 			iAchievements.Add(achievementsData[i].ToString());
 		}
	}
		
	private void PopulateLeaderBoardEntries(string incomingEntriesForLeaderboard, LeaderboardType aType)
	{
		ArrayList leaderboardListData = (ArrayList)JSON.JsonDecode(incomingEntriesForLeaderboard);
		ArrayList leaderboardList = new ArrayList();
		Hashtable table;
		
		if (leaderboardListData == null)
			return;
			
		for (int i = 0 ; i < leaderboardListData.Count ; i++)
		{
			table = (Hashtable)leaderboardListData[i];
			LeaderboardEntry entry = new LeaderboardEntry();
			entry.username = (string)table["username"];
			entry.position = (string)table["position"];
			entry.score = (double)table["score"];
			leaderboardList.Add(entry);
		}
				
		switch (aType)
		{
			case LeaderboardType.Top20Entries:
			{
				if (iTop20EntriesForLeaderboard != null)
					iTop20EntriesForLeaderboard.Clear();
				else
					iTop20EntriesForLeaderboard = new List<LeaderboardEntry>();
		
				foreach(LeaderboardEntry entry in leaderboardList)
				{
					iTop20EntriesForLeaderboard.Add(entry);
				}
			}			
			break;
		
			case LeaderboardType.Top20Friends:
			{
				if (iTop20FriendsForLeaderboard != null)
					iTop20FriendsForLeaderboard.Clear();
				else
					iTop20FriendsForLeaderboard = new List<LeaderboardEntry>();
		
				foreach(LeaderboardEntry entry in leaderboardList)
				{
					iTop20FriendsForLeaderboard.Add(entry);
				}				
			}
			break;
			
			case LeaderboardType.Random20:
			{
				if (iRandom20ForLeaderboard != null)
					iRandom20ForLeaderboard.Clear();
				else
					iRandom20ForLeaderboard = new List<LeaderboardEntry>();
		
				foreach(LeaderboardEntry entry in leaderboardList)
				{
					iRandom20ForLeaderboard.Add(entry);
				}				
			}
			break;	
		}
	}

	private string ScreenOrientationToString(iPhoneScreenOrientation orientation)
	{
		string orientationString = null;
		
		switch (orientation)
		{
			case iPhoneScreenOrientation.Portrait:
				orientationString = "portrait";
				break;
				
			case iPhoneScreenOrientation.LandscapeLeft:
				orientationString = "landscapeLeft";
				break;
				
			case iPhoneScreenOrientation.LandscapeRight:
				orientationString = "landscapeRight";
				break;
				
			case iPhoneScreenOrientation.PortraitUpsideDown:
				orientationString = "portraitUpsideDown";
				break;				
		}
		return orientationString;		
	}		
}		

