//
//  Particles.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 9/18/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "Particles.h"
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "GameCommon.h"

#define HIT_FRAMES              7
#define SWOOSH_FRAMES           4
#define EXPLOSION_FRAMES        6
#define SMOKEPUFF_FRAMES        6
#define SPARKLE_FRAMES          5
#define PARTICLE_FRAME_DURATION 4

@implementation Particle

@synthesize position, velocity, angle, scaleX, scaleY, color, 
            timeLeft, totalLifetime, type, maxScale, layer, 
            pulsing, maxFrames, framesPerStage;

-(id)initAt:(Vector2D)pos andVelocity:(Vector2D)vel andAngle:(float)ang
    andScaleX:(float)scaX andScaleY:(float)scaY andColor:(Color3D)col andTotalLifetime:(float)tlt 
    andType:(eParticleType)pt andTexture:(eTexture)tx {
    if (self == [super init]) {
        [self initDataAt:pos 
                andVelocity:vel 
                andAngle:ang 
                andScaleX:scaX
                andScaleY:scaY 
                andColor:col 
                andTotalLifetime:tlt 
                andType:pt
                andTexture:tx];
    }
    return self;
}

-(void)initDataAt:(Vector2D)pos andVelocity:(Vector2D)vel andAngle:(float)ang
    andScaleX:(float)scaX andScaleY:(float)scaY andColor:(Color3D)col andTotalLifetime:(float)tlt 
    andType:(eParticleType)pt andTexture:(eTexture)tx {
    position    = pos;
    velocity    = vel;
    angle       = ang;
    scaleX      = scaX;
    scaleY      = scaY;
    maxScale    = fmaxf(scaX,scaY);
    color       = col;
    totalLifetime = tlt;
    timeLeft = tlt;
    type        = pt;
    layer       = kLayer_Game;
    tex         = tx;
    pulsing     = false;
    pulseT      = 0.0f;
    frame       = 0;
    maxFrames   = 0;
    framesPerStage = 0;
    
    // start with initial animation state
    [self tick:0.0f];
}

-(Boolean)isAlive {
    return timeLeft > 0.0f;
}

- (void)render:(float)timeElapsed {
    if (color.alpha <= 0.0f) {
        return;
    }
    
    if (frame > maxFrames) {
        return;
    }

    Texture2D* texture = nil;
    if (framesPerStage) {
        int tFrame = frame;
        int stage = 0;
        while (true) {
            tFrame -= framesPerStage[stage];
            if (tFrame > 0) {
                ++stage;
            }
            else {
                break;
            }
        }
        texture = GetTexture(tex+stage);
    }
    else {
        texture = GetTexture(tex+frame/PARTICLE_FRAME_DURATION);    
    }

    if (pulsing) {
        pulseT      += timeElapsed;
        float pulse = fabsf(sinf(5.0f*pulseT));
    
        glLoadIdentity();
        glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
        glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);
        glScalef((1.0f+pulse)*scaleX, (1.0f+pulse)*scaleY, 1.0f);        
        glColor4f(1.0f, 1.0f, 1.0f, 0.5f*color.alpha*pulse); 
        [texture draw];             
    }

    glLoadIdentity();
    glTranslatef(ToScreenScaleX(position.x), ToScreenScaleY(position.y), 0.0f);
    glRotatef(angle*RAD_TO_DEGR,0.0f,0.0f,1.0f);
    glScalef(scaleX, scaleY, 1.0f);
    glColor4f(color.red,color.green,color.blue, color.alpha);
    [texture draw];
}

-(void)tick:(float)timeElapsed {
    timeLeft -= timeElapsed;
    if (timeLeft <= 0.0f) {
        return;
    }
    
    float fractionSpent = (1.0f-timeLeft/totalLifetime);

    switch (type) {
    case kParticleType_Candy:
        {
            velocity.y  -= CANDY_FALL_SPEED * timeElapsed;
            angle       += CANDY_SPIN_RATE*timeElapsed;

            float expansion = fminf(1.0f, 2.0f*sinf(M_PI*fractionSpent));
            scaleX = scaleY = maxScale*expansion;
            color.alpha     = expansion;
            break;
        }
    case kParticleType_Confetti:
        {
            color.alpha = 1.0f-fractionSpent;
            angle       += CONFETTI_SPIN_RATE*timeElapsed;
            break;
        }        
    case kParticleType_Spark:
        {
            scaleX      += timeElapsed * maxScale;
            color.alpha = 1.0f-fractionSpent;
            break;        
        }        
    case kParticleType_Vegetable:
        {
            velocity.y  -= VEGETABLE_FALL_SPEED * timeElapsed;
            angle       += VEGETABLE_SPIN_RATE*timeElapsed;

            float expansion = fminf(1.0f, 2.0f*sinf(M_PI*fractionSpent));
            scaleX = scaleY = maxScale*expansion;
            color.alpha     = expansion;
            break;
        }
    case kParticleType_Balloon:
        {
            velocity.x      = 25.0f*sinf(4.0f*M_PI*fractionSpent);
            color.alpha     = fminf(1.0f, 2.0f*sinf(M_PI_2*fractionSpent));      
            float expansion = fminf(1.0f, 2.0f*sinf(M_PI*fractionSpent));                        
            scaleX = scaleY = maxScale*expansion;
            break;  
        }               
    case kParticleType_Basic:
        {
            float expansion = fminf(1.0f, 2.0f*sinf(M_PI*fractionSpent));
            color.alpha     = expansion;        
            break;
        }        
    case kParticleType_Mist:
        {
            scaleX = scaleY = 1.0f+(maxScale-1.0f)*sinf(M_PI*fractionSpent);
            color.alpha     = 1.0f-fractionSpent;
            break;        
        }
    case kParticleType_Animated:
        {
            ++frame;
            break;
        }
    default: break;
    }
        
    position = Vector2DAdd(position, Vector2DMul(velocity,timeElapsed));
}
@end


@implementation ParticleManager

+(ParticleManager*)getParticleManager {
    static ParticleManager* sParticleManager = nil;
    if (sParticleManager == nil) {
        sParticleManager = [[ParticleManager alloc] init];
    }
    return sParticleManager;    
}

-(void)createVegetableExplosionAt:(Vector2D)pos withAmount:(int)n {
    int remaining = (PARTICLE_MAX-activeParticles.count);
    int numToAdd = MIN(n, remaining);
    for (int i = 0; i < numToAdd; ++i) {
        Particle* p = [self NewParticleAt:pos 
                                andVelocity:MakeRandVector2D(900.0f) 
                                andAngle:TWO_PI*random()/(float)RAND_MAX 
                                andScaleX:VEGETABLE_MAX_SIZE 
                                andScaleY:VEGETABLE_MAX_SIZE 
                                andColor:COLOR3D_WHITE 
                                andTotalLifetime:VEGETABLE_LIFETIME 
                                andType:kParticleType_Vegetable
                                andTexture:kTexture_Vegetable];        
        [activeParticles addObject:p];
        [p release];
    }
}

-(void)createLaserFrom:(Vector2D)start
                    to:(Vector2D)end
                    withColor:(Color3D)color {
    Vector2D dir = Vector2DSub(end, start);
    float distance = Vector2DMagnitude(dir);
    Vector2DNormalize(&dir);
    
    float speed = 1200.0f;
    Vector2D velocity = Vector2DMul(dir, speed);
    Particle* p = [self NewParticleAt:start 
                            andVelocity:velocity
                            andAngle:atan2f(dir.y,dir.x)
                            andScaleX:0.0f 
                            andScaleY:1.5f 
                            andColor:color 
                            andTotalLifetime:LASER_LIFETIME 
                            andType:kParticleType_Spark
                            andTexture:kTexture_White];  
    p.maxScale = distance;
    [activeParticles addObject:p];
    [p release];
}

-(void)createSparkAt:(Vector2D)pos 
                    withAmount:(int)n 
                    withColor:(Color3D)color
                    withSpeed:(float)speed 
                    withScale:(float)scale
                    withLayer:(eLayer)layer
{
    int remaining = (PARTICLE_MAX-activeParticles.count);
    int numToAdd = MIN(n, remaining);
    float angle = TWO_PI*random()/(float)RAND_MAX;
    float angleIncr = TWO_PI/(float)numToAdd;
    for (int i = 0; i < numToAdd; ++i) {
        Particle* p = [self NewParticleAt:pos 
                                andVelocity:Vector2DMake(2.5f*speed*cosf(angle),2.5f*speed*sinf(angle)) 
                                andAngle:angle
                                andScaleX:0.0f 
                                andScaleY:scale 
                                andColor:color 
                                andTotalLifetime:SPARK_LIFETIME 
                                andType:kParticleType_Spark
                                andTexture:kTexture_White];  
        p.maxScale = speed;
        p.layer = layer;
        [activeParticles addObject:p];
        [p release];
        angle += angleIncr;
    }
}

-(void)createExplosionAt:(Vector2D)pos withScale:(float)sca withLarge:(Boolean)large withLayer:(eLayer)layer {
    Particle* p = [self NewParticleAt:pos 
                        andVelocity:MakeRandVector2D(0.0f) 
                        andAngle:0.0f
                        andScaleX:EXPLOSION_MAX_SIZE*sca
                        andScaleY:EXPLOSION_MAX_SIZE*sca
                        andColor:COLOR3D_WHITE
                        andTotalLifetime:EXPLOSION_LIFETIME 
                        andType:kParticleType_Animated
                        andTexture:(large)?kTexture_LargeExplosionBegin:kTexture_SmallExplosionBegin];        
    p.layer = layer;
    p.maxFrames = EXPLOSION_FRAMES*PARTICLE_FRAME_DURATION;
    [activeParticles addObject:p];
    [p release];
}

-(void)createSparkleAt:(Vector2D)pos withLayer:(eLayer)layer {
    Particle* p = [self NewParticleAt:pos 
                        andVelocity:MakeRandVector2D(0.0f) 
                        andAngle:0.0f
                        andScaleX:1.0f
                        andScaleY:1.0f
                        andColor:COLOR3D_WHITE
                        andTotalLifetime:SPARKLE_LIFETIME 
                        andType:kParticleType_Animated
                        andTexture:kTexture_SparkleBegin];        
    p.layer = layer;
    p.maxFrames = SPARKLE_FRAMES*PARTICLE_FRAME_DURATION;
    [activeParticles addObject:p];
    [p release];
}

-(void)createSmokePuffAt:(Vector2D)pos withScale:(float)sca withLayer:(eLayer)layer {
    Particle* p = [self NewParticleAt:pos 
                        andVelocity:MakeRandVector2D(0.0f) 
                        andAngle:0.0f
                        andScaleX:sca
                        andScaleY:sca
                        andColor:COLOR3D_WHITE
                        andTotalLifetime:SMOKEPUFF_LIFETIME 
                        andType:kParticleType_Animated
                        andTexture:kTexture_SmokePuffBegin];        
    p.layer = layer;
    static const int SmokePuffFrames[] = {1, 2, 1, 2, 1, 1};
    p.framesPerStage = (int*)SmokePuffFrames;
    p.maxFrames = 8;
    [activeParticles addObject:p];
    [p release];
}

-(void)createCandyExplosionAt:(Vector2D)pos withAmount:(int)n withLayer:(eLayer)layer {
    int remaining = (PARTICLE_MAX-activeParticles.count);
    int numToAdd = MIN(n, remaining);
    for (int i = 0; i < numToAdd; ++i) {
        Particle* p = [self NewParticleAt:pos 
                                andVelocity:MakeRandVector2D(900.0f) 
                                andAngle:TWO_PI*random()/(float)RAND_MAX 
                                andScaleX:CANDY_MAX_SIZE 
                                andScaleY:CANDY_MAX_SIZE 
                                andColor:COLOR3D_WHITE 
                                andTotalLifetime:CANDY_LIFETIME 
                                andType:kParticleType_Candy
                                andTexture:kTexture_CandyBegin+rand()%(kTexture_CandyEnd-kTexture_CandyBegin)];        
        p.layer = layer;
        [activeParticles addObject:p];
        [p release];
    }
}

-(void)createConfettiAt:(Vector2D)pos withAmount:(int)n withLayer:(eLayer)layer {    
    int remaining = (PARTICLE_MAX-activeParticles.count);
    int numToAdd = MIN(n, remaining);
    for (int i = 0; i < numToAdd; ++i) { 
        Particle* p = [self NewParticleAt:pos 
                                andVelocity:MakeRandVector2D(250.0f) 
                                andAngle:TWO_PI*random()/(float)RAND_MAX 
                                andScaleX:CONFETTI_MAX_SIZE 
                                andScaleY:CONFETTI_MAX_SIZE 
                                andColor:COLOR3D_WHITE
                                andTotalLifetime:CONFETTI_LIFETIME 
                                andType:kParticleType_Confetti
                                andTexture:kTexture_ConfettiBegin+rand()%(kTexture_ConfettiEnd-kTexture_ConfettiBegin)];     
        p.layer = layer;
        [activeParticles addObject:p];
        [p release];
    }
}

