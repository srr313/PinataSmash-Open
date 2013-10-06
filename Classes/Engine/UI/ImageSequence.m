//
//  ImageSequence.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 1/6/11.
//  Copyright 2011 Double Jump. All rights reserved.
//

#import "ImageSequence.h"
#import "Screen.h"

#define TIME_PER_FRAME (10.0f/60.0f)

@implementation ImageSequence

-(id)init {
    if (self = [super init]) {
        frames = [[NSMutableArray alloc] init];
        currentFrame = 0;
    }
    return self;
}

-(void)dealloc {
    [frames release];
    [super dealloc];
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    [[frames objectAtIndex:currentFrame] tick:timeElapsed];
    currentFrameTime += timeElapsed;
    if (currentFrameTime > TIME_PER_FRAME) {
        currentFrameTime = 0.0f;
        currentFrame = (currentFrame+1)%frames.count;
    }
}

-(void)render:(float)timeElapsed {
    ImageControl* image = [frames objectAtIndex:currentFrame];
    image.scale = scale;
    [image render:timeElapsed];
}

-(void)addImage:(ImageControl*)image {
    [frames addObject:image];
}


@end
