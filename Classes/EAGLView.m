//
//  EAGLView.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright BlitShake LLC 2010. All rights reserved.
//

#import "EAGLView.h"

#import "EpisodeSelectionScreen.h"
#import "ES1Renderer.h"
#import "CreditsScreen.h"
#import "Game.h"
#import "GameoverScreen.h"
#import "GameParameters.h"
#import "GameScreen.h"
#import "AchievementScreen.h"
#import "JiggleAnimation.h"
#import "LevelLoader.h"
#import "LevelSelectionScreen.h"
#import "LevelEndScreen.h"
#import "Particles.h"
#import "PauseScreen.h"
#import "PregameScreen.h"
#import "Screen.h"
#import "Sounds.h"
#import "SplashScreen.h"
#import "TitleScreen.h"

#define SUPPORT_HIGH_RES

#define CATEGORY_SWITCH_DELAY 0.55f

Boolean         g_bInBackground = false;
EAGLView*       sGLView = nil;

@interface EAGLView()
-(void)executeNextFlowState;
-(void)releaseLastGame;
-(Boolean)readyForNextFlowState;
-(Boolean)isGameCategory:(eFlowState)state;
-(Boolean)isUICategory:(eFlowState)state;
-(void)drawTouchTrail;
-(void)companySplashEnd:(id)owner;
@end

@implementation EAGLView

@synthesize animating, flowState, tool, episodeIndex;
@dynamic animationFrameInterval;

static float        sScreenWidth = 0.0f;
static float        sScreenHeight = 0.0f;
static eDisplayMode sDisplayMode;
static float        sScreenScaleX = 0.0f;
static float        sScreenScaleY = 0.0f;

Vector2D GetGLDimensions() { 
    return Vector2DMake(GetGLWidth(),GetGLHeight()); 
} 

float GetGLWidth() {
    return 320.0f;  //sGLView.contentScaleFactor*sGLView.bounds.size.width; 
}

float GetGLHeight() { 
    return 480.0f;  //sGLView.contentScaleFactor*sGLView.bounds.size.height; 
}

float GetContentScaleFactor() {
    return sGLView.contentScaleFactor;
}

inline float ToScreenScaleX(float x) {
    return x * sScreenScaleX;
}

inline float ToScreenScaleY(float y) {
    return y * sScreenScaleY; 
}

inline float ToGameScaleX(float x) {
    return x / sScreenScaleX;
}

inline float ToGameScaleY(float y) {
    return y / sScreenScaleY;
}

Boolean IsDeviceIPad() {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  }
#endif
  return NO;
}

eDisplayMode GetDisplayMode() {
    return sDisplayMode;
}

////////////////////////////////////////////////////////////////

