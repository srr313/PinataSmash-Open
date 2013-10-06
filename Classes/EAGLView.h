//
//  EAGLView.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright BlitShake LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "ESRenderer.h"
#import "FlowManager.h"
#import "GameCommon.h"
#import "OpenGLCommon.h"

extern Vector2D GetGLDimensions();
extern float GetGLWidth();
extern float GetGLHeight();
extern float GetContentScaleFactor();
extern float ToScreenScaleX(float x);
extern float ToScreenScaleY(float y);
extern float ToGameScaleX(float x);
extern float ToGameScaleY(float y);

@class EAGLView;

extern Boolean g_bInBackground;
extern EAGLView* sGLView;

#define GL_VIEW (sGLView)

@class Game;
@class ImageControl;
@class ParticleManager;
@class Screen;

typedef enum {
    kSimpleTransition = 0,
    kCategoryTransition,
} eTransitionType;

typedef enum {
    kStandard,
    kRetina,
    kIPad,
} eDisplayMode;

extern Boolean IsDeviceIPad();

extern eDisplayMode GetDisplayMode();

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView<FlowManager, UIAccelerometerDelegate> 
{    
@private
    id <ESRenderer> renderer;

    Game* game;
    int level;
    eTool tool;
    NSString* episodePath;
    int episodeIndex;
    Screen* screen;
    
    eFlowState previousFlowState;
    eFlowState flowState;
    eFlowState nextFlowState;
    Boolean changingFlowState;

    BOOL animating;
    BOOL displayLinkSupported;
    NSInteger animationFrameInterval;
    // Use of the CADisplayLink class is the preferred method for controlling your animation timing.
    // CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
    // The NSTimer class is used only as fallback when running on a pre 3.1 device where CADisplayLink
    // isn't available.
    id displayLink;
    NSTimer *animationTimer;
    
    CGPoint touchLocation;
    CGPoint touchPreviousLocation;
    Boolean firstTouch;
    
    float simulationSpeed;
    float simulationSpeedTimeleft;
    
    ImageControl* fadeControl;
    
    NSMutableArray* popupElements;
    TextControl* loadingText;
    ImageControl* kidPopup;
    ImageControl* kidBubble;
    
    eTransitionType transitionType;
    float categoryDelayElapsed;
    Boolean hasLoadedAssets;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (nonatomic) eFlowState flowState;
@property (nonatomic) eTool tool;
@property (nonatomic) int episodeIndex;

-(void)changeFlowState:(eFlowState)newState;
-(Boolean)changingFlowState;
-(void)startAnimation;
-(void)stopAnimation;
-(void)drawView:(float)timeElapsed;
-(void)update:(id)sender;
-(void)setSimulationSpeed:(float)speed withDuration:(float)duration;
-(Boolean)inGame;
-(void)setLevel:(int)lvl;
-(void)setEpisodePath:(NSString*)path;
-(void)setEpisodeIndex:(int)index;

- (void)touchesBegan:(CGPoint)location;
- (void)touchesEnded:(CGPoint)location;
- (void)touchesMoved:(CGPoint)location andPreviousLocation:(CGPoint)previousLocation;

- (void)crystalUiDeactivated;

@end
