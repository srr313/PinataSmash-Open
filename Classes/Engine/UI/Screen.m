//
//  Screen.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/19/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "Screen.h"
#import "EAGLView.h"
#import "FlowManager.h"
#import "Localize.h"
#import "JiggleAnimation.h"
#import "Sounds.h"

Color3D GetNextMultiplierColor(int m) {
    if (m <= 1) {
        return COLOR3D_WHITE;
    }

    #define NUM_MULTIPLIER_COLORS 5     
    static Boolean sInitializedColors = false;
    static int sMultiplierColorIndex = 0;
    static Color3D multiplierColors[NUM_MULTIPLIER_COLORS];
    if (!sInitializedColors) {
        multiplierColors[0] = Color3DMake(1.0f, 1.0f, 0.0f, 1.0f);
        multiplierColors[1] = Color3DMake(1.0f, 0.0f, 1.0f, 1.0f);
        multiplierColors[2] = COLOR3D_GREEN;
        multiplierColors[3] = Color3DMake(0.0f, 1.0f, 1.0f, 1.0f);
        multiplierColors[4] = COLOR3D_BLUE;
        sInitializedColors = true;
    }
    
    sMultiplierColorIndex = (sMultiplierColorIndex+1)%NUM_MULTIPLIER_COLORS;
    return multiplierColors[sMultiplierColorIndex];
}

@interface ScreenControl()
-(void)nextShadow;
@end


@implementation ScreenControl

@synthesize position, basePosition, scale, baseScale, jiggling, jiggler, 
            pulsing, pulseRate, color, baseAlpha, texture, children, hasShadow, autoShadow, 
            fadeSpeed, angle, baseAngle, tilting, parent, visible, enabled, alphaEnabled;

#define MIN_TIME_BEFORE_TAP 0.5f

