//
//  Kid.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/5/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//
 
#import "Kid.h"
#import "CandyPile.h"
#import "Game.h"
#import "GameLevel.h"
#import "GameParameters.h"
#import "JiggleAnimation.h"
#import "Particles.h"
#import "Pinata.h"
#import "Screen.h"
#import "Tool.h"

//#define DRAW_KID_SHADOW

#define KID_HIT_DELAY       5.0f
#define KID_WARNING_DELAY   5.0f
#define KID_CHEER_DELAY     5.0f
#define LIGHT_SPIN_RATE     60.0f
#define KID_BOUNCE_HEIGHT   128.0f

static int KidFrames[KID_STAGES+2] = {
    0, 3, 9, 14, 15, 22
};

static int KidFrameDuration[KID_STAGES+1] = {
    4, 4, 4, 4, 4,
};


@interface Kid()
-(void)updateForm:(float)timeElapsed;
-(Vector2D)speakLocation;
-(void)drawLights:(float)timeElapsed;
-(void)postText:(NSString*)text at:(Vector2D)position withColor:(Color3D)color;
@end

@implementation Kid

@synthesize alive, position, currentStage, jumped;

-(id)initForGame:(Game*)g {
    if (self == [super init]) {
        game                    = g;
        scale                   = 1.0f;
        currentStage            = 0;
        currentFrameDuration    = 0;
        currentKidFrame         = 0;
        currentFramesElapsed    = 0;
        targetFrame             = 0;
        alive                   = true;  
        hitJiggle               = [[JiggleAnimation alloc] init];
        lastHitTime             = KID_HIT_DELAY;
        timeSinceWarning        = 0.0f;
        timeSinceCheer          = 0.0f;
        startedExpansion        = false;
        postedRuleMessage       = false;    
        lastCandy               = [game getCandyPile].numCandy;
        sugarRush               = false;
        sugarHigh               = false;
        spinTime                = 0.0f;
        jumpHeight              = 0.0f;
        jumped                  = false;
        startAnimation          = false;
        [self updateForm: 0.0f];        
    }
    return self;
}

-(void)tick:(float)timeElapsed {
    [simpleText tick:timeElapsed];
    [simpleTextBackground tick:timeElapsed];
    
    if (simpleText.fade == kFade_Stop && simpleText.color.alpha >= 1.0f) {
        [simpleText setFadeDelay:1.5f];
        [simpleText setFade:kFade_Out];

        [simpleTextBackground setFadeDelay:1.5f];        
        [simpleTextBackground setFade:kFade_Out];
    }
    
    [hitJiggle tick:timeElapsed];
    
    if (sugarHigh) {
        spinTime += timeElapsed;
    }
    
    if (currentKidFrame < targetFrame) {
        ++currentFramesElapsed;
        if (currentFramesElapsed>=currentFrameDuration) {
            ++currentKidFrame;
            currentFramesElapsed = 0;                     
        }
    }
    
    lastHitTime         += timeElapsed;
    timeSinceWarning    += timeElapsed;
    timeSinceCheer      += timeElapsed;
    
    CandyPile* pile = [game getCandyPile];  
    if (timeSinceWarning > KID_WARNING_DELAY) {
        if (pile.numCandy < 100.0f) {
            [self postText:@"More Candy!" at:[self speakLocation] withColor:COLOR3D_RED];        
            timeSinceWarning = 0.0f;
        }
        else if (!postedRuleMessage && game.gameLevel.rule.metric==kGameRule_Time && [game gameTime] > game.gameLevel.rule.silver) {
            [self postText:@"Time's Low!" at:[self speakLocation] withColor:COLOR3D_RED];        
            timeSinceWarning = 0.0f;                
            postedRuleMessage = true;
        }
        else if (!postedRuleMessage && game.gameLevel.rule.metric==kGameRule_Shots && game.tool.count > game.gameLevel.rule.silver) {
            [self postText:@"Almost out of shots!" at:[self speakLocation] withColor:COLOR3D_RED];        
            timeSinceWarning = 0.0f; 
            postedRuleMessage = true;
        }
        else if (pile.numCandy > lastCandy+75.0 && timeSinceCheer > KID_CHEER_DELAY) {
            static const int numMessages = 6;
            static const eLocalizedString sCheers[] = {
                @"Wow!",
                @"Nice!",
                @"Mmmm!",
                @"Yeah!",
                @"Oh Joy!",
                @"Radical!",
            };        
                  
            static int lastMessage = 0;
            int nextMessage = random()%numMessages;
            lastMessage = (lastMessage == nextMessage) ? (lastMessage+1)%numMessages : nextMessage;
            [self postText:sCheers[lastMessage] at:[self speakLocation] withColor:COLOR3D_GREEN];        
            
            timeSinceCheer = 0.0f;
        }
    }
        
    lastCandy = pile.numCandy;
    
    [self updateForm:timeElapsed];
}

- (void)nextStage {
    if (currentStage < KID_STAGES) {
        currentFrameDuration    = KidFrameDuration[currentStage];
        targetFrame             = KidFrames[currentStage+1];
        ++currentStage;    
    }
}

- (void)render:(float)timeElapsed {
    [simpleTextBackground render:timeElapsed];
    [simpleText render:timeElapsed];

    if (!alive) {
        return;
    }
    
    if (sugarHigh) {
        [self drawLights:timeElapsed];
    }
        
    if (kTexture_KidBegin+currentKidFrame >= kTexture_KidEnd) {
        return;
    }
        
    Texture2D* texture = GetTexture(currentKidFrame+kTexture_KidBegin);

#ifdef DRAW_KID_SHADOW
    if (!IsDeviceIPad()) {   // render shadow
        Vector2D shadowOffset = [ES1Renderer shadowOffset];     
    
        glLoadIdentity();        
        glTranslatef(ToScreenScaleX(position.x+shadowOffset.x), ToScreenScaleY(position.y+fabsf(shadowOffset.y)), 0.0f);
        glScalef(scale,scale,0.0f);
        glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, shadowColor.alpha); 
        [texture draw];
    }
#endif
    
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
    glScalef(scale,1.0f,0.0f);
    [texture draw];
}

-(void)drawLights:(float)timeElapsed {        
    float sugarHighTimeleft = (GAME_PARAMETERS.sugarHighDuration - game.sugarHighTime);
    if (sugarHighTimeleft < 1.5f && 
        sinf(5.0f*game.sugarHighTime/fmax(sugarHighTimeleft,0.75f)) < 0.0f) 
    {
        return;
    }

    Texture2D* texture = GetTexture(kTexture_White);   

    glDisable(GL_BLEND);
   
    float angle = LIGHT_SPIN_RATE*spinTime;
    float barWidth  = ToScreenScaleY(64.0f)/texture.pixelsHigh;
    float barLength = 16*ToScreenScaleX(GetGLWidth())/texture.pixelsWide;
    const int kSlices = 7;
    
    Color3D lightColors[kSlices];
    lightColors[0] = Color3DMake(1.0f, 0.0f, 0.0f, 1.0f);
    lightColors[1] = Color3DMake(1.0f, 0.54f, 0.0f, 1.0f);
    lightColors[2] = Color3DMake(1.0f, 1.0f, 0.0f, 1.0f);
    lightColors[3] = Color3DMake(0.0f, 1.0f, 0.0f, 1.0f);
    lightColors[4] = Color3DMake(0.0f, 0.0f, 1.0f, 1.0f);                
    lightColors[5] = Color3DMake(0.29f, 0.0f, 0.5f, 1.0f);
    lightColors[6] = Color3DMake(0.5f, 0.0f, 1.0f, 1.0f);        
            
    for (int i = 0; i < kSlices; ++i) {
        glLoadIdentity();
        glTranslatef(ToScreenScaleX(GetGLWidth()/2), -ToScreenScaleY(GetGLHeight()/2), 0.0f);
        glRotatef(angle,0.0f,0.0f,1.0f);
        glScalef(barLength, barWidth, 0.0f);
        glColor4f(lightColors[i].red,lightColors[i].green,lightColors[i].blue, 1.0f);
        [texture draw];          
        
        angle += 180.0f / kSlices;
    }
        
    glEnable(GL_BLEND);
}   

-(void)updateForm:(float)timeElapsed {
    if (jumped) {
        velocity    -= timeElapsed*400.0f;        
        if (velocity < 0.0f) {
            velocity        = 0.0f;
            startAnimation  = true;            
        }
        jumpHeight  += timeElapsed*velocity;
    }
        
    Texture2D* texture = GetTexture(currentKidFrame+kTexture_KidBegin);
    CandyPile* pile = [game getCandyPile];  
    
    float jiggle    = [pile getConsumptionScale] * hitJiggle.scale;      
    float candyLift = [pile getJiggleScale]*[pile getForegroundHeight]-30.0f;
        
    position.x = GetGLWidth()/2;
    position.y = ToGameScaleY(texture.pixelsHigh/2) * jiggle 
                    + fmaxf(candyLift, 0.0f)
                    + jumpHeight;

    if (startAnimation && currentStage < KID_STAGES) {
        [self nextStage];
        [self explode];
    }
        
    scale = jiggle;    
}

-(Vector2D)speakLocation {
    return Vector2DMake(position.x, 
                        position.y
                            +GetImageDimensions(currentKidFrame+kTexture_KidBegin).y/2
                            +ToScreenScaleY(30.0f));                    
}