-(Boolean)inGame {
    return (flowState == kFlowState_Game);
}

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{    
    sGLView = self;


    if (self == [super initWithCoder:coder])
    {    
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];    
    
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

        eaglLayer.opaque = TRUE;
        
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        {
            int w = 320;
            int h = 480;
            
            sScreenWidth    = [UIScreen mainScreen].bounds.size.width;
            sScreenHeight   = [UIScreen mainScreen].bounds.size.height;            

            float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            // Can't detect screen res in pre 3.2 devices, but they are all 320x480 anyway.
            if (osVersion >= 3.2f) {
                UIScreen* mainSceen = [UIScreen mainScreen];
                // switch width and height since we're interested in portrait mode
                w   = mainSceen.currentMode.size.width;
                h   = mainSceen.currentMode.size.height;
                
                // hack since we should be in portrait mode
//                if (sScreenWidth > sScreenHeight) {
//                    float tmp = sScreenWidth;
//                    sScreenWidth    = sScreenHeight;
//                    sScreenHeight   = tmp;
//                }
                
            }
            else {
                w   = 320.0f;
                h   = 480.0f;
            }
            
            sDisplayMode = kStandard;
            
            if (fabsf(sScreenWidth-768.0f) < 0.01f) {
                sDisplayMode = kIPad;            
            }
            
        #ifdef SUPPORT_HIGH_RES
            if ( sScreenWidth != w && !IsDeviceIPad() ) {
                self.contentScaleFactor = w/320.0f;
                sScreenWidth    *= self.contentScaleFactor;
                sScreenHeight   *= self.contentScaleFactor;            
                
                if (fabsf(self.contentScaleFactor-2.0f) < 0.01f) {
                    sDisplayMode = kRetina;
                }
            }
        #endif
            
            sScreenScaleX = (sScreenWidth / GetGLWidth());            
            sScreenScaleY = (sScreenHeight / GetGLHeight());                        
        }
        
        renderer = [[ES1Renderer alloc] init];

        if (!renderer)
        {
            [self release];
            return nil;
        }
        
        [LevelLoader loadAll];

        animating               = FALSE;
        displayLinkSupported    = FALSE;
        animationFrameInterval  = 1;
        displayLink             = nil;
        animationTimer          = nil;
        changingFlowState       = false;
        previousFlowState       = kFlowState_Undefined;
        
        fadeControl = [[ImageControl alloc] 
                        initAt:Vector2DMul(GetGLDimensions(),0.5f) 
                        withTexture:kTexture_White];
        fadeControl.baseScale = sScreenHeight/GetTextureDimensions(kTexture_White).y;
        [fadeControl setColor:COLOR3D_BLACK];
        fadeControl.baseAlpha = 0.0f;
                
        loadingText = [[TextControl alloc]
                       initAt:Vector2DMake(0.5f*GetGLWidth(),320.0f) 
                       withString:@"Loading..." 
                       andDimensions:Vector2DMake(GetGLWidth(),26.0f) 
                       andAlignment:UITextAlignmentCenter 
                       andFontName:DEFAULT_FONT 
                       andFontSize:24.0f];        
        [loadingText setColor:COLOR3D_BLUE];
        loadingText.baseAlpha   = 0.0f;
        loadingText.jiggling    = true;
        
        kidBubble = [[ImageControl alloc] 
                       initAt:Vector2DMake(0.5f*GetGLWidth(),320.0f)
                       withTexture:kTexture_SpeechBox];
        kidBubble.baseAlpha = 0.0f;
        kidBubble.jiggling  = true;        
        
        kidPopup = [[ImageControl alloc] 
                     initAt:Vector2DMake(0.5f*GetGLWidth(),200.0f)
                     withTexture:kTexture_Kid4];
        kidPopup.baseAlpha = 0.0f;
        kidPopup.jiggling  = true;        
        
        popupElements = [[NSMutableArray alloc] init];
        [popupElements addObject:kidBubble];
        [popupElements addObject:loadingText];
        [popupElements addObject:kidPopup];        
        
        simulationSpeed         = 1.0f;
        simulationSpeedTimeleft = FLT_MAX;
        tool                    = kTool_Bat;
        episodeIndex = 0;

        // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
        // class is used as fallback when it isn't available.
        NSString *reqSysVer = @"3.1";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
            displayLinkSupported = TRUE;
        
        categoryDelayElapsed    = 0.0f;                          
        transitionType          = kSimpleTransition;
        flowState               = kFlowState_Undefined;   
        nextFlowState           = kFlowState_Undefined;
        [self changeFlowState:kFlowState_Undefined]; 

        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0f/40)];
        [[UIAccelerometer sharedAccelerometer] setDelegate:self];
        
        InitializeSounds();
        [GameParameters initSingleton];
    }

    return self;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	const float threshold = 1.5f;
	Boolean isShake = false;
	
    static float xOld = 0.0f;
    static float yOld = 0.0f;
    static float zOld = 0.0f;
    
    if (xOld!=0.0f || yOld!=0.0f || zOld!=0.0f) {
        if (fabsf(acceleration.x-xOld) > threshold * 0.5f ) {
            isShake = true;
        }
        else if (fabsf(acceleration.y-yOld) > threshold * 0.5f) {
            isShake = true;
        }
        else if (fabsf(acceleration.z-zOld) > threshold * 0.5f) {
            isShake = true;
        }
    }    
    xOld = acceleration.x;
    yOld = acceleration.y;
    zOld = acceleration.z;
    
