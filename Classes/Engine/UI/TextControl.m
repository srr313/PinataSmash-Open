//
//  TextControl.m
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

@implementation TextControl

-(id)initAt:(Vector2D)pos withText:(eLocalizedString)locText andArg:(NSObject*)arg andDimensions:(Vector2D)dim
    andAlignment:(UITextAlignment)alignment andFontName:(NSString*)font andFontSize:(int)size {
    NSString* locStr = LocalizeTextArgs(locText, arg);
    return [self initAt:pos withString:locStr andDimensions:dim andAlignment:alignment andFontName:font andFontSize:size];
}
-(id)initAt:(Vector2D)pos withString:(NSString*)str andDimensions:(Vector2D)dim
    andAlignment:(UITextAlignment)alignment andFontName:(NSString*)font andFontSize:(int)size {
    if (self == [super init]) {
        jiggling = false;
        [self resetTo:pos withString:str andDimensions:dim andAlignment:alignment andFontName:font andFontSize:size];
    }
    return self;
}
-(void)resetTo:(Vector2D)pos withString:(NSString*)str andDimensions:(Vector2D)dim
    andAlignment:(UITextAlignment)alignment andFontName:(NSString*)font andFontSize:(int)size {
    position = pos;
    basePosition = pos;
    texture = kTexture_Null;
    
    NSString* stringWithFormatting = [str stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];    
    
    [texture2D release];
    texture2D = [[Texture2D alloc] 
        initWithString:stringWithFormatting 
        dimensions:CGSizeMake(ToScreenScaleX(dim.x), ToScreenScaleY(dim.y))
        alignment:alignment 
        fontName:font 
        fontSize:ToScreenScaleY(size)];
    
    dimensions = Vector2DMake(texture2D.pixelsWide,texture2D.pixelsHigh);
}
-(Texture2D*)getLocalTexture2D {
    return texture2D;
}
-(void)dealloc {
    [texture2D release];
    [super dealloc];
}

@end
