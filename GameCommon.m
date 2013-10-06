//
//  GameCommon.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/19/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import "GameCommon.h"
#import "EAGLView.h"

Color3D GetAchievementColor(eAchievement achievement) {
    static Color3D medalColors[kAchievement_Gold-kAchievement_Bronze+1];
    
    medalColors[0] = Color3DMake(0.8f, 0.45f, 0.3f, 1.0f);
    medalColors[1] = Color3DMake(0.9f, 0.9f, 1.0f, 1.0f);
    medalColors[2] = Color3DMake(1.0f, 0.7f, 0.05f, 1.0f);
    
    return medalColors[achievement-kAchievement_Bronze];
}

NSString* GetWebPath(NSString* filename) {
    NSString* path = @"http://www.blitshake.com/fb_images/";
    return [path stringByAppendingString:filename];
}

NSString* GetGameTimeFormat(int timeValue, bool showEntireClock) {
    int minutes = (timeValue / 60);
    int seconds = (timeValue % 60);
    
    NSString* minutesString = @"";
    if (minutes > 0 || showEntireClock) {
        minutesString = [NSString stringWithFormat:@"%d:", minutes];
    }

    NSString* secondsString = nil;
    if (seconds < 10 && (minutes > 0 || showEntireClock)) {
        secondsString = [NSString stringWithFormat:@"0%d", seconds];
    }
    else {
        secondsString = [NSString stringWithFormat:@"%d", seconds];
    }
        
    return [NSString stringWithFormat:@"%@%@", minutesString, secondsString];
}

extern Boolean IsGameShadowsEnabled() {
    return false;
//    return !IsDeviceIPad();
}

extern Boolean IsGameMotionBlurEnabled() {
    return false;
//    return !IsDeviceIPad();
}