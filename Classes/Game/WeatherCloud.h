//
//  WeatherCloud.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 3/26/11.
//  Copyright 2011 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Game;

@interface WeatherCloud : NSObject {
    Game*   game;
    float   descendT;
    float   descendTarget;
    float   lastRain;
    Boolean raining;
    float   fractionDogs;
    float   fallSpeed;
    float   lifetime;
}

@property (nonatomic) float fractionDogs;
@property (nonatomic) float fallSpeed;
@property (nonatomic) float spawnDelay;
@property (nonatomic) float lifetime;

-(id)initForGame:(Game*)g;
-(void)tick:(float)timeElapsed;
-(void)render:(float)timeElapsed;
-(void)setRain:(Boolean)flag;
@end
