//
//  LevelLoader.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/16/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "LevelLoader.h"
#import "EAGLView.h"
#import "GameLevel.h"
#import "SaveGame.h"

static NSMutableArray* levelLoaderLevels = nil;
static NSMutableDictionary* episodeLevels = nil;

// LEVEL ITERATOR PROTOCOL ////////////////////////
@protocol LevelIteratorAction<NSObject>
-(void)onLevel:(GameLevel*)lvl;
@end

// ACHIEVEMENT COUNTER //////////////////////////////////
@interface AchievementCounter : NSObject<LevelIteratorAction> {
    int gold;
    int silver;
    int bronze;
    int totalLevels;
}
@property (nonatomic,readonly) int gold;
@property (nonatomic,readonly) int silver; 
@property (nonatomic,readonly) int bronze; 
@property (nonatomic,readonly) int totalLevels; 
-(void)onLevel:(GameLevel*)lvl;
@end

@implementation AchievementCounter 
@synthesize gold, silver, bronze, totalLevels;
-(void)onLevel:(GameLevel *)lvl {
    if (lvl.achievement==kAchievement_Gold) {
        ++gold;
    }
    else if (lvl.achievement==kAchievement_Silver) {
        ++silver;
    }
    else if (lvl.achievement==kAchievement_Bronze) {
        ++bronze;
    }
    ++totalLevels;
}
@end

// COMPLETION COUNTER //////////////////////////////////

@interface LevelLoader()
+(void)loadLevel:(NSString*)text withPath:(NSString*)path inEpisode:(NSString*)episode;
@end


@implementation LevelLoader

+(void)loadAll { 
    NSAssert(!levelLoaderLevels, @"Levels already loaded!");
    levelLoaderLevels = [[NSMutableArray alloc] init];
    
    NSAssert(!episodeLevels, @"Episodes already loaded!");    
    episodeLevels = [[NSMutableDictionary alloc] init];

    BodyLoad* episodeSetBody = [[BodyLoad alloc] initWithPath:@"Episodes"];
    for (GroupLoad* episodeGroup in episodeSetBody.groups) {
        if ([episodeGroup.typeName caseInsensitiveCompare:@"EPISODE"]==NSOrderedSame) {
            
            NSString* episodePath = [[episodeGroup getAttributeString:@"PATH"] retain];
            BodyLoad* episodeBody = [[BodyLoad alloc] initWithPath:episodePath];
            
            #ifdef DEBUG_BUILD            
                NSLog(@"Loading levels...");
            #endif
            
            for (GroupLoad* levelGroup in episodeBody.groups) {
                if ([levelGroup.typeName caseInsensitiveCompare:@"LEVELS"]==NSOrderedSame) { 
                    int n = 0;
                    while (true) {
                        NSString* levelKey = [NSString stringWithFormat:@"LEVEL%d", n+1];
                        NSString* path = [levelGroup getAttributeString:levelKey];
                        if (!path) {
                            break;
                        }
                        
                        #ifdef DEBUG_BUILD                                    
                            NSLog(@"Loading %@", path);
                        #endif
                        
                        NSString* filePath = [[NSBundle mainBundle] pathForResource:path ofType:@"txt"];  
                        NSAssert(filePath, @"LevelLoader::LoadAll - invalid filePath");
                        
                        NSError*            error;
                        NSString *text = [NSString stringWithContentsOfFile:filePath usedEncoding:NULL error:&error];  
                        NSAssert(text, @"Unable to read level text file!");
                        
                        [LevelLoader loadLevel:text withPath:path inEpisode:episodePath];     
                        
                        ++n;
                    }
                }             
            }
            [episodeBody release];            
        }
    }
    [episodeSetBody release];
}

+(void)loadLevel:(NSString *)text withPath:(NSString*)path inEpisode:(NSString*)episode {
    GameLevel* lvl = [GameLevel loadLevel:text];
    lvl.uniqueID = path;
    
    NSMutableArray* levels = [episodeLevels objectForKey:episode];
    if (!levels) {
        levels = [[NSMutableArray alloc] initWithObjects:lvl, nil];
        [episodeLevels setObject:levels forKey:episode];
        [levels release];
    }
    else {
        [levels addObject:lvl];
    }
    
    NSMutableArray* levelStates = [SaveGame getLevelStates];    
    for (NSDictionary* levelState in levelStates) {
        NSString* levelName = [levelState objectForKey:ID_KEY];
        if ([levelName compare:lvl.uniqueID]==NSOrderedSame) {
            lvl.achievement = [[levelState objectForKey:ACHIEVEMENT_KEY] intValue];
        }
    }
    
    [levelStates release];
    [levelLoaderLevels addObject:lvl];
}

+(void)iterateLevels:(id<LevelIteratorAction>)action inEpisode:(NSString*)episodePath { 
    NSMutableArray* levels = [episodeLevels objectForKey:episodePath];
    
    for (GameLevel* lvl in levels) {        
        [action onLevel:lvl];
    }
}

+(int)getNumLevelsInEpisode:(NSString*)episodePath {
    NSMutableArray* levels = [episodeLevels objectForKey:episodePath];
    return levels.count;
}