//    NSLog(@"(%f,%f,%f)\n",acceleration.x,acceleration.y,acceleration.z);
    
    if ([self inGame]) {
        if (isShake) {
            [game shake];
        } 
    }
}

-(void)setSimulationSpeed:(float)speed withDuration:(float)duration {
    simulationSpeed = speed;
    simulationSpeedTimeleft = duration;
}

- (void)executeNextFlowState {  
    if (!changingFlowState) {
        #ifdef DEBUG_BUILD                    
            NSLog(@"executeNextFlowState:Not changing flow state.");
        #endif
        
        return;
    }
  
    if ( ![self inGame] ) {
        [screen release];
        screen = nil;
    }

    switch (nextFlowState) {
    case kFlowState_CrystalSplash:
        {
            break;
        }
    case kFlowState_CompanySplash:
        {
            SplashScreen* splash = [[SplashScreen alloc]  initWithFlowManager:self 
                                            andImage:kTexture_CompanySplash
                                            andDelay:0.0f];            
            [splash setResponder:self andSelector:@selector(companySplashEnd:)];
            screen = splash;
            break;
        }
    case kFlowState_Title:
        {
            if (flowState == kFlowState_Undefined || flowState == kFlowState_CompanySplash) {
                [[SimpleAudioEngine sharedEngine] playBackgroundMusic:
                    [[NSBundle mainBundle] pathForResource:@"MENU_LOOP" ofType:@"wav"] loop:true];        
            }
            
            [self releaseLastGame];
            screen = [[TitleScreen alloc] initWithFlowManager:self];
            break;
        }
    case kFlowState_EpisodeSelection:
        {
            screen = [[EpisodeSelectionScreen alloc] initWithFlowManager:self];
            break;
        }
    case kFlowState_LevelSelection:
        {
            if (flowState != kFlowState_EpisodeSelection) {
                [[SimpleAudioEngine sharedEngine] playBackgroundMusic:
                    [[NSBundle mainBundle] pathForResource:@"MENU_LOOP" ofType:@"wav"] loop:true];        
            }
        
            [self releaseLastGame];
            screen = [[LevelSelectionScreen alloc] initWithFlowManager:self andEpisodePath:episodePath];
            break;
        }
    case kFlowState_Pregame:
        {
            if (flowState == kFlowState_LevelSelection) {
                [[SimpleAudioEngine sharedEngine] playBackgroundMusic:
                    [[NSBundle mainBundle] pathForResource:@"GAME_LOOP" ofType:@"wav"] loop:true];             
            }        
        
            [self releaseLastGame];
            game = [[Game alloc] 
                initWithWidth: GetGLWidth()     //self.bounds.size.width 
                andHeight: GetGLHeight()        //self.bounds.size.height 
                andView:self ];
            game.screen = [[GameScreen alloc] initWithFlowManager:self andGame:game];
            [game setLevel:level inEpisode:episodePath];
            screen = [[PregameScreen alloc] initWithFlowManager:self andGame:game];
            break;
        }
    case kFlowState_Game:
        {                   
            screen = game.screen;
            [game setToolType:tool];
            break;            
        }
        break;
    case kFlowState_GameResume:
        {
            screen = game.screen;
            nextFlowState = kFlowState_Game;
            break;
        }
    case kFlowState_Pause:
        {
            screen = [[PauseScreen alloc] initWithFlowManager:self andGame:game];            
            break;
        }
    case kFlowState_Gameover:
        {
            screen = [[GameoverScreen alloc] initWithFlowManager:self andGame:game];            
            break;
        }
    case kFlowState_LevelEnd:
        {
            screen = [[LevelEndScreen alloc] initWithFlowManager:self andGame:game];            
            break;        
        }
    case kFlowState_Achievement:
        {
            screen = [[AchievementScreen alloc] initWithFlowManager:self];                        
            break;
        }   
    case kFlowState_Credits:
        {
            screen = [[CreditsScreen alloc] initWithFlowManager:self];                        
            break;
        }
    default: break;
    }
    
    flowState = nextFlowState;
    changingFlowState = false;
}

-(Boolean)readyForNextFlowState {
    if (transitionType == kSimpleTransition) {
        return (fadeControl.fade == kFade_Stop);
    }
    else if (transitionType == kCategoryTransition) {
        return (fadeControl.fade == kFade_Stop && categoryDelayElapsed > CATEGORY_SWITCH_DELAY);        
    }
    return false;
}

- (void)drawView:(float)timeElapsed
{
    if (g_bInBackground)
            return;

    float adjustedTimeElapsed = simulationSpeed*timeElapsed;
    [renderer render:game 
                afterTimeElapsed:adjustedTimeElapsed 
                withParticleManager:PARTICLE_MANAGER 
                andScreen:screen
                andFilter:fadeControl
                andPopupElements:popupElements];
}

- (void)update:(id)sender {
    float timeElapsed = (animationFrameInterval/60.0f);

    if (simulationSpeed != 1.0f) {
        simulationSpeedTimeleft -= timeElapsed;
        if (simulationSpeedTimeleft <= 0) {
            simulationSpeed = 1.0f;
            [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_MotionSpeedup)]; 
        }
    }
    
    float adjustedTimeElapsed = simulationSpeed*timeElapsed;
    
    if (nextFlowState!=flowState) {
        if ([self readyForNextFlowState]) {
            [self executeNextFlowState];    
            
            if (fadeControl.fade == kFade_Stop) {
                [fadeControl setFade:kFade_Out];
                
                if (loadingText.color.alpha > 0.0f) {
                    for (ScreenControl* control in popupElements) {
                        [control    setFade:kFade_Out];
                    }                    
                }
            }
        }
        else if (transitionType == kCategoryTransition 
                    && fadeControl.fade == kFade_Stop 
                    && !hasLoadedAssets ) {
            if ([self isGameCategory:nextFlowState]) {
                [renderer initGameTextures];
            }
            else {
                [renderer initUITextures];
            }  
            hasLoadedAssets = true;     
        }
        categoryDelayElapsed += timeElapsed;             
    }

    if ([self inGame]) {
        [game simUpdate:adjustedTimeElapsed];
    }
    
    [PARTICLE_MANAGER tick:adjustedTimeElapsed];
    
    [screen         tick:adjustedTimeElapsed];
    [fadeControl    tick:timeElapsed];

    for (ScreenControl* control in popupElements) {
        [control    tick:timeElapsed];
    }    
    
    [self drawView:adjustedTimeElapsed];    
}

- (void)layoutSubviews
{
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:0];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;

        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        if (displayLinkSupported)
        {
            // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
            // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
            // not be called in system versions earlier than 3.1.

            displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(update:)];
            [displayLink setFrameInterval:animationFrameInterval];
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        }
        else
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(update:) userInfo:nil repeats:TRUE];

        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            animationTimer = nil;
        }

        animating = FALSE;
    }
}

// Handles the start of a touch
- (void)touchesBegan:(CGPoint)location {
    // changing state
    if (nextFlowState!=flowState) {
        return;
    }

    CGRect bounds = [self bounds];
    
    firstTouch = YES;
    
    //Convert touch point from UIView referential to OpenGL one (upside-down flip)
    touchLocation = location; 
    touchLocation.x = ToGameScaleX(self.contentScaleFactor*touchLocation.x);
    touchLocation.y = ToGameScaleY(self.contentScaleFactor*(bounds.size.height - touchLocation.y));
    
    TapEvent evt;
    evt.location = touchLocation;
    evt.type = kTapEventType_Start;

    // consumed?
    if ([screen processEvent:evt]) {
        return;
    }
    
    if ([self inGame]) {
        [game triggerAt:evt];
    }
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // changing state
    if (nextFlowState!=flowState) {
        return;
    }

    UITouch* touch = [[event touchesForView:self] anyObject];
    [self touchesBegan:[touch locationInView:self]];
}

