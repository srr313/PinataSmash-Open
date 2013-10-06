//
//  JiggleAnimation.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/18/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "JiggleAnimation.h"

@implementation JiggleAnimation

@synthesize t, scale;

-(id)init {
    if (self == [super init]) {
        scale = 1.0f;
        t = 0.0f;
        frequency = 0.0f;
        amplitude = 0.0f;
        duration = 0.0f;
        timeSinceLastJiggle = 0.0f;
    }
    return self;
}

-(void)jiggleFreq:(float)freq andAmplitude:(float)amp andDuration:(float)dur {
        frequency = freq;
        amplitude = amp;
        duration = dur;
        timeSinceLastJiggle = 0.0f;
}

-(void)tick:(float)timeElapsed {
    if (![self jiggling]) {
        return;
    }
    t += timeElapsed;
    timeSinceLastJiggle += timeElapsed;
    float jiggleProgress = timeSinceLastJiggle/duration;
    if (jiggleProgress >= 1.0f) {
        duration = 0.0f;
        scale = 1.0f;
        timeSinceLastJiggle -= timeElapsed;
    }
    else {
        scale = 1.0f+(1.0f-jiggleProgress)*amplitude*sinf(t*frequency);
    }
}

-(Boolean)jiggling {
    return duration > 0.0f;
}

-(void)stop {
    duration = 0.0f;
}

@end