-(void)explode {
    [PARTICLE_MANAGER 
        createCandyExplosionAt:position
        withAmount:75
        withLayer:kLayer_Game];

//    [PARTICLE_MANAGER createExplosionAt:position 
//                        withScale:1.0f 
//                        withLarge:true 
//                        withLayer:kLayer_Game];

    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_BalloonPop)];        
    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(kSound_CandyDrop)];
}

-(Boolean)isInside:(CGPoint)p {
    if (!alive) {
        return false;
    }

    Vector2D dim = GetImageDimensions(currentKidFrame+kTexture_KidBegin);
    return fabsf(p.x-position.x) <= dim.x/2*scale &&
           fabsf(p.y-position.y) <= dim.y/2*scale;    
}

-(Boolean)trigger {
//    if (alive && lastHitTime > KID_HIT_DELAY && timeSinceWarning > 1.5f) {
//        [hitJiggle stop];
//        [hitJiggle jiggleFreq:5.0f andAmplitude:0.25f andDuration:0.25f];
//        
//        static const int numMessages = 8;
//        static const eLocalizedString sCheers[] = {
//            @"Ouch!",
//            @"Hey!",
//            @"Stop it!",
//            @"Urgh!",
//            @"Don't hit me!",
//            @"Waah!",
//            @"Oy Vey!",            
//            @"Argh!",
//        };        
//              
//        static int lastMessage = 0;
//        int nextMessage = random()%numMessages;
//        lastMessage = (lastMessage == nextMessage) ? (lastMessage+1)%numMessages : nextMessage;
//        [self postText:sCheers[lastMessage] at:[self speakLocation] withColor:COLOR3D_RED];
//        lastHitTime = 0.0f;
//        return true;
//    }
    return false;
}

-(void)addForce:(Vector2D)force {
}

-(void)setSugarRush:(Boolean)flag {
    sugarRush = flag;
    if (sugarRush) {
        [self postText:@"Sugar Rush!" at:[self speakLocation] withColor:COLOR3D_GREEN];        
    }
    else {
        [self postText:@"Ahhhh!" at:[self speakLocation] withColor:COLOR3D_GREEN];            
    }
    timeSinceCheer = 0.0f;    
}

-(void)setSugarHigh:(Boolean)flag {
    sugarHigh = flag;
    if (sugarHigh) {
        [game displayMessage:@"Rub the screen\nas fast as you can!"];
        [self postText:@"Sugar High!" at:[self speakLocation] withColor:COLOR3D_GREEN];        
    }
    else {
        [self postText:@"Ahhhh!" at:[self speakLocation] withColor:COLOR3D_GREEN];            
    }
    timeSinceCheer = 0.0f;
}

-(void)postText:(NSString*)text at:(Vector2D)pos withColor:(Color3D)color {
    if (jumped) {
        return;
    }

    if (simpleText) {
        [simpleText release]; 
        simpleText = nil;       
    }
    
    if (!simpleTextBackground) {
        simpleTextBackground = 
            [[ImageControl alloc] 
                initAt:ZeroVector() 
                withTexture:kTexture_SpeechBox];
        simpleTextBackground.jiggling = true;
        simpleTextBackground.hasShadow = false;         
    }

    simpleTextBackground.position = pos;
    [simpleTextBackground setFadeDelay:0.0f];
    [simpleTextBackground setFade:kFade_In];    
    [simpleTextBackground bounce:1.125f];

    simpleText = [[TextControl alloc] 
        initAt:pos
        withText:text
        andArg:nil
        andDimensions:Vector2DMake(0.4f*GetGLWidth(),24.0f) 
        andAlignment:UITextAlignmentCenter 
        andFontName:DEFAULT_FONT andFontSize:22];
    simpleText.jiggling = true;
    simpleText.hasShadow = false;
    [simpleText setColor:color];
    [simpleText setFadeDelay:0.2f];
    [simpleText setFade:kFade_In];
    [simpleText bounce:1.125f];
}

-(void)jump {
    Pinata* p = [game findNearestPinata:Vector2DMake(0.5f*GetGLWidth(),0.0f)];
    if (p) {
        static const int numMessages = 4;
        static const eLocalizedString sMessages[] = {
            @"Revenge!",
            @"Woohoo!",
            @"Pop!",
            @"Ha ha ha!",
        };        
        
        static int lastMessage = 0;
        int nextMessage = random()%numMessages;
        lastMessage = (lastMessage == nextMessage) ? (lastMessage+1)%numMessages : nextMessage;
        [Pinata postComment:sMessages[lastMessage] atPosition:p.position];
    }
        
    velocity    += 400.0f;
    jumped      = true;
    
    [simpleText             release];
    simpleText              = nil;    
    
    [simpleTextBackground   release];
    simpleTextBackground    = nil;
}

-(void)dealloc {
    [simpleText             release];
    [simpleTextBackground   release];

    [hitJiggle release];
    [super dealloc];
}

@end
