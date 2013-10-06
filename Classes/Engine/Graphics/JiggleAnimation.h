//
//  JiggleAnimation.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/18/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JiggleAnimation : NSObject {
@private
    // output
    float scale;
    
    // properties
    float t;
    float timeSinceLastJiggle;
    float amplitude;
    float frequency;
    float duration;
}

@property (nonatomic) float t;
@property (nonatomic) float scale;

-(id)init;
-(void)jiggleFreq:(float)freq andAmplitude:(float)amp andDuration:(float)dur;
-(void)tick:(float)timeElapsed;
-(void)stop;
-(Boolean)jiggling;

@end