- (void)touchesEnded:(CGPoint)location
{
    // changing state
    if (nextFlowState!=flowState) {
        return;
    }

    CGRect bounds = [self bounds];
    
    firstTouch  = YES;
    
    //Convert touch point from UIView referential to OpenGL one (upside-down flip)

    touchLocation   = location;
    touchLocation.x = ToGameScaleX(self.contentScaleFactor*touchLocation.x);
    touchLocation.y = ToGameScaleY(self.contentScaleFactor*(bounds.size.height - touchLocation.y));
        
    TapEvent evt;
    evt.location = touchLocation;
    evt.type = kTapEventType_End;

    // consumed?
    if ([screen processEvent:evt]) {
        return;
    }
    
    if ([self inGame]) {
        [game triggerAt:evt];
    }
}

// Handles the start of a touch
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // changing state
    if (nextFlowState!=flowState) {
        return;
    }

    UITouch* touch = [[event touchesForView:self] anyObject];
    [self touchesEnded:[touch locationInView:self]];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(CGPoint)location andPreviousLocation:(CGPoint)previousLocation
{  
      
    CGRect bounds = [self bounds];
            
    //Convert touch point from UIView referential to OpenGL one (upside-down flip)
    if (firstTouch) {
        firstTouch = NO;
    } else {
        touchLocation   = location;
        touchLocation.x = ToGameScaleX(self.contentScaleFactor*touchLocation.x);
        touchLocation.y = ToGameScaleY(self.contentScaleFactor*(bounds.size.height - touchLocation.y));
    }
    
    touchPreviousLocation   = previousLocation;
    touchPreviousLocation.x = ToGameScaleX(self.contentScaleFactor*touchPreviousLocation.x);
    touchPreviousLocation.y = ToGameScaleY(self.contentScaleFactor*(bounds.size.height - touchPreviousLocation.y));

    [self drawTouchTrail];

    TapEvent evt;
    evt.location = touchLocation;
    evt.type = kTapEventType_Move;
    
    if ([screen processEvent:evt]) {
        return;
    }
    
    if ([self inGame]) {
        [game triggerAt:evt];
    }
}
 
// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
    UITouch* touch = [[event touchesForView:self] anyObject];
    [self touchesMoved:[touch locationInView:self] andPreviousLocation:[touch previousLocationInView:self]];
}

-(void)drawTouchTrail {
    if (game.sugarHighMode) {
        return;
    }

    static NSDate* startDate = nil;
    if (!startDate) {
        startDate = [[NSDate date] retain];                
    }
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:startDate];
    
    if (timeInterval > 0.05f) {
        [startDate release];
        startDate = [currentDate retain];
    
        Particle* p = nil;
        if (flowState == kFlowState_Game) {
            Color3D color = Color3DMake(random()/(float)RAND_MAX,random()/(float)RAND_MAX,random()/(float)RAND_MAX,1.0f);
            p = [PARTICLE_MANAGER
                    NewParticleAt:Vector2DMake(touchLocation.x,touchLocation.y)
                        andVelocity:Vector2DMake(0.0f,-150.0f) 
                        andAngle:TWO_PI*random()/RAND_MAX 
                        andScaleX:CONFETTI_MAX_SIZE 
                        andScaleY:CONFETTI_MAX_SIZE 
                        andColor:color 
                        andTotalLifetime:0.5f 
                        andType:kParticleType_Confetti
                        andTexture:kTexture_ConfettiBegin+rand()%(kTexture_ConfettiEnd-kTexture_ConfettiBegin)];                 
        }
        else {
            p = [PARTICLE_MANAGER
                    NewParticleAt:Vector2DMake(touchLocation.x,touchLocation.y)
                        andVelocity:Vector2DMake(0.0f,-150.0f) 
                        andAngle:TWO_PI*random()/RAND_MAX 
                        andScaleX:CANDY_MAX_SIZE 
                        andScaleY:CANDY_MAX_SIZE 
                        andColor:COLOR3D_WHITE 
                        andTotalLifetime:0.5f 
                        andType:kParticleType_Candy
                        andTexture:kTexture_CandyBegin+rand()%(kTexture_CandyEnd-kTexture_CandyBegin)]; 
        }
        p.layer = kLayer_UI;
        [PARTICLE_MANAGER addParticle:p];
        [p release];
    }
}