+(NSMutableArray*)getNumAchievementsInEpisode:(NSString*)episodePath {
    AchievementCounter* counter = [[AchievementCounter alloc] init];
    [LevelLoader iterateLevels:counter inEpisode:episodePath];
    NSMutableArray* counts = [[NSMutableArray alloc] initWithCapacity:4];
    [counts addObject:[NSNumber numberWithInt:counter.gold]];
    [counts addObject:[NSNumber numberWithInt:counter.silver]];
    [counts addObject:[NSNumber numberWithInt:counter.bronze]];
    [counts addObject:[NSNumber numberWithInt:counter.totalLevels]];
    [counter release];
    return counts;
}

+(float)getEpisodeCompletion:(NSString*)episodePath {
    AchievementCounter* counter = [[AchievementCounter alloc] init];
    [LevelLoader iterateLevels:counter inEpisode:episodePath];
    float episodeCompletion = (counter.gold+counter.silver+counter.bronze)/(float)counter.totalLevels;
    [counter release];
    return episodeCompletion;
}

+(GameLevel*)getLevel:(int)n inEpisode:(NSString*)episodePath {
    NSMutableArray* levels = [episodeLevels objectForKey:episodePath];
    return [levels objectAtIndex:n];
}

+(int)levelCount {
    return levelLoaderLevels.count;
}

@end


/////////////////////////////////////////

@implementation BodyLoad
@synthesize groups;

-(id)initWithPath:(NSString*)path {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:path ofType:@"txt"];  
    NSAssert(filePath, @"Unable to find text file!");
    
    NSError*            error;
    NSString *text = [NSString stringWithContentsOfFile:filePath usedEncoding:NULL error:&error];  
    NSAssert(text, @"Unable to read text file!");
    
    return [self initWithString:text];
}

-(id)initWithString:(NSString*)data {
    if (self == [super init]) {
        NSArray* parts = [data componentsSeparatedByString:@"BEGIN"];
        NSAssert(parts, @"Unable to split text for level!");
    
        groups = [[NSMutableArray alloc] init];

        for (NSString* partStr in parts) {
            NSString* trimmed = [partStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([trimmed compare:@""]==NSOrderedSame) {
                continue;
            }
            GroupLoad* g = [[GroupLoad alloc] initWithString:trimmed];
            [groups addObject:g];
            [g release];
        }

    }
    return self;
}

-(void)dealloc {
    [groups release];
    [super dealloc];
}

@end


/////////////////////////////////////////

@implementation GroupLoad

@synthesize typeName;

-(Boolean)hasAttribute:(NSString*)key {
    return [attributes valueForKey:key]!=nil; 
}

-(id)initWithString:(NSString*)data {
    if (self == [super init]) {
        attributes = [[NSMutableDictionary alloc] init];
        NSArray* attributeLines = [data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]; 
        for (NSString* line in attributeLines) {
            NSString* trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([trimmed compare:@""]==NSOrderedSame) {
                continue;
            }        
        
            NSArray* attributeParts = [trimmed componentsSeparatedByString:@"="];
            NSString* key = [attributeParts objectAtIndex:0];
            if ([key caseInsensitiveCompare:@"NAME"]==NSOrderedSame) {
                typeName = [attributeParts objectAtIndex:1];
                continue;
            }
            else if ([key caseInsensitiveCompare:@"END"]==NSOrderedSame) {
                break;
            }
            
            NSAssert(attributeParts.count==2,@"Not enough components on line");
            AttributeLoad* attribute = [[AttributeLoad alloc] initWithString:[attributeParts objectAtIndex:1]];
            [attributes setValue:attribute forKey:key];
            [attribute release];
        }
    }
    return self;
}

-(void)dealloc {
    [attributes release];
    [super dealloc];
}

-(int)getAttributeBool:(NSString*)name {
     AttributeLoad* attribute = [attributes valueForKey:name];
     return (attribute) ? [attribute toBool] : false;
}

-(int)getAttributeInt:(NSString*)name {
     AttributeLoad* attribute = [attributes valueForKey:name];
     return (attribute) ? [attribute toInt] : 0;
}

-(float)getAttributeFloat:(NSString*)name {
     AttributeLoad* attribute = [attributes valueForKey:name];
     return (attribute) ? [attribute toFloat] : 0.0f;
}

-(Vector2D)getAttributePosition:(NSString*)name {
    AttributeLoad* attribute = [attributes valueForKey:name];
    if (attribute) {
        Vector2D position = [attribute toVector2D];
        position.x *= GetGLWidth();
        position.y *= GetGLHeight();
        return position;
    }
    return ZeroVector();
}

-(Vector2D)getAttributeVector2D:(NSString*)name {
     AttributeLoad* attribute = [attributes valueForKey:name];
     return (attribute) ? [attribute toVector2D] : ZeroVector();
}

-(NSString*)getAttributeString:(NSString*)name {
     AttributeLoad* attribute = [attributes valueForKey:name];
     return (attribute) ? [attribute toString] : nil;
}
@end

/////////////////////////////////////////

@implementation AttributeLoad

-(id)initWithString:(NSString*)data {
    if (self == [super init]) {
        value = data;
    }
    return self;
}

-(Boolean)toBool {
    return [value boolValue];
}

-(int)toInt {
    return [value intValue];
}

-(float)toFloat {
    return [value floatValue];
}

-(Vector2D)toVector2D {
    NSArray* coords = [value componentsSeparatedByString:@","];
    NSAssert(coords.count==2,@"AttributeLoad::toVector2D - not enough coords for attribute");
    Vector2D v = Vector2DMake( 
        [[[coords objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] floatValue],
        [[[coords objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] floatValue] );
    return v;
}

-(NSString*)toString {
    return value;
}

@end