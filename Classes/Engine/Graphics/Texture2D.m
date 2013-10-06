/*

File: Texture2D.m
Abstract: Creates OpenGL 2D textures from images or text.

Version: 1.7

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the following terms, and your
use, installation, modification or redistribution of this Apple software
constitutes acceptance of these terms.  If you do not agree with these terms,
please do not use, install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject
to these terms, Apple grants you a personal, non-exclusive license, under
Apple's copyrights in this original Apple software (the "Apple Software"), to
use, reproduce, modify and redistribute the Apple Software, with or without
modifications, in source and/or binary forms; provided that if you redistribute
the Apple Software in its entirety and without modifications, you must retain
this notice and the following text and disclaimers in all such redistributions
of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may be used
to endorse or promote products derived from the Apple Software without specific
prior written permission from Apple.  Except as expressly stated in this notice,
no other rights or licenses, express or implied, are granted by Apple herein,
including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import <OpenGLES/ES1/glext.h>

#import "Texture2D.h"

#import "FontLabelStringDrawing.h"
#import "FontManager.h"

//CONSTANTS:

#define kMaxTextureSize	 1024

//CLASS IMPLEMENTATIONS:

@implementation Texture2D

@synthesize contentSize=_size, pixelFormat=_format, pixelsWide=_width, pixelsHigh=_height, name=_name, maxS=_maxS, maxT=_maxT;

- (id) initWithData:(const void*)data pixelFormat:(Texture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size
        filterNearest:(Boolean)nearest wrapClamp:(Boolean)clamp
{
	GLint					saveName;
	if((self = [super init])) {
		glGenTextures(1, &_name);
		glGetIntegerv(GL_TEXTURE_BINDING_2D, &saveName);
		glBindTexture(GL_TEXTURE_2D, _name);
        
        if (nearest) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        }
        else { 
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);            
        }

        if (clamp) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);    
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);        
        }
        else {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);    
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);            
        }
        
		switch(pixelFormat) {
			
			case kTexture2DPixelFormat_RGBA8888:
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
				break;
			case kTexture2DPixelFormat_RGB565:
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, data);
				break;
			case kTexture2DPixelFormat_A8:
				glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, width, height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, data);
				break;
			default:
				[NSException raise:NSInternalInconsistencyException format:@""];
			
		}
		glBindTexture(GL_TEXTURE_2D, saveName);
	
		_size = size;
		_width = width;
		_height = height;
		_format = pixelFormat;
		_maxS = size.width / (float)width;
		_maxT = size.height / (float)height;
	}					
	return self;
}

- (void) dealloc
{
	if(_name)
	 glDeleteTextures(1, &_name);
	
	[super dealloc];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %08X | Name = %i | Dimensions = %ix%i | Coordinates = (%.2f, %.2f)>", [self class], self, _name, _width, _height, _maxS, _maxT];
}

@end

@implementation Texture2D (Image)
	
- (id) initWithImage:(UIImage *)uiImage filterNearest:(Boolean)nearest wrapClamp:(Boolean)clamp
{
	NSUInteger				width,
							height,
							i;
	CGContextRef			context = nil;
	void*					data = nil;;
	CGColorSpaceRef			colorSpace;
	void*					tempData;
	unsigned int*			inPixel32;
	unsigned short*			outPixel16;
	BOOL					hasAlpha;
	CGImageAlphaInfo		info;
	CGAffineTransform		transform;
	CGSize					imageSize;
	Texture2DPixelFormat    pixelFormat;
	CGImageRef				image;
	BOOL					sizeToFit = NO;
	
	
	image = [uiImage CGImage];
	
	if(image == NULL) {
		[self release];
        #ifdef DEBUG_BUILD                    
            NSLog(@"Image is Null");
        #endif
		return nil;
	}
	

	info = CGImageGetAlphaInfo(image);
	hasAlpha = ((info == kCGImageAlphaPremultipliedLast) || (info == kCGImageAlphaPremultipliedFirst) || (info == kCGImageAlphaLast) || (info == kCGImageAlphaFirst) ? YES : NO);
	if(CGImageGetColorSpace(image)) {
		if(hasAlpha)
			pixelFormat = kTexture2DPixelFormat_RGBA8888;
		else
			pixelFormat = kTexture2DPixelFormat_RGB565;
	} else  //NOTE: No colorspace means a mask image
		pixelFormat = kTexture2DPixelFormat_A8;
	
	
	imageSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
	transform = CGAffineTransformIdentity;

	width = imageSize.width;
	
	if((width != 1) && (width & (width - 1))) {
		i = 1;
		while((sizeToFit ? 2 * i : i) < width)
			i *= 2;
		width = i;
	}
	height = imageSize.height;
	if((height != 1) && (height & (height - 1))) {
		i = 1;
		while((sizeToFit ? 2 * i : i) < height)
			i *= 2;
		height = i;
	}
	while((width > kMaxTextureSize) || (height > kMaxTextureSize)) {
		width /= 2;
		height /= 2;
		transform = CGAffineTransformScale(transform, 0.5, 0.5);
		imageSize.width *= 0.5;
		imageSize.height *= 0.5;
	}
	
	switch(pixelFormat) {		
		case kTexture2DPixelFormat_RGBA8888:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			data = malloc(height * width * 4);
			context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			break;
		case kTexture2DPixelFormat_RGB565:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			data = malloc(height * width * 4);
			context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			break;
			
		case kTexture2DPixelFormat_A8:
			data = malloc(height * width);
			context = CGBitmapContextCreate(data, width, height, 8, width, NULL, kCGImageAlphaOnly);
			break;				
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid pixel format"];
	}
 

	CGContextClearRect(context, CGRectMake(0, 0, width, height));
	CGContextTranslateCTM(context, 0, height - imageSize.height);
	
	if(!CGAffineTransformIsIdentity(transform))
		CGContextConcatCTM(context, transform);
	CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
	//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGGGBBBBB"
	if(pixelFormat == kTexture2DPixelFormat_RGB565) {
		tempData = malloc(height * width * 2);
		inPixel32 = (unsigned int*)data;
		outPixel16 = (unsigned short*)tempData;
		for(i = 0; i < width * height; ++i, ++inPixel32)
			*outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | ((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) | ((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);
		free(data);
		data = tempData;
		
	}
	self = [self initWithData:data pixelFormat:pixelFormat 
                pixelsWide:width pixelsHigh:height contentSize:imageSize
                filterNearest:nearest wrapClamp:clamp];
	
	CGContextRelease(context);
	free(data);
	
	return self;
}

@end

@implementation Texture2D (Text)

- (id) initWithString:(NSString*)string dimensions:(CGSize)dimensions alignment:(UITextAlignment)alignment fontName:(NSString*)name fontSize:(CGFloat)size
{
	NSUInteger				width,
							height,
							i;
	CGContextRef			context;
	void*					data;
	CGColorSpaceRef			colorSpace;
	id                      font;
	
	font = [UIFont fontWithName:name size:size];
    
	if(!font) {
		font = [[FontManager sharedManager] 
                    zFontWithName:name 
                    pointSize:size];
    }
    
	width = dimensions.width;
	if((width != 1) && (width & (width - 1))) {
		i = 1;
		while(i < width)
		i *= 2;
		width = i;
	}
	height = dimensions.height;
	if((height != 1) && (height & (height - 1))) {
		i = 1;
		while(i < height)
		i *= 2;
		height = i;
	}
	
	colorSpace = CGColorSpaceCreateDeviceGray();
	data = calloc(height, width);
	context = CGBitmapContextCreate(data, width, height, 8, width, colorSpace, kCGImageAlphaNone);
	CGColorSpaceRelease(colorSpace);
	
	
	CGContextSetGrayFillColor(context, 1.0, 1.0);
	CGContextTranslateCTM(context, 0.0, height);
	CGContextScaleCTM(context, 1.0, -1.0); //NOTE: NSString draws in UIKit referential i.e. renders upside-down compared to CGBitmapContext referential
	UIGraphicsPushContext(context);
        
	if( [font isKindOfClass:[UIFont class] ] ) {
		[string drawInRect:CGRectMake(0, 0, dimensions.width, dimensions.height) 
                withFont:font 
                lineBreakMode:UILineBreakModeWordWrap 
                alignment:alignment];
    }
    else { // ZFont class 
		[string drawInRect:CGRectMake(0, 0, dimensions.width, dimensions.height) 
                withZFont:font 
                lineBreakMode:UILineBreakModeWordWrap 
                alignment:alignment];
    }
    	
	self = [self initWithData:data pixelFormat:kTexture2DPixelFormat_A8 
                pixelsWide:width pixelsHigh:height contentSize:dimensions
                filterNearest:false wrapClamp:true ];
	
	CGContextRelease(context);
	free(data);
	
	return self;
}

@end

@implementation Texture2D (Drawing)



- (void) draw
{
	GLfloat		coordinates[] = { 0,	_maxT,
								_maxS,	_maxT,
								0,		0,
								_maxS,	0 };
	GLfloat		width = (GLfloat)_width * _maxS,
				height = (GLfloat)_height * _maxT;
                
//    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//
//        }
//    #else
	GLfloat		vertices[] = {	-width / 2,	-height / 2,	0.0,
								width / 2,	-height / 2,	0.0,
								-width / 2,	height / 2,	0.0,
								width / 2,	height / 2,	0.0 };
//    #endif

    glBindTexture(GL_TEXTURE_2D, _name);        
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) drawWithTexScale:(CGPoint)texScale
{
	GLfloat	 coordinates[] = {  0,                  _maxT*texScale.y,
								_maxS*texScale.x,	_maxT*texScale.y,
								0,		0,
								_maxS*texScale.x,	0  };
	GLfloat		width = (GLfloat)_width * _maxS,
				height = (GLfloat)_height * _maxT;
                                
//    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//
//        }
//    #else
	GLfloat		vertices[] = {	-width / 2,	-height / 2,	0.0,
								width / 2,	-height / 2,	0.0,
								-width / 2,	height / 2,	0.0,
								width / 2,	height / 2,	0.0 };
//    #endif

    glBindTexture(GL_TEXTURE_2D, _name);        
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) drawWithTexOffset:(CGPoint)texOffset
{
	GLfloat		coordinates[] = { 0+texOffset.x,	_maxT+texOffset.y,
								_maxS+texOffset.x,	_maxT+texOffset.y,
								0+texOffset.x,		0+texOffset.y,
								_maxS+texOffset.x,	0+texOffset.y };
	GLfloat		width = (GLfloat)_width * _maxS,
				height = (GLfloat)_height * _maxT;
                                
//    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//
//        }
//    #else
	GLfloat		vertices[] = {	-width / 2,	-height / 2,	0.0,
								width / 2,	-height / 2,	0.0,
								-width / 2,	height / 2,	0.0,
								width / 2,	height / 2,	0.0 };
//    #endif

    glBindTexture(GL_TEXTURE_2D, _name);        
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) drawInRect:(CGRect)rect
{
	GLfloat	 coordinates[] = {  0,		_maxT,
								_maxS,	_maxT,
								0,		0,
								_maxS,	0  };
	GLfloat	vertices[] = {	rect.origin.x,							rect.origin.y,							0.0,
							rect.origin.x + rect.size.width,		rect.origin.y,							0.0,
							rect.origin.x,							rect.origin.y + rect.size.height,		0.0,
							rect.origin.x + rect.size.width,		rect.origin.y + rect.size.height,		0.0 };
	
    glBindTexture(GL_TEXTURE_2D, _name);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) drawInRect:(CGRect)rect withTexCoords:(CGRect)textCoords withSecondTexture:(Texture2D*)texture2
{
	GLfloat	 coordinates[] = {  textCoords.origin.x,                        textCoords.origin.y,
								textCoords.origin.x+textCoords.size.width,	textCoords.origin.y,
								textCoords.origin.x,                        textCoords.origin.y+textCoords.size.height,
								textCoords.origin.x+textCoords.size.width,  textCoords.origin.y+textCoords.size.height};
	GLfloat	 coordinates2[] = { 0.0f,0.0f, -1.0f,0.0f, 0.0f,-1.0f, -1.0f,-1.0f };
	GLfloat	vertices[] = {	rect.origin.x,							rect.origin.y,							0.0,
							rect.origin.x + rect.size.width,		rect.origin.y,							0.0,
							rect.origin.x,							rect.origin.y + rect.size.height,		0.0,
							rect.origin.x + rect.size.width,		rect.origin.y + rect.size.height,		0.0 };
	
	glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
    glBindTexture(GL_TEXTURE_2D, _name);
	
    if (texture2) {
        glClientActiveTexture(GL_TEXTURE1); // second texture
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(2, GL_FLOAT, 0, coordinates2);
            
        // Enable 2D texturing for the second texture.
        glActiveTexture(GL_TEXTURE1);
        glEnable(GL_TEXTURE_2D);

        glBindTexture(GL_TEXTURE_2D, texture2.name);
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_INTERPOLATE);   //Interpolate RGB with RGB
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_TEXTURE);
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_PREVIOUS);
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_RGB, GL_TEXTURE);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND2_RGB, GL_SRC_ALPHA);

        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_INTERPOLATE);   //Interpolate ALPHA with ALPHA
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_TEXTURE);
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_PREVIOUS);
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_ALPHA, GL_TEXTURE);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND2_ALPHA, GL_SRC_ALPHA);
    }
        
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glActiveTexture(GL_TEXTURE1);
    glDisable(GL_TEXTURE_2D);
    
	glClientActiveTexture(GL_TEXTURE0); 
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glActiveTexture(GL_TEXTURE0);    
}

@end
