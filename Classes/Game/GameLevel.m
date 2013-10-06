//
//  GameLevel.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/14/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "GameLevel.h"
#import "Bungee.h"
#import "EAGLView.h"
#import "Game.h"
#import "LevelLoader.h"
#import "Localize.h"
#import "Parachute.h"
#import "Particles.h"
#import "Spawner.h"
#import "Tool.h"

@implementation GameRule

@synthesize gold, silver, bronze, metric;

-(id)initWithGroup:(GroupLoad *)group {
    if (self == [super init]) {
        comparison = [group getAttributeInt:@"COMPARISON"];
        metric = [group getAttributeInt:@"METRIC"];
        bronze = [group getAttributeFloat:@"BRONZE"];
        silver = [group getAttributeFloat:@"SILVER"];
        gold = [group getAttributeFloat:@"GOLD"];
    }
    return self;
}

-(eAchievement)evaluate:(Game*)game {
    int lhs = INT_MAX;
    switch (metric) {
    case kGameRule_Time:
        lhs = game.levelTime;
        break;
    case kGameRule_Shots:
        lhs = game.tool.count;
        break;
    default:
        NSAssert(false,@"GameRule::evaluate - invalid metric!");
        break;
    }
    
    lhs -= game.metricBonusAwarded;
    
    return [self getMedalForMetric:lhs];
}

-(eAchievement)getMedalForMetric:(int)metricValue {
    if (comparison==[[NSNumber numberWithInt:metricValue] compare:[NSNumber numberWithInt:gold]]) {
        return kAchievement_Gold;
    }    
    else if (comparison==[[NSNumber numberWithInt:metricValue] compare:[NSNumber numberWithInt:silver]]) {
        return kAchievement_Silver;
    }    
    else if (comparison==[[NSNumber numberWithInt:metricValue] compare:[NSNumber numberWithInt:bronze]]) {
        return kAchievement_Bronze;
    }    
    return kAchievement_Failed;
}

@end

//////////////////////////////////////

@implementation GameMessage

@synthesize text, images, delay;

-(id)initText:(eLocalizedString)t andDelay:(float)d {
    if (self = [super init]) {
        text    = t;
        images  = [[NSMutableArray alloc] init];
        delay   = d;
    }
    return self;
}

-(void)dealloc {
    [images release];
    [super dealloc];
}

@end


//////////////////////////////////////

@implementation GameLevel

@synthesize initialCandy, candyRequired, consumeAmount, consumeDelay, 
            displayCurrencyTip, achievement, uniqueID, title, rule;

-(id)initWithGame:(Game*)game {
    if (self == [super init]) {
        spawners    = [[NSMutableArray alloc] init];
        messages    = [[NSMutableArray alloc] init];
        tutorials   = [[NSMutableArray alloc] init]; 
        currentMessage      = 0;
        currentTutorial     = 0;
        displayCurrencyTip  = FALSE;
    }
    return self;
}

-(void)addSpawner:(Spawner*)spawner {
    [spawners addObject:spawner];
}

-(void)addMessage:(GameMessage*)message {
    [messages addObject:message];
}

-(eLocalizedString)nextMessage {
    if (currentMessage < messages.count) {
        GameMessage* message = [messages objectAtIndex:currentMessage];
        ++currentMessage;
        return message.text;
    }
    return kLocalizedString_Null;
}

-(Boolean)isNextMessageReady:(float)timeElapsed {
    if (currentMessage < messages.count) {
        GameMessage* message = [messages objectAtIndex:currentMessage];
        if (timeElapsed > message.delay) {
            return true;
        }
    }
    return false;
}

-(void)addTutorialMessage:(GameMessage*)message {
    [tutorials addObject:message];
}

-(Boolean)isNextTutorialMessageReady:(float)timeElapsed {
    if (currentTutorial < tutorials.count) {
        GameMessage* message = [tutorials objectAtIndex:currentMessage];
        if (timeElapsed > message.delay) {
            return true;
        }
    }
    return false;
}

-(GameMessage*)nextTutorialMessage {
    if (currentTutorial < tutorials.count) {
        GameMessage* message = [tutorials objectAtIndex:currentTutorial];
        ++currentTutorial;
        return message;
    }
    return nil;
}

-(void)tick:(float)timeElapsed {
    for (Spawner* s in spawners) {
        [s tick:timeElapsed];
    }
}

+(GameLevel*)loadLevel:(NSString*)levelStr {
    GameLevel* level = [[GameLevel alloc] initWithGame:nil];
    BodyLoad* body = [[BodyLoad alloc] initWithString:levelStr];
    for (GroupLoad* group in body.groups) {
        if ([group.typeName caseInsensitiveCompare:@"PINATA_SPAWNER"]==NSOrderedSame) {
            PinataSpawner* spawner = [[PinataSpawner alloc] initWithGroup:group];
            [level addSpawner:spawner];
            [spawner release];
        }
        else if ([group.typeName caseInsensitiveCompare:@"POWERUP_SPAWNER"]==NSOrderedSame) {
            PowerupSpawner* spawner = [[PowerupSpawner alloc] initWithGroup:group];
            [level addSpawner:spawner];
            [spawner release];
        }
        else if ([group.typeName caseInsensitiveCompare:@"CLOUD_SPAWNER"]==NSOrderedSame) {
            CloudSpawner* spawner = [[CloudSpawner alloc] initWithGroup:group];
            [level addSpawner:spawner];
            [spawner release];
        }        
        else if ([group.typeName caseInsensitiveCompare:@"HEADER"]==NSOrderedSame) {
            level.achievement = [group getAttributeInt:@"STATE"];
            level.title = [[group getAttributeString:@"TITLE"] copy];
            level.initialCandy = [group getAttributeInt:@"INITIAL_CANDY"];
            level.consumeAmount = [group getAttributeInt:@"CONSUME_AMOUNT"];
            level.consumeDelay = [group getAttributeInt:@"CONSUME_DELAY"];
            level.candyRequired = [group getAttributeInt:@"CANDY_REQUIRED"];
            level.displayCurrencyTip = [group getAttributeBool:@"DISPLAY_CURRENCY_TIP"];
            
            for (int i = 1; i <= INT_MAX; ++i) {
                NSString* messageKey = [NSString stringWithFormat:@"MESSAGE%d", i];
                if (![group hasAttribute:messageKey]) {
                    break;
                }
                NSString* messageText = [[group getAttributeString:messageKey] copy];                
                float messageDelay = [group getAttributeFloat:[messageKey stringByAppendingFormat:@"_DELAY"]];
                GameMessage* message = [[GameMessage alloc] initText:messageText andDelay:messageDelay];
                [level addMessage:message];
                [message release];
            }
            for (int i = 1; i <= INT_MAX; ++i) {
                NSString* tutorialKey = [NSString stringWithFormat:@"TUTORIAL%d", i];
                if (![group hasAttribute:tutorialKey]) {
                    break;
                }
                NSString* tutorialText  = [[group getAttributeString:tutorialKey] copy];                
                float tutorialDelay     = [group getAttributeFloat:[tutorialKey stringByAppendingFormat:@"_DELAY"]];
                GameMessage* message    = [[GameMessage alloc] initText:tutorialText andDelay:tutorialDelay];
                
                for (int j = 1; j <= INT_MAX; ++j) {
                    NSString* tutorialImage = [[group getAttributeString:[tutorialKey stringByAppendingFormat:@"_IMAGE%d",j]] copy];                                                
                    if (!tutorialImage) {
                        break;
                    }
                    [message.images addObject:tutorialImage];
                }
                
                [level addTutorialMessage:message];
                [message release];
            }            
        }
        else if ([group.typeName caseInsensitiveCompare:@"RULE"]==NSOrderedSame) {
            NSAssert(!level.rule, @"GameLevel::LoadLevel - rule already exists!");
            level.rule = [[GameRule alloc] initWithGroup:group];
        }
    }

    [body release];
    return level;
}

-(void)reset:(Game*)g {
    game = g;
    currentMessage = 0;
    currentTutorial = 0;
    for (Spawner* s in spawners) {
        s.game = g;
        [s reset];
    }
}

-(void)dealloc {
    [spawners release];
    [messages release];
    [tutorials release];
    [rule release];
    [super dealloc];
}

@end
