//
//  ModalControl.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/1/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "ModalControl.h"
#import "EAGLView.h"
#import "Particles.h"

@interface ModalControl()
-(void)closeAction:(ButtonControl *)owner;
@end


@implementation ModalControl

@synthesize closeButton;

+(ModalControl*)createModalWithMessage:(eLocalizedString)message andArg:(NSObject*)arg andFontSize:(int)fontSize; {
    ModalControl* modal = [[ModalControl alloc] init];
    
    Vector2D pos = Vector2DMul(GetGLDimensions(), 0.5f);
    TextControl* text = [[TextControl alloc] 
        initAt: pos
        withText:message
        andArg:arg
        andDimensions:Vector2DMake(modal.dimensions.x-36.0f, 0.75f*modal.dimensions.y) 
        andAlignment:UITextAlignmentCenter 
        andFontName:DEFAULT_FONT andFontSize:fontSize];
    text.hasShadow = false;
    text.jiggling = true;
    [text setFade:kFade_In];
    [text bounce:1.0f];
    [modal addChild:text];
    [text release];
    
    return modal;
}


+(ModalControl*)createModalWithMessage:(eLocalizedString)message andArg:(NSObject*)arg andButton:(ButtonControl*)button {
    ModalControl* modal = [ModalControl createModalWithMessage:message andArg:arg andFontSize:24];
    
    Vector2D panelDimensions = GetImageDimensions(kTexture_ModalPanel);
    Vector2D halfPanel = Vector2DMul(panelDimensions, 0.5f);
    float closeButtonWidth = GetImageDimensions(kTexture_AltCloseButton).x;
    
    Vector2D pos = Vector2DMul(GetGLDimensions(), 0.5f);
    pos.x -= closeButtonWidth;
    pos.y -= halfPanel.y;
    button.position = pos;
    [modal addChild:button];
    
    ButtonControl* closeButton = modal.closeButton;
    closeButton.texture = kTexture_AltCloseButton; // override default close button
    closeButton.position = Vector2DMake(closeButton.position.x+closeButtonWidth,closeButton.position.y);
    
    [modal removeChild:modal.closeButton];
    [modal addChild:modal.closeButton];    
    
    return modal;
}

+(ModalControl*)createModalWithMessage:(eLocalizedString)message andArg:(NSObject*)arg andImages:(NSArray*)images {
    ModalControl* modal = [ModalControl createModalWithMessage:message andArg:arg andFontSize:24];
    
    Vector2D panelDimensions = GetTextureDimensions(kTexture_ModalPanel);
        
    if (images.count > 0) {
        
        float scaling = 1.0f;
        float spacing = 0.0f;
        float imgWidth = 0.0f;
        for (ImageControl* img in images) {
            imgWidth = ToGameScaleX(img.dimensions.x);
            spacing += ToGameScaleX(img.dimensions.x);
            
            float downScale = (panelDimensions.y/2) / img.dimensions.y;
            scaling = MIN( scaling, downScale );
        }
        
        spacing *= 0.5f*scaling;
        spacing -= 0.5f*scaling*imgWidth;

        Vector2D halfPanel = Vector2DMul(panelDimensions, 0.5f);    
        Vector2D pos = Vector2DMul(GetGLDimensions(), 0.5f);
        pos.x -= spacing;    
        float baseHeight = pos.y;
        
        for (ImageControl* img in images) { 
            img.jiggling  = true;       
            
            float currentScale = (panelDimensions.y/2) / img.dimensions.y;
            if (currentScale <= scaling) {
                img.baseScale = scaling;                
            }
             
            float rise = 0.25f*((panelDimensions.y/2)-img.baseScale*img.dimensions.y);
            pos.y = baseHeight + rise +
                        ToGameScaleY(0.5f*img.baseScale*img.dimensions.y-halfPanel.y+10.0f);        
            img.position  = pos;
            
            pos.x += ToGameScaleX(img.dimensions.x);
            [modal addChild:img];            
        }
    }
    
    [modal removeChild:modal.closeButton];
    [modal addChild:modal.closeButton];
        
    return modal;
}

-(id)init {
    if (self == [super init]) {
        visible = false;
        
        Vector2D screenCenter = Vector2DMul(GetGLDimensions(), 0.5f);        
        ImageControl* panel = [[ImageControl alloc] 
            initAt:screenCenter withTexture:kTexture_ModalPanel];
        panel.hasShadow = true;
        panel.jiggling = true;
        [self addChild:panel]; 
        [panel release];
                
        dimensions = GetImageDimensions(kTexture_ModalPanel);
        Vector2D halfPanel = Vector2DMul(dimensions, 0.5f);
        
        closeButton = [[ButtonControl alloc] 
            initAt:Vector2DAdd(screenCenter, Vector2DMake(0.0f,-halfPanel.y)) 
            withTexture:kTexture_CloseButton 
            andText:kLocalizedString_Null];
        closeButton.tilting     = true;
        closeButton.hasShadow   = true;
        [closeButton setFade:kFade_In];
        [closeButton setResponder:self andSelector:@selector(closeAction:)];
        [self addChild:closeButton];
    }
    return self;
}

-(Boolean)isInside:(CGPoint)p {
    return true;
}

-(Boolean)processEvent:(TapEvent)evt {
    if (![super processEvent: evt]  && evt.type == kTapEventType_Start) {
        for (ScreenControl* control in children) {
            [control bounce];
        }
    }
    return true;
}

-(void)setCloseResponder:(id)resp andSelector:(SEL)sel {
    closeResponder = resp;
    closeSelector = sel;
}

-(void)closeAction:(ButtonControl *)owner {
    visible = false;
    [closeResponder performSelector:closeSelector withObject:self];
}

-(void)setVisible:(Boolean)flag {
    for (ScreenControl* control in children) {
        [control bounce];
    }
    [super setVisible:flag];
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    
    if (visible && color.alpha > 0.0f) {
        particleT += 5.0f * timeElapsed;
        timeForNextParticle -= timeElapsed;
        
        if (timeForNextParticle <= 0.0f) {
            timeForNextParticle = 0.02f;
        
            Vector2D gameDimensions = GetGLDimensions();
            float r = 10.0f + 0.5f * GetImageDimensions(kTexture_ModalPanel).y;
            float sint = sinf(particleT);
            float cost = cosf(particleT);
            float x = 0.5f*gameDimensions.x + r * cost;
            float y = 0.5f*gameDimensions.y + r * sint;
                
            Particle* p = [PARTICLE_MANAGER
                                NewParticleAt:Vector2DMake(x,y)
                                    andVelocity:Vector2DMake(0.0f,0.0f) 
                                    andAngle:atan2(x, y) 
                                    andScaleX:CANDY_MAX_SIZE
                                    andScaleY:CANDY_MAX_SIZE
                                    andColor:COLOR3D_WHITE
                                    andTotalLifetime:0.25f 
                                    andType:kParticleType_Candy
                                    andTexture:kTexture_CandyBegin+rand()%(kTexture_CandyEnd-kTexture_CandyBegin)]; 
            p.layer = kLayer_UI;
            [PARTICLE_MANAGER addParticle:p];
            [p release];
        }    
    }
}

-(void)dealloc {
    [closeButton release];
    [super dealloc];
}

@end

