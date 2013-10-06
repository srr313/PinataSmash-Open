//
//  Candy.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/13/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import "Candy.h"
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "Game.h"
#import "JiggleAnimation.h"
#import "Particles.h"

#define CANDY_DRAG 0.995f
#define CANDY_FLOATING_LIFETIME 3.0f
#define CANDY_PIECE_CANDIES 10.0f

//#define CANDY_PULSING_ENABLED
#define REWARD_FOR_FLOATERS

@interface Candy()
-(void)stayInBounds:(float)speed;
-(void)resetAt:(Vector2D)p andVelocity:(Vector2D)v forGame:(Game*)g;
@end


@implementation Candy

@synthesize position, alive;

static NSMutableArray* bucket = nil;

+(Candy*)CreateCandyAt:(Vector2D)p andVelocity:(Vector2D)v forGame:(Game*)g {
    if (!bucket) {
        bucket = [[NSMutableArray alloc] init];
    }
    
    Candy* candy = nil;
    if (bucket.count > 0) {
        candy = [[bucket lastObject] retain];
        [candy resetAt:p andVelocity:v forGame:g];
        [bucket removeLastObject];
    }
    else {
        candy = [[Candy alloc] initAtPosition:p andVelocity:v forGame:g];
    }
    
    return candy;
}

+(void)Recycle:(Candy*)c {
    [bucket addObject: c];
}

-(id)initAtPosition:(Vector2D)p andVelocity:(Vector2D)v forGame:(Game*)g {
    if (self == [super init]) {
        [self resetAt:p andVelocity:v forGame:g];
        animation = [[JiggleAnimation alloc] init];
    }
    return self;
}

-(void)dealloc {
    [animation release];
    [super dealloc];
}

-(void)resetAt:(Vector2D)p andVelocity:(Vector2D)v forGame:(Game*)g {
    position = p;
    velocity = v;
    game = g;
    angle = random()/(float)RAND_MAX;
    [animation jiggleFreq:15.0f andAmplitude:0.25f andDuration:FLT_MAX];
    color = Color3DMake(random()/(float)RAND_MAX,random()/(float)RAND_MAX,random()/(float)RAND_MAX,0.0f);
    
    timeFloating = 0.0f;
    state = kCandyState_Floating;
    fallingT = 0.0f;
    alive = true;
    
    particleType = kTexture_CandyBegin + rand()%(kTexture_CandyEnd-kTexture_CandyBegin);
}

-(void)stayInBounds:(float)speed {
    if (position.x > game.labWidth) {
        velocity.x = -fabsf(velocity.x);
    }
    else if (position.x < 0.0f) {
        velocity.x = fabsf(velocity.x);    
    }
    
    if (position.y > game.labHeight) {
        velocity.y = -fabsf(velocity.y);
    }
    else if (position.y < 0.0f) {
        velocity.y = fabsf(velocity.y);    
    }
}

-(Boolean)isInside:(CGPoint)p {
    Vector2D dim = GetImageDimensions(kTexture_Candy_01);    
    return fabsf(p.x-position.x) <= 0.75f*dim.x*animation.scale &&
           fabsf(p.y-position.y) <= 0.75f*dim.y*animation.scale;
}

-(void)tick:(float) timeElapsed {
    angle += timeElapsed;
    [animation tick:timeElapsed];
    
    if (state == kCandyState_Floating) {   
        timeFloating += timeElapsed;        
        velocity = Vector2DMul(velocity, CANDY_DRAG);
        position = Vector2DAdd(position, Vector2DMul(velocity, timeElapsed));
        [self stayInBounds:Vector2DMagnitude(velocity)];
        
        color.alpha = fmaxf(0.0f, (CANDY_FLOATING_LIFETIME-timeFloating)/CANDY_FLOATING_LIFETIME);        
        
        if (timeFloating > CANDY_FLOATING_LIFETIME) {
            alive = false;
            
#ifdef REWARD_FOR_FLOATERS
            [game addCandy:CANDY_PIECE_CANDIES useMultiplier:false];
#endif
        }
    }
    else {
        fallingT += 1.2f*timeElapsed;
        float tSq = fallingT*fallingT;
        position.x = (1.0f-tSq)*fallStartPosition.x+tSq*GetGLWidth()/2;
        position.y = (1.0f-tSq)*fallStartPosition.y+20.0f;
        color.alpha = 4.0f*(1.0f-fallingT)*fallingT;
        
        alive = (fallingT < 1.0f);
    }
}

-(Boolean)trigger {
    if (state != kCandyState_Floating || !alive) {
        return false;
    }
        
    fallStartPosition = position;
    state = kCandyState_Collected;
    [animation jiggleFreq:10.0f andAmplitude:1.0f andDuration:0.5f];
        
    return true;
}

-(void)addForce:(Vector2D)force {
    velocity = Vector2DAdd(velocity, force);        
}

- (void)render:(float)timeElapsed {
    if (!alive) {
        return;
    }
    Texture2D* texture = GetTexture(particleType);
    float angleDegree = angle*RAD_TO_DEGR;

    #ifdef CANDY_PULSING_ENABLED
    {
        glLoadIdentity();
        glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
        glRotatef(angleDegree,0.0f,0.0f,1.0f);
        glScalef(1.4f*animation.scale, 1.4f*animation.scale, 1.0f);        
        
        float glow = 0.5f*fabsf(sinf(10.0f*(fallingT+timeFloating)));
        glColor4f(1.0f, 1.0f, 0.0f,color.alpha*glow); 
        [texture draw];             
    }
    #endif
                                
    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
    glRotatef(angleDegree,0.0f,0.0f,1.0f);
    glScalef(animation.scale, animation.scale, 1.0f);        
    glColor4f(1.0f,1.0f,1.0f,color.alpha); 
    [texture draw];   
}

@end