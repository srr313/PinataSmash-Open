//
//  AchievementScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/21/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "AchievementScreen.h"
#import "Achievement.h"
#import "EAGLView.h"
#import "FacebookWrapper.h"
#import "Game.h"
#import "GameCommon.h"
#import "JiggleAnimation.h"
#import "Localize.h"
#import "MetagameManager.h"
#import "ScrollComponent.h"

#ifdef DO_ANALYTICS
    #import "FlurryAPI.h"
#endif    


@interface AchievementControl : ScreenControl { //<FBDialogDelegate> {
    TextControl* text;
    ImageControl* icon;
    ButtonControl* facebookButton;
    NSString* description;
}
-(id)initAt:(Vector2D)pos withDescription:(NSString*)desc andImage:(NSString*)image andEarned:(Boolean)earned;
-(void)postAchievementAction:(ButtonControl*)control;
@end

@implementation AchievementControl
-(id)initAt:(Vector2D)pos withDescription:(NSString*)desc andImage:(NSString*)image andEarned:(Boolean)earned {
    if (self == [super init]) {    
        description = desc;
        [description retain];
        
        position = pos;
        basePosition = pos;
        
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:ZeroVector() 
            withTexture:kTexture_AchievementPanel];
        [bgImage setColor:COLOR3D_GREEN];
        [self addChild:bgImage];
        [bgImage release];
            
        icon = [[ImageControl alloc] 
            initAt:Vector2DMake(-132.0f,0.0f) withTexture:(earned)?GetTextureId(image):kTexture_QuestionMark];
        icon.hasShadow = true;
        icon.tilting = true;
        [self addChild:icon];
        if (earned) {
            [icon bounce];
        }
        
        facebookButton = [[ButtonControl alloc] 
            initAt:Vector2DMake(110.0f,0.0f) withTexture:kTexture_Facebook andText:kLocalizedString_Null];
        facebookButton.hasShadow = true;
        [facebookButton setResponder:self andSelector:@selector(postAchievementAction:)];
        [facebookButton setEnabled:earned];
        
//        if (earned) {
//            facebookButton.jiggling = true;
//            [facebookButton.jiggler jiggleFreq:5.0f andAmplitude:0.05f andDuration:FLT_MAX];        
//        }
        
        [self addChild:facebookButton];
            
        Vector2D textPos = Vector2DMake(-20.0f, 0.0f);
        text = [[TextControl alloc] 
            initAt: textPos
            withString:desc
            andDimensions:Vector2DMake(150.0f,64.0f) 
            andAlignment:UITextAlignmentLeft 
            andFontName:DEFAULT_FONT andFontSize:18];
        text.hasShadow = true;
        text.autoShadow = true;
        text.jiggling = false;
        [self addChild:text];
    }
    return self;
}

-(void)postAchievementAction:(ButtonControl*)control {
#ifdef DO_ANALYTICS
    [FlurryAPI logEvent:@"POST_ACHIEVEMENT"];
#endif    

//    eLocalizedString localized = LocalizeTextArgs(kLocalizedString_FB_Achievement, description);
//    [FacebookWrapper publishToFacebook:localized andImagePath:GetWebPath(@"Icon.png") andDelegate:self];
}

-(void)dealloc {
    [text release];
    [icon release];
    [facebookButton release];
    [description release];
    [super dealloc];
}
@end

/////////////////////////////////////////////////

@interface AchievementScreen()
-(void)backAction:(ButtonControl*)control;
-(void)initAchievementControls;
@end

@implementation AchievementScreen

-(void)backAction:(ButtonControl *)control {
    [flowManager changeFlowState:kFlowState_Title];
}

-(id)initWithFlowManager:(id<FlowManager>)fm {
    if (self == [super initWithFlowManager:fm]) {    
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:Vector2DMul(GetGLDimensions(), 0.5f) 
            withTexture:kTexture_MenuBackground];
        bgImage.alphaEnabled = false;            
        [self addControl:bgImage];
        [bgImage release];
        
        [self initAchievementControls];
        
//        Vector2D titleTextPos = Vector2DMake(GetGLDimensions().x*0.5f, 430.0f);
//        TextControl* titleText = [[TextControl alloc] 
//            initAt:titleTextPos 
//            withText:kLocalizedString_Achievements
//            andArg:nil
//            andDimensions:Vector2DMake(256.0f,64.0f) 
//            andAlignment:UITextAlignmentCenter 
//            andFontName:DEFAULT_FONT andFontSize:32];
//        titleText.hasShadow = true;
//        titleText.tilting = true;
//        titleText.jiggling = true;
//        [titleText setColor:Color3DMake(0.0f, 0.0f, 0.0f, 1.0f)];
//        [titleText setShadowColor:Color3DMake(0.0f, 0.0f, 0.0f, 0.2f)];
//        [titleText shadowScale:1.03f];
//        [titleText bounce:1.0f];
//        [self addControl:titleText];  
//        [titleText release];
//        titleText = nil;  
        
        Vector2D backPosition = Vector2DMake(50.0f,35.0f);
        ButtonControl* backButton = [[ButtonControl alloc] 
            initAt:backPosition withTexture:kTexture_BackButton andText:kLocalizedString_Null];
        [backButton setResponder:self andSelector:@selector(backAction:)];
        backButton.tilting = true;
        [self addControl:backButton];
        [backButton release];
        backButton = nil;
    }
    return self;    
}

-(void)initAchievementControls {
    ScrollComponent* achievementList = [[ScrollComponent alloc] init];
    achievementList.direction = kDirection_Vertical;
    achievementList.screenPageOffset = 0.15f;
    achievementList.highlightCurrentPage = false;
    achievementList.lockToNearestPage = false;
    [self addControl:achievementList];
    [achievementList release];
    
    NSMutableArray* achievements = METAGAME_MANAGER.achievements;
    Vector2D position = Vector2DMake(0.5f*GetGLWidth(),GetGLHeight()-0.25f*GetImageDimensions(kTexture_AchievementPanel).y);
    int index = 0;
    for (Achievement* achievement in achievements) {
        AchievementControl* control = [[AchievementControl alloc] 
            initAt:position 
                withDescription:achievement.description
                andImage:achievement.imageName
                andEarned:achievement.earned];
        [achievementList addControl:control toPage:index];
        [control release];
        
        ++index;
    }
}

@end
