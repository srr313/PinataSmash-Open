//
//  CreditsScreen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 12/28/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import "CreditsScreen.h"
#import "EAGLView.h"

#define USE_BW_CREDITS

@interface CreditsScreen()
-(void)resetCredits;
@end


@implementation CreditsScreen

-(id)initWithFlowManager:(id<FlowManager>)fm {
    if (self = [super initWithFlowManager:fm]) {
    
    #ifndef USE_BW_CREDITS
        ImageControl* bgImage = [[ImageControl alloc] 
            initAt:Vector2DMul(GetGLDimensions(), 0.5f) withTexture:kTexture_MenuBackground];
        [self addControl:bgImage]; 
        [bgImage bounce];
        bgImage.jiggling = true;        
        bgImage.alphaEnabled = false;
        [bgImage release];
        bgImage = nil;    
    #endif     
    
        NSString *versionNumber =[[[NSBundle mainBundle] infoDictionary] 
                                        valueForKey:@"CFBundleShortVersionString"];                      
                                        
        NSString* gameName = [NSString stringWithFormat:@"T/Piñata Smash v%@", versionNumber];
                                        
        entries =  [[NSArray alloc] initWithObjects: 
            gameName,
            @"S/By BlitShake LLC",
            @" ",
            @"T/Development",
            @"Sean Rosenbaum",
            @" ",
            @"T/Design",
            @"David Benedek",
            @" ",
            @"T/Art",
            @"Mike Pappa",
            @" ",
            @"T/Sound",
            @"www.freesound.org",
            @" ",  
            @"Abyssmal",
            @"acclivity",          
            @"adcbicycle",  
            @"BMacZero", 
            @"Corsica_S", 
            @"Creek23",   
            @"datasoundsample", 
            @"flasher21",
            @"flatfly",
            @"FranciscoPadilla",    
            @"Gniffelbaf",
            @"Hell's Sound Guy",
            @"jivatma07",
            @"jmaimarc",
            @"mich3D",
            @"neonaeon",
            @"nicstage",
            @"Q.K.",
            @"sandyrb",
            @"simon.rue",
            @"smcameron",
            @"SpeedY",
            @"spexis",
            @"Splashdust",
            @"Srehpog",
            @"Syna Max",
            @"THE_bizniss",
            @"volivieri",
            @"zerolagtime",
            @"zimbot",
            @" ",
            @" ",
            @"T/Thanks for playing!",
            nil
        ];
        
        credits = [[NSMutableArray alloc] initWithCapacity:entries.count]; 

        for (NSString* entry in entries) {  
            Color3D color = COLOR3D_WHITE;
            if ([entry hasPrefix:@"T/"]) {
                color = COLOR3D_BLUE;
                entry = [entry stringByReplacingOccurrencesOfString:@"T/" withString:@""];
            }
            else if ([entry hasPrefix:@"S/"]) {
                color = COLOR3D_YELLOW;
                entry = [entry stringByReplacingOccurrencesOfString:@"S/" withString:@""];
            }
                            
            TextControl* textEntry = [[TextControl alloc] 
                initAt:         ZeroVector()
                withString:     entry
                andDimensions:  Vector2DMake(GetGLWidth(),36.0f) 
                andAlignment:   UITextAlignmentCenter 
                andFontName:    DEFAULT_FONT andFontSize:32];
            
            textEntry.jiggling  = true;
            textEntry.hasShadow = false;
            textEntry.color     = color;
            
            [self addControl:textEntry];
            [credits addObject:textEntry];
            [textEntry release];            
        }
        
        [self resetCredits];
        
        Vector2D backPosition = Vector2DMake(35.0f,440.0f);
        ButtonControl* backButton = [[ButtonControl alloc] 
            initAt:backPosition withTexture:kTexture_BackButton andText:kLocalizedString_Null];
        [backButton setResponder:self andSelector:@selector(backAction:)];
        backButton.tilting = false;
        [self addControl:backButton];
        [backButton release];
        backButton = nil;

    }
    return self;
}

-(void)backAction:(ButtonControl *)control {
    [flowManager changeFlowState:kFlowState_Title];
}

-(void)resetCredits {
    Vector2D position = Vector2DMake(0.5f*GetGLWidth(), 0.0f);
    for (TextControl* text in credits) {    
        position.y -= 32.0f;
        text.position = position;
    }
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];

    Boolean done = YES;
    for (TextControl* text in credits) {
        Vector2D position = text.position;
        Boolean wasOffscreen = (position.y < 0.0f);
        position.y += 75.0f*timeElapsed;
        if (position.y < GetGLHeight()) {
            done = NO;
            
            if (wasOffscreen && position.y > 0.0f) {
                [text bounce];
            }
            
        }
        text.position = position;
    }
    
    if (done) {
       [self resetCredits];
    }
}

-(void)dealloc {
    [entries release];
    [credits release];
    [super dealloc];
}

@end


