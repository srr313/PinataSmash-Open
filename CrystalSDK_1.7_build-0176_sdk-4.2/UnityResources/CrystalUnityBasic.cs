/*
 *  CrystalUnityBasic.cs
 *
 *  Created by Gareth Reese
 *  Copyright 2009 Chillingo Ltd. All rights reserved.
 *
 */


using System;
using UnityEngine; 


/**
 * @brief The interface to all of the Crystal SDK functionality.
 */
public class CrystalUnityBasic : MonoBehaviour 
{
	public string lastIncomingChallenge;
	public string startedFromChallenge;
	public bool popoversActivated;

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
		AchievementsUi		///< Opens up the Achievements tab
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
	
	public void Update()
	{
		// Called every frame so we need to make sure that we only check what we need to to ensure good performance
		// If you're not using challenges then you can comment out the CCChallengeNotification & CCStartedFromChallenge code below
		// If you're not using the popoversActivated property you can comment out the CCStartedFromChallenge code
		
		if (Time.frameCount % 30 == 0)
		{
			string incomingChallenge = PlayerPrefs.GetString("CCChallengeNotification");
			if (incomingChallenge != "")
			{
				lastIncomingChallenge = incomingChallenge;
				PlayerPrefs.SetString("CCChallengeNotification", "");
				
				//////////////////////////////////////////////////////////////////////////////
				// The user has started a challenge from the Crystal UI
				//
				// Call your incoming challenge handler script here or check 
				// the incomingChallenge attribute for an ID every so often
				//////////////////////////////////////////////////////////////////////////////
			}
		}
		
		else if (Time.frameCount % 30 == 10)	
		{
			if (startedFromChallenge == "")
				startedFromChallenge = PlayerPrefs.GetString("CCStartedFromChallenge");
				
			if (startedFromChallenge != "")
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
		
		else if (Time.frameCount % 30 == 20)
		{
			string popoversActivatedString = PlayerPrefs.GetString("CCPopoversActivated");
			bool popoversActivatedBool = (popoversActivatedString == "YES") ? true : false;
			
			if (popoversActivatedBool != popoversActivated)
			{
				Debug.Log("> CrystalUnity_Basic popovers activated " + popoversActivatedBool);
				popoversActivated = popoversActivatedBool;
				
				//////////////////////////////////////////////////////////////////////////////
				// The Crystal popovers have either been activated or deactivated
				// If you'd prefer to grey-out your main menu buttons when the popovers are
				// activated you can do it from here or check the popoversActivated property
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
		if (startedFromChallenge != "")
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
		if (lastIncomingChallenge != "")
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
			AddCommand("ActivateUi|" + (int)type);
		}
		else	
			Debug.Log("> CrystalUnityBasic ActivateUi" + type);
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
	 * @brief Post the result of the last challenge that the game was notified for
	 * The game will be notified of the challenge via the challengeStartedWithGameConfig: method of CrystalSessionDelegate.
	 * @param result The result of the challenge, either as a numerical value or as a number of seconds for time-based scores
	 * @param doDialog If true Crystal will display a dialog over the game user interface
	 */
	public void PostChallengeResultForLastChallenge(double result)
	{
		if (isOkToRun())
		{
			AddCommand("PostChallengeResultForLastChallenge|" + result);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostChallengeResultForLastChallenge" + result);
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
		if (isOkToRun())
		{
			AddCommand("PostAchievement|" + achievementId + "|" + wasObtained + "|" + description + "|" + alwaysPopup);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostAchievement" + achievementId + ", " + wasObtained + ", " + description + ", " + alwaysPopup);
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
	 */
	public void PostLeaderboardResult(string leaderboardId, float result, bool lowestValFirst)
	{
		if (isOkToRun())
		{
			AddCommand("PostLeaderboardResult|" + leaderboardId + "|" + result + "|" + lowestValFirst);
		}
		else
		{
			Debug.Log("> CrystalUnityBasic PostLeaderboardResult" + leaderboardId + ", " + result + ", " + lowestValFirst);
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
		}
		
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
	

	private static CrystalUnityBasic _singleton = null;

	public CrystalUnityBasic() 
	{
		if (_singleton != null) {
			return;
		}
		_singleton = this;
	} 
	
	/**
	 * @brief Get hold of the singleton instance
	 */
	public static CrystalUnityBasic singleton 
	{
		get {
			if (_singleton == null) {
				new CrystalUnityBasic();
			}
			return _singleton;
		}
	}	
}
