//
//  ES1Renderer.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/15/10.
//  Copyright BlitShake LLC 2010. All rights reserved.
//

#import "ESRenderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "OpenGLCommon.h"
#import "Pinata.h"
#import "Texture2D.h"

@class ImageControl;
@class ParticleManager;
@class Screen;
@class TextControl;
@class Texture2D;

Texture2D* GetTexture(eTexture);
eTexture GetTextureId(NSString*);
Vector2D GetTextureDimensions(eTexture);
Vector2D GetImageDimensions(eTexture tex);
Vector2D MakeRandScreenVector();

@interface ES1Renderer : NSObject <ESRenderer>
{
@private
    EAGLContext* context;

    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer;
    
    // kind of hacky... for loading screen
    ImageControl* kidImage;
    ImageControl* kidBubble;
}

+(Vector2D)shadowOffset;

- (void)render:(Game*)game 
        afterTimeElapsed:(float)timeElapsed 
        withParticleManager:(ParticleManager*)pm 
        andScreen:(Screen*)screen
        andFilter:(ImageControl*)filter
        andPopupElements:(NSMutableArray*)popupElements;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (void)initGameTextures;
- (void)initUITextures;
@end
