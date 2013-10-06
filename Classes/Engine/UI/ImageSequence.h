//
//  ImageSequence.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 1/6/11.
//  Copyright 2011 Double Jump. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screen.h"

@interface ImageSequence : ScreenControl {
    NSMutableArray* frames; 
    int currentFrame;
    float currentFrameTime;
}

-(id)init;
-(void)dealloc;
-(void)tick:(float)timeElapsed;
-(void)render:(float)timeElapsed;
-(void)addImage:(ImageControl*)image;

@end
