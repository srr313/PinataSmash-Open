//
//  Screen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/19/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ES1Renderer.h"
#import "FlowManager.h"
#import "Localize.h"
#import "OpenGLCommon.h"
#import "Sounds.h"
#import "Texture2D.h"

@class JiggleAnimation;

#define DEFAULT_FONT @"shears"   //@"sing"  //@"Marker Felt"

extern Color3D GetNextMultiplierColor(int m);

typedef enum {
    kTapEventType_Start = 0,
    kTapEventType_End,
    kTapEventType_Move,
    kTapEventType_Count,
} eTapEventType;

typedef struct {
    eTapEventType type;
    CGPoint location;
} TapEvent;

typedef enum {
    kFade_In = 0,
    kFade_Out,
    kFade_Stop,
} eFade;

@class Screen;

@interface ScreenControl : NSObject {
    Vector2D position;
    Vector2D basePosition;
    Vector2D dimensions;
    Color3D color;
    Boolean pulsing;
    float pulseT;
    float pulseRate;
    float baseScale;
    float scale;
    Boolean jiggling;
    JiggleAnimation* jiggler;
    eTexture texture;
    eFade fade;
    float fadeSpeed;
    float fadeDelay;
    float baseAlpha;
    NSMutableArray* children;
    Boolean hasShadow;
    Color3D shadowColor;
    float shadowScale;
    Boolean autoShadow;
    float shadowT;
    Color3D shadowStart;
    Color3D shadowEnd;
    float angle;
    float baseAngle;
    float angleT;
    Boolean tilting;
    Screen* parent;
    Boolean visible;
    Boolean enabled;
    Boolean alphaEnabled;
}
@property (nonatomic)Vector2D position;
@property (nonatomic)Vector2D basePosition;
@property (nonatomic)Boolean jiggling;
@property (nonatomic)Boolean pulsing;
@property (nonatomic)float pulseRate;
@property (nonatomic,assign) JiggleAnimation* jiggler;
@property (nonatomic)Boolean hasShadow;
@property (nonatomic)float scale;
@property (nonatomic)float baseScale;
@property (nonatomic)Color3D color;
@property (nonatomic)eTexture texture;
@property (nonatomic)float baseAlpha;
@property (nonatomic)float fadeSpeed;
@property (nonatomic,assign)NSMutableArray* children;
@property (nonatomic) float angle;
@property (nonatomic) float baseAngle;
@property (nonatomic) Boolean tilting;
@property (nonatomic,assign) Screen* parent;
@property (nonatomic) Boolean visible;
@property (nonatomic) Boolean enabled;
@property (nonatomic) Boolean autoShadow;
@property (nonatomic) Boolean alphaEnabled;
-(Vector2D)dimensions;
-(Boolean)isInside:(CGPoint)p;
-(void)tick:(float)timeElapsed;
-(void)render:(float)timeElapsed;
-(Boolean)processEvent:(TapEvent)evt;
-(void)setPulsing:(Boolean)flag;
-(Texture2D*)getLocalTexture2D;
-(void)setEnabled:(Boolean)flag;
-(Color3D)shadowColor;
-(void)setShadowColor:(Color3D)col;
-(void)shadowScale:(float)sca;
-(float)shadowScale;
-(void)setColor:(Color3D)col;
-(Color3D)color;
-(void)setFade:(eFade)flag;
-(void)setFadeSpeed:(float)speed;
-(void)setFadeDelay:(float)delay;
-(eFade)fade;
-(void)bounce:(float)amp;
-(void)bounce;
-(void)addChild:(ScreenControl*)child;
-(void)removeChild:(ScreenControl*)child;
@end

@interface ImageControl : ScreenControl {
    Boolean tiled;
    float scrolling;
}
@property (nonatomic) Boolean tiled;
-(id)initAt:(Vector2D)pos withTexture:(eTexture)tex;
@end

@interface TextControl : ScreenControl {
    Texture2D* texture2D;
}
-(id)initAt:(Vector2D)pos withString:(NSString*)str andDimensions:(Vector2D)dim
    andAlignment:(UITextAlignment)alignment andFontName:(NSString*)font andFontSize:(int)size;
-(id)initAt:(Vector2D)pos withText:(eLocalizedString)text andArg:(NSObject*)arg andDimensions:(Vector2D)dim
    andAlignment:(UITextAlignment)alignment andFontName:(NSString*)font andFontSize:(int)size;
-(void)resetTo:(Vector2D)pos withString:(NSString*)str andDimensions:(Vector2D)dim
    andAlignment:(UITextAlignment)alignment andFontName:(NSString*)font andFontSize:(int)size;    
@end

@interface ButtonControl : ScreenControl {
    id              responder;
    SEL             selector;
    TextControl*    textControl;
    Boolean         heldDown;
    Boolean         respondOnRelease;
    eSound          pressSound;
}
@property (nonatomic) Boolean respondOnRelease;
-(id)initAt:(Vector2D)pos withTexture:(eTexture)tex andText:(eLocalizedString)text;
-(id)initAt:(Vector2D)pos withTexture:(eTexture)tex andString:(NSString*)str;
-(void)setResponder:(id)resp andSelector:(SEL)sel;
-(void)setPressSound:(eSound)sound;
@end

@interface Screen : NSObject {
    NSMutableArray* controls;
    id<FlowManager> flowManager;
    float timeSpent;
}
-(id)initWithFlowManager:(id<FlowManager>)fm;
-(void)tick:(float)timeElapsed;
-(void)addControl:(ScreenControl*)control;
-(void)removeControl:(ScreenControl*)control;
-(NSMutableArray*)getControls;
-(Boolean)processEvent:(TapEvent)evt;
-(void)render:(float)timeElapsed;
-(void)crystalUiDeactivated;
@end
