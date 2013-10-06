//
//  Particles.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/18/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenGLCommon.h"
#import "ESRenderer.h"

#define PARTICLE_MAX 150

#define HIT_LIFETIME    0.5f
#define SWOOSH_LIFETIME 0.5f

#define VEGETABLE_LIFETIME 2.0f
#define VEGETABLE_FALL_SPEED 600.0f
#define VEGETABLE_SPIN_RATE 2.0f
#define VEGETABLE_MAX_SIZE 1.0f

#define CANDY_LIFETIME 2.0f
#define CANDY_FALL_SPEED 600.0f
#define CANDY_SPIN_RATE 2.0f
#define CANDY_MAX_SIZE 1.0f

#define CONFETTI_SPIN_RATE 1.5f
#define CONFETTI_LIFETIME 1.0f
#define CONFETTI_MAX_SIZE 1.0f

#define EXPLOSION_MAX_SIZE 1.0f
#define EXPLOSION_LIFETIME 0.5f

#define SMOKEPUFF_LIFETIME 0.5f
#define SPARKLE_LIFETIME   0.5f

#define NEGATIVE_MAX_SIZE 1.5f
#define NEGATIVE_LIFETIME 1.0f

#define SPARK_LIFETIME 0.25f
#define LASER_LIFETIME 0.25f

#define MIST_MAX_SIZE   1.25f
#define MIST_LIFETIME   0.5f

#define PARTICLE_MANAGER [ParticleManager getParticleManager]

typedef enum {
    kLayer_Game = 0,
    kLayer_UI,
} eLayer;

typedef enum {
    kParticleType_Basic,
    kParticleType_Candy,
    kParticleType_Confetti,
    kParticleType_Animated,  
    kParticleType_Vegetable,
    kParticleType_Spark,
    kParticleType_Mist,
    kParticleType_Balloon,
    kParticleType_Count,
}  eParticleType;

@interface Particle : NSObject {
@public
    Vector2D    position;
    Vector2D    velocity;
    Color3D     color;
    float       angle;
    float       scaleX;
    float       scaleY;
    float       maxScale;
    float       timeLeft;
    float       totalLifetime;
    eParticleType type;
    eTexture    tex;
    eLayer      layer;
    Boolean     pulsing;
    float       pulseT;
    int         frame;
    int         maxFrames;
    int*        framesPerStage;
}
@property (nonatomic) Vector2D position;
@property (nonatomic) Vector2D velocity;
@property (nonatomic) Color3D color;
@property (nonatomic) float angle;
@property (nonatomic) float scaleX;
@property (nonatomic) float scaleY;
@property (nonatomic) float maxScale;
@property (nonatomic) float timeLeft;
@property (nonatomic) float totalLifetime;
@property (nonatomic) eParticleType type;
@property (nonatomic) eLayer layer;
@property (nonatomic) Boolean pulsing;
@property (nonatomic) int maxFrames;
@property (nonatomic) int* framesPerStage;
-(id)initAt:(Vector2D)pos andVelocity:(Vector2D)vel andAngle:(float)ang
    andScaleX:(float)scaX andScaleY:(float)scaY andColor:(Color3D)col andTotalLifetime:(float)tlt 
    andType:(eParticleType)pt andTexture:(eTexture)texture;
-(void)initDataAt:(Vector2D)pos andVelocity:(Vector2D)vel andAngle:(float)ang
    andScaleX:(float)scaX andScaleY:(float)scaY andColor:(Color3D)col andTotalLifetime:(float)tlt
    andType:(eParticleType)pt andTexture:(eTexture)texture;
-(void)tick:(float)timeElapsed;
-(Boolean)isAlive;
-(void)render:(float)timeElapsed;
@end

@interface ParticleManager : NSObject {
@private
    NSMutableArray* activeParticles;
    NSMutableArray* freeParticles;
}
+(ParticleManager*)getParticleManager;
-(id)init;
-(void)createVegetableExplosionAt:(Vector2D)pos withAmount:(int)n;
-(void)createLaserFrom:(Vector2D)start
                    to:(Vector2D)end
                    withColor:(Color3D)color;
-(void)createSparkAt:(Vector2D)pos 
                    withAmount:(int)n 
                    withColor:(Color3D)color
                    withSpeed:(float)speed
                    withScale:(float)scale
                    withLayer:(eLayer)layer; 
-(void)createExplosionAt:(Vector2D)pos withScale:(float)sca withLarge:(Boolean)large withLayer:(eLayer)layer;
-(void)createSparkleAt:(Vector2D)pos withLayer:(eLayer)layer;
-(void)createCandyExplosionAt:(Vector2D)pos withAmount:(int)n withLayer:(eLayer)layer;
-(void)createConfettiAt:(Vector2D)pos withAmount:(int)n withLayer:(eLayer)layer;
-(void)createSwooshAt:(Vector2D)pos;
-(void)createSmokePuffAt:(Vector2D)pos withScale:(float)sca withLayer:(eLayer)layer;
-(void)createSparkleAt:(Vector2D)pos withLayer:(eLayer)layer;
-(void)createHitAt:(Vector2D)pos;
-(void)createMistAt:(Vector2D)pos withColor:(Color3D)color withScale:(float)scale;
-(void)addParticle:(Particle*)p;
-(void)tick:(float)timeElapsed;
-(void)renderParticles:(float)timeElapsed inLayer:(eLayer)layer;
-(Particle*)NewParticleAt:(Vector2D)pos andVelocity:(Vector2D)vel andAngle:(float)ang
    andScaleX:(float)scaX andScaleY:(float)scaY andColor:(Color3D)col andTotalLifetime:(float)tlt
    andType:(eParticleType)pt andTexture:(eTexture)texture;
-(void)clear;
@end
