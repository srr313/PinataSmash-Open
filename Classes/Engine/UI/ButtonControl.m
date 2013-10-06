//
//  ButtonControl.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 2/14/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import "Screen.h"
#import "EAGLView.h"
#import "FlowManager.h"
#import "Localize.h"
#import "JiggleAnimation.h"
#import "Sounds.h"

@interface ButtonControl()
-(void)trigger;
@end


@implementation ButtonControl

@synthesize respondOnRelease;

-(id)initAt:(Vector2D)pos withTexture:(eTexture)tex andString:(NSString*)str {
    if (self == [super init]) {
        basePosition = pos;
        dimensions = GetTextureDimensions(tex);
        texture = tex;
        jiggling = true;
        [jiggler stop];
        jiggler.t = random()/(float)RAND_MAX;
        hasShadow = true;
        shadowColor.alpha = 0.2f;
        heldDown = false;
        pressSound = kSound_ButtonPress;
        respondOnRelease = false;
                
        Vector2D textPosition = Vector2DMake(0.0f,-ToGameScaleY(dimensions.y/4));
        if (str != nil) {
            textControl = [[TextControl alloc] 
                initAt:textPosition 
                withString:str
                andDimensions:Vector2DMake(ToGameScaleX(dimensions.x),ToGameScaleY(dimensions.y))
                andAlignment:UITextAlignmentCenter 
                andFontName:DEFAULT_FONT 
                andFontSize:24];
            textControl.hasShadow = false;
            textControl.jiggling = false;
//            textControl.jiggler.t = random()/(float)RAND_MAX;
            [textControl setColor:Color3DMake(0.0f, 0.0f, 0.0f, 1.0f)];
            [self addChild:textControl];
        }
        
        [self setPosition:pos];
    }
    return self;
}

-(id)initAt:(Vector2D)pos withTexture:(eTexture)tex andText:(eLocalizedString)locText {
    NSString* locStr = LocalizeText(locText);
    return [self initAt:pos withTexture:tex andString:locStr];
}
-(void)setResponder:(id)resp andSelector:(SEL)sel {
    responder = resp;
    selector = sel;
}
-(void)setPressSound:(eSound)sound {
    pressSound = sound;
}
-(Boolean)processEvent:(TapEvent)evt { 
    if (!enabled) {
        return false;
    }
  
    if (evt.type == kTapEventType_Start) {
        if (!respondOnRelease) {
            [super processEvent:evt];
            
            // the control should not be accessed beyond this point in the event that
            // it was destroyed by the trigger's selector            
            [self trigger];        
        }
        else {
            [self bounce];  
            heldDown = true;              
        }
        return true;
    }

    Boolean eventConsumed   = false;
    Boolean wasHeldDown     = heldDown;
    heldDown                = false; 
    if (evt.type == kTapEventType_End && (wasHeldDown&&respondOnRelease)) {
        [super processEvent:evt];
        
        // the control should not be accessed beyond this point in the event that
        // it was destroyed by the trigger's selector        
        [self trigger];
        
        return true;
        
    }
           
    return eventConsumed;
}

-(void)trigger {
    [[SimpleAudioEngine sharedEngine] playEffect:GetSoundName(pressSound)]; 
    [self bounce];            
    [responder performSelector:selector withObject:self];

}

-(void)setColor:(Color3D)col {
    [super setColor:col];
    [textControl setShadowColor:Color3DMake(0.0f,0.0f,0.0f,0.2f)];
}
-(void)dealloc {
    [textControl release];
    [super dealloc];
}

@end