-(id)init {
    if (self == [super init]) {
        jiggler = [[JiggleAnimation alloc] init];
        [jiggler jiggleFreq:5.0f andAmplitude:0.05f andDuration:FLT_MAX];
        pulsing = false;
        pulseT = 0.0f;
        jiggling = false;
        color = COLOR3D_WHITE;
        scale = 1.0f;
        baseScale = 1.0f;
        fade = kFade_Stop;
        fadeSpeed = 4.0f;
        fadeDelay = 0.0f;
        shadowColor = Color3DMake(0.0f, 0.0f, 0.0f, 0.3f);
        autoShadow = false;
        shadowT = 2.0f;
        shadowScale = 1.03f;
        hasShadow = false;
        texture = kTexture_Null;
        angle = 0.0f;
        angleT = random()/(float)RAND_MAX;
        tilting = false;
        visible = true;
        baseAlpha = color.alpha;
        enabled = true;
        alphaEnabled = true;
        pulseRate = 4.0f; 
        
        [self nextShadow];
    }
    return self;
}
-(void)dealloc {
    [jiggler release];
    [children release];
    [super dealloc];
}
-(void)nextShadow {
    shadowStart = shadowColor;
    shadowEnd = GetNextMultiplierColor((int)shadowT);
}
-(void)setAutoShadow:(Boolean)flag {
    autoShadow = flag;
    if (autoShadow) {
        shadowColor = Color3DMake(1.0f, 1.0f, 1.0f, 0.0f);
        [self nextShadow];
    }
}
-(Boolean)isInside:(CGPoint)p {
    // more precise if it uses the jiggle-scaled bounds - but we may not need that much precision

    Boolean isInsideParent =
        position.x-ToGameScaleX(dimensions.x/2) <= p.x && p.x <= position.x+ToGameScaleX(dimensions.x/2)
        && position.y-ToGameScaleY(dimensions.y/2) <= p.y && p.y <= position.y+ToGameScaleY(dimensions.y/2);
        
    if (isInsideParent) {
        return true;
    }
        
    for (ScreenControl* child in children) {
        if ([child isInside:p]) {
            return true;
        }
    }
    
    return false;
}
-(void)tick:(float)timeElapsed {
    if (!visible) {
        return;
    }

    if (autoShadow) {
        int shadowIndex1 = (int)shadowT;
        shadowT += timeElapsed;
        int shadowIndex2 = (int)shadowT;
        if (shadowIndex1 != shadowIndex2) {
            [self nextShadow];
        }
        float shadowLerp = shadowT-shadowIndex2;
        shadowColor.red = shadowStart.red*(1.0f-shadowLerp)+shadowEnd.red*shadowLerp;
        shadowColor.green = shadowStart.green*(1.0f-shadowLerp)+shadowEnd.green*shadowLerp;
        shadowColor.blue = shadowStart.blue*(1.0f-shadowLerp)+shadowEnd.blue*shadowLerp;
        shadowColor.alpha = 0.6f;             
    }

    if (jiggling) {
        [jiggler tick:timeElapsed];
        scale = baseScale * jiggler.scale;
    }
    else {
        scale = baseScale;
    }
    
    if (tilting) {
        angleT += timeElapsed;
        baseAngle = 0.125f*(180.0f/M_PI)*sinf(2.0f*angleT);
        angle = baseAngle;
    }
    
    if (pulsing) {
        pulseT += timeElapsed;
        baseAlpha = 0.5f*(1.0f+sinf(pulseRate*pulseT));
    }
    else if (fade != kFade_Stop) { 
        if (fadeDelay > 0.0f) {
            fadeDelay -= timeElapsed;
        }
        else {
            if (fade == kFade_In) {
                baseAlpha = fminf(fadeSpeed*timeElapsed+baseAlpha,1.0f);
            }
            else if (fade == kFade_Out) {
                baseAlpha = fmaxf(-fadeSpeed*timeElapsed+baseAlpha,0.0f);
            }   
             
            if (baseAlpha >= 1.0f || baseAlpha <= 0.0f) {
                fade = kFade_Stop;
            }
        }
    }
    
    for (ScreenControl* child in children) {
        [child tick:timeElapsed];
        child.scale *= scale;
        child.angle = child.baseAngle + angle;
        child.color = Color3DMake(child.color.red, child.color.green, child.color.blue, baseAlpha*color.alpha);
    }
}
- (void)render:(float)timeElapsed {        
    if (!visible) {
        return;
    }
    
    if (!alphaEnabled) {
        glDisable(GL_BLEND);
    }
    
    Color3D controlColor = [self color];
    if (controlColor.alpha <= 0.0f) {
        return;
    }

    Texture2D* renderTexture = [self getLocalTexture2D];
    if (renderTexture == nil && texture != kTexture_Null) {
        renderTexture = GetTexture(texture);
    }
    
    if (renderTexture != nil) {
        if (hasShadow) {
            Vector2D shadowOffset = [ES1Renderer shadowOffset];        
            float netShadowScale = [self shadowScale]*scale;
            Color3D shadowCol = [self shadowColor];
            glLoadIdentity();
            glTranslatef(ToScreenScaleX(position.x+shadowOffset.x), ToScreenScaleY(position.y+shadowOffset.y), 0.0f);
            glScalef(netShadowScale, netShadowScale, 1.0f);
            glRotatef(angle, 0.0f, 0.0f, 1.0f);
            glColor4f(shadowCol.red, shadowCol.green, shadowCol.blue, controlColor.alpha*shadowCol.alpha);                
            [renderTexture draw];
        }
                
        glLoadIdentity();
        glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
        glScalef(scale, scale, 1.0f);
        glRotatef(angle, 0.0f, 0.0f, 1.0f);
        glColor4f(controlColor.red, controlColor.green, controlColor.blue, controlColor.alpha);
        [renderTexture draw];
    }
    
    if (!alphaEnabled) {
        glEnable(GL_BLEND);
    }    
        
    for (ScreenControl* child in children) {
        [child render:timeElapsed];
    }
}
-(Boolean)processEvent:(TapEvent)evt {
    for (ScreenControl* child in children) {
        if ([child isInside:evt.location] && [child processEvent:evt]) {
            return true;
        }
    }
    return false;
}
-(Vector2D)dimensions {
    return dimensions;
}
-(Texture2D*)getLocalTexture2D {
    return nil;
}
-(NSMutableArray*)getChildren {
    return nil;
}
-(void)setEnabled:(Boolean)flag {
    enabled = flag;
    baseAlpha = enabled ? 1.0f : 0.5f;
}
-(void)setColor:(Color3D)col {
    color = col;
}
-(void)setBaseScale:(float)base {
    baseScale = base;
    scale = base;
}
-(Color3D)color {
    return Color3DMake(color.red, color.green, color.blue, baseAlpha*color.alpha);
}
-(void)setFade:(eFade)flag {
    fade = flag;
    if (fade==kFade_In) {
        baseAlpha = 0.0f;
    }
    else if (fade==kFade_Out) {
        baseAlpha = 1.0f;
    }
}
-(void)setFadeSpeed:(float)speed {
    fadeSpeed = speed;
}
-(void)setFadeDelay:(float)delay {
    fadeDelay = delay;
}
-(eFade)fade {
    return fade;
}
-(Color3D)shadowColor {
    return shadowColor;
}
-(float)shadowScale {
    return shadowScale;
}
-(void)setShadowColor:(Color3D)col {
    shadowColor = col;
}
-(void)shadowScale:(float)sca {
    shadowScale = sca;
}
-(void)bounce:(float)amp {
    [jiggler stop];
    [jiggler jiggleFreq:5.0f andAmplitude:amp andDuration:0.5f];
}
-(void)bounce {
    [jiggler stop];
    [jiggler jiggleFreq:15.0f andAmplitude:0.1f andDuration:0.5f];
}
-(void)addChild:(ScreenControl*)child {
    if (children==nil) {
        children = [[NSMutableArray alloc] init];
    }
    [children addObject:child];
}
-(void)removeChild:(ScreenControl*)child {
    [children removeObject:child];
}
-(void)setPosition:(Vector2D)pos {
    position = pos;
    for (ScreenControl* child in children) {
        [child setPosition:Vector2DAdd(child.basePosition, position)];
    }
}
@end

@implementation Screen
-(id)initWithFlowManager:(id <FlowManager>)fm {
    flowManager = fm;
    controls = [[NSMutableArray alloc] init];
    timeSpent = 0.0f;
    return [super init];
}
-(void)tick:(float)timeElapsed {
    timeSpent += timeElapsed;
    for (ScreenControl* control in controls) {
        [control tick:timeElapsed];
    }
}
-(void)addControl:(ScreenControl*)control {
    [controls addObject:control];
}
-(void)removeControl:(ScreenControl*)control {
    [controls removeObject:control];
}
-(Boolean)processEvent:(TapEvent)evt {
    if (timeSpent <= MIN_TIME_BEFORE_TAP) {
        return true;
    }
    
    for (ScreenControl* control in [controls reverseObjectEnumerator]) {
        if (control.visible 
        && [control isInside:evt.location] 
        && [control processEvent:evt]) {
            return true;
        }
    } 
    return false;   
}
-(void)render:(float)timeElapsed {
    for (ScreenControl* control in controls) {
        [control render:timeElapsed];
    }
}
-(NSMutableArray*)getControls {
    return controls;
}
-(void)crystalUiDeactivated {
}
-(void)dealloc {
    [controls release];
    [super dealloc];
}

@end