-(void)createSwooshAt:(Vector2D)pos {
    Particle* p = [self NewParticleAt:pos 
                            andVelocity:MakeRandVector2D(0.0f) 
                            andAngle:0.0f
                            andScaleX:1.0f 
                            andScaleY:1.0f 
                            andColor:COLOR3D_WHITE
                            andTotalLifetime:SWOOSH_LIFETIME 
                            andType:kParticleType_Animated
                            andTexture:kTexture_TapMissBegin];        
    p.maxFrames = SWOOSH_FRAMES*PARTICLE_FRAME_DURATION;                            
    [activeParticles addObject:p];
    [p release];
}

-(void)createHitAt:(Vector2D)pos {
    Particle* p = [self NewParticleAt:pos 
                            andVelocity:MakeRandVector2D(0.0f) 
                            andAngle:0.0f
                            andScaleX:1.0f 
                            andScaleY:1.0f 
                            andColor:COLOR3D_WHITE
                            andTotalLifetime:HIT_LIFETIME 
                            andType:kParticleType_Animated
                            andTexture:kTexture_HitBegin];        
    p.maxFrames = HIT_FRAMES*PARTICLE_FRAME_DURATION;                            
    [activeParticles addObject:p];
    [p release];
}

-(void)createMistAt:(Vector2D)pos withColor:(Color3D)color withScale:(float)scale {
    Particle* p = [self NewParticleAt:pos 
                            andVelocity:MakeRandVector2D(0.0f) 
                            andAngle:0.0f
                            andScaleX:MIST_MAX_SIZE*scale
                            andScaleY:MIST_MAX_SIZE*scale
                            andColor:color 
                            andTotalLifetime:MIST_LIFETIME 
                            andType:kParticleType_Mist
                            andTexture:kTexture_Mist];        
    [activeParticles addObject:p];
    [p release];
}


-(id)init {
    if (self == [super init]) {
        activeParticles = [[NSMutableArray alloc] initWithCapacity:PARTICLE_MAX];
        freeParticles   = [[NSMutableArray alloc] initWithCapacity:PARTICLE_MAX];
    }            
    return self;
}

-(Particle*)NewParticleAt:(Vector2D)pos andVelocity:(Vector2D)vel andAngle:(float)ang
    andScaleX:(float)scaX andScaleY:(float)scaY andColor:(Color3D)col andTotalLifetime:(float)tlt 
    andType:(eParticleType)pt  andTexture:(eTexture)tex {
    
    Particle* p = nil;
    if (freeParticles.count > 0) {
        p = [freeParticles lastObject];
        [p retain];
        [freeParticles removeLastObject];
        
        [p initDataAt:pos 
            andVelocity:vel 
            andAngle:ang 
            andScaleX:scaX
            andScaleY:scaY 
            andColor:col 
            andTotalLifetime:tlt 
            andType:pt
            andTexture:tex];
    }
    else {
        p = [[Particle alloc] 
                initAt:pos 
                andVelocity:vel 
                andAngle:ang 
                andScaleX:scaX
                andScaleY:scaY 
                andColor:col 
                andTotalLifetime:tlt 
                andType:pt
                andTexture:tex];
    }
    return p;
}

-(void)addParticle:(Particle*)p {
    [activeParticles addObject:p];
}

-(void)tick:(float)timeElapsed {
    NSMutableArray* deadList = [NSMutableArray array]; 
    for (Particle* p in activeParticles) {
        [p tick:timeElapsed];
        if (!p.isAlive) {
            [deadList addObject:p];
        }
    }
    [activeParticles removeObjectsInArray:deadList];
    [freeParticles addObjectsFromArray:deadList];
}

-(void)renderParticles:(float)timeElapsed inLayer:(eLayer)layer {
    for (Particle* particle in activeParticles) {
        if (particle.layer==layer) {
            [particle render:timeElapsed];
        }
    }
}    

-(void)clear {
    for (Particle* p in activeParticles) {
        p.timeLeft = 0.0f;
    }    
}

-(void)dealloc {
    [activeParticles release];
    [freeParticles release];
    [super dealloc];
}

@end
