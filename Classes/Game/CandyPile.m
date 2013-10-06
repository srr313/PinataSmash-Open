//
//  CandyPile.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/19/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "CandyPile.h"
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "JiggleAnimation.h"

//#define DRAW_CANDY_PILE_SHADOW
#define MAX_PILE_SIZE 15.0f

@implementation CandyPile

@synthesize numCandy, candyCollected, consumptionDelay, consumptionAmount, candyConsumed, position;

-(id)initWithCandy:(int)candy 
        andTarget:(int)target
        andConsumptionDelay:(float)delay 
        andConsumptionAmount:(float)amount 
        forGame:(Game*)g 
{
    if (self == [super init]) {
        numCandy            = candy;
        targetAmount        = target;
        candyCollected      = 0;
        candyConsumed       = 0;
        consumptionDelay    = delay;
        consumptionAmount   = amount;
        game                = g;

        addJiggler = [[JiggleAnimation alloc] init];
        remJiggler = [[JiggleAnimation alloc] init];
                
        timeSinceLastConsumption = 0.0f;
        
        position = Vector2DMake(GetGLWidth()/2,0.0f);
    }
    return self;
}

-(void)addCandy:(int)amount {
    if (numCandy > 0) {
        numCandy += amount;
        candyCollected += amount;
        if (amount > 0) {
            [addJiggler jiggleFreq:15.0f andAmplitude:0.05f andDuration:1.0f];
        }
        else {
            [remJiggler jiggleFreq:15.0f andAmplitude:0.05f andDuration:0.5f];
            candyConsumed += amount;
        }
        
        if (numCandy < 0) {
            numCandy = 0;
        }
    }
}

-(int)getCandy {
    return numCandy;
}

-(float)getBaseScale {
    return 0.9f*(fminf(numCandy / (float)targetAmount, 1.0f));
}

-(float)getJiggleScale {
    return addJiggler.scale * remJiggler.scale;
}

-(float)getConsumptionScale {
    return remJiggler.scale;
}

-(float)getForegroundHeight {
    float imageHeight = GetImageDimensions(kTexture_CandyPileFG).y;
    return 0.5f*imageHeight*[self getBaseScale];
}

-(void)tick:(float)timeElapsed {
    [addJiggler tick:timeElapsed];
    [remJiggler tick:timeElapsed];
    
    timeSinceLastConsumption += timeElapsed;
    if (timeSinceLastConsumption > consumptionDelay) {
        timeSinceLastConsumption = 0.0f;
        numCandy -= consumptionAmount; 
        if (numCandy <= 0) {
            numCandy = 0;
            return;
        }
    }
}

-(void)renderForeground:(float)timeElapsed {        
    Texture2D* texture  = GetTexture(kTexture_CandyPileFG);
    float imageHeight   = texture.pixelsHigh;
    float pileSize      = imageHeight*([self getBaseScale]-0.5f);
    float pileScale     = [self getJiggleScale];
    
#ifdef DRAW_CANDY_PILE_SHADOW    
    if (!IsDeviceIPad()) {   // render shadow
        Vector2D shadowOffset = [ES1Renderer shadowOffset];
        Color3D shadowColor = [game shadowColor];        
    
        glLoadIdentity();        
        glTranslatef(   ToScreenScaleX(position.x+shadowOffset.x), 
                        ToScreenScaleY(position.y+pileSize+0.5f*fabsf(shadowOffset.y)), 0.0f);
        glScalef(pileScale,pileScale,0.0f);
        glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, shadowColor.alpha); 
        [texture draw];
    }
#endif    
    
    // draw inside
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);    
    glLoadIdentity();
    glTranslatef(   ToScreenScaleX(position.x), 
                    ToScreenScaleY(position.y)+pileSize, 
                    0.0f);
    glScalef(pileScale,pileScale,0.0f);
    [texture draw];
}

-(void)renderBackground:(float)timeElapsed {        
    Texture2D* texture  = GetTexture(kTexture_CandyPileBG);
    float imageHeight   = texture.pixelsHigh;
    float pileSize      = imageHeight*(2.0f*[self getBaseScale]-0.5f);
    float pileScale     = [self getJiggleScale];
    
#ifdef DRAW_CANDY_PILE_SHADOW    
    if (!IsDeviceIPad()) {   // render shadow
        Vector2D shadowOffset = [ES1Renderer shadowOffset];
        Color3D shadowColor = [game shadowColor];        
    
        glLoadIdentity();        
        glTranslatef(   ToScreenScaleX(position.x+shadowOffset.x), 
                        ToScreenScaleY(position.y+0.5f*fabsf(shadowOffset.y)+pileSize), 
                        0.0f);
        glScalef(pileScale,pileScale,0.0f);
        glColor4f(shadowColor.red, shadowColor.green, shadowColor.blue, shadowColor.alpha); 
        [texture draw];
    }    
#endif
    
    // draw inside
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);    
    glLoadIdentity();
    glTranslatef(   ToScreenScaleX(position.x), 
                    ToScreenScaleY(position.y)+pileSize, 
                    0.0f);
    glScalef(pileScale,pileScale,0.0f);
    [texture draw];
}

-(void)bounce {
    [addJiggler jiggleFreq:15.0f andAmplitude:0.025f andDuration:0.5f];
}

-(void)dealloc {
    [addJiggler release];
    [remJiggler release];
    [super dealloc];
}

@end