- (Boolean)changingFlowState {
    return changingFlowState;
}

-(eFlowState)previousFlowState {
    return previousFlowState;
}

- (Boolean)isGameCategory:(eFlowState)state {
    return (kFlowState_GameCategory <= state && state < kFlowState_GameCategoryEnd);
}

- (Boolean)isUICategory:(eFlowState)state {
    return kFlowState_UICategory <= state && state < kFlowState_UICategoryEnd;
}

- (eTransitionType)categoryChange:(eFlowState)newState fromState:(eFlowState)oldState {
    eFlowState cat1 = kFlowState_Undefined;
    if ([self isUICategory:newState]) {
        cat1 = kFlowState_UICategory;
    }
    else if ([self isGameCategory:newState]) {
        cat1 = kFlowState_GameCategory;
    }
    
    eFlowState cat2 = kFlowState_Undefined;    
    if ([self isUICategory:oldState]) {
        cat2 = kFlowState_UICategory;
    }
    else if ([self isGameCategory:oldState]) {
        cat2 = kFlowState_GameCategory;
    }  
    
    if (cat1 != cat2 && cat1 != kFlowState_Undefined && cat2 != kFlowState_Undefined) {
        return kCategoryTransition;
    }
    
    return kSimpleTransition;
}

- (void)changeFlowState:(eFlowState)newState {
    if (changingFlowState) {
        return;
    }

    if (nextFlowState != newState) {
        previousFlowState = flowState;
        changingFlowState = true;
        if (newState != kFlowState_Pause && newState != kFlowState_CompanySplash) {
            transitionType = [self categoryChange:newState fromState:previousFlowState];
            if (transitionType == kCategoryTransition) {
                categoryDelayElapsed = 0.0f;
                hasLoadedAssets = false;
                [[SimpleAudioEngine sharedEngine] pauseBackgroundMusic];                

                for (ScreenControl* control in popupElements) {
                    [control.jiggler jiggleFreq:15.0f andAmplitude:0.5f andDuration:0.25f];
                    [control    setFade:kFade_In];
                }                        
            }
            [fadeControl setFade:kFade_In];
        }
    }
    nextFlowState = newState;
}

-(void)releaseLastGame {
    if ([self inGame] 
            || flowState == kFlowState_LevelEnd 
            || flowState == kFlowState_Gameover 
            || flowState == kFlowState_Pause
            || flowState == kFlowState_Pregame)
    {
        [game release];
        game = nil;
    }
}

-(void)setLevel:(int)lvl {
    level = lvl;
}

-(void)setEpisodePath:(NSString*)path {
    episodePath = path;
}

-(void)setEpisodeIndex:(int)index {
    episodeIndex = index;
}

- (void)dealloc
{
    [fadeControl    release];
    [loadingText    release];
    [kidPopup       release];
    [kidBubble      release];    
    [popupElements  release];
    
    [renderer release];
    [PARTICLE_MANAGER release];
    [game release];
    [screen release];

    sGLView = nil;

    [super dealloc];
}

-(void)crystalUiDeactivated {
    [screen crystalUiDeactivated];
}

-(void)companySplashEnd:(id)owner {
    // todo - move crystal splash / or title here.
}

@end
