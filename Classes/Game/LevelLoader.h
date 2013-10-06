//
//  LevelLoader.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/16/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameCommon.h"
#import "OpenGLCommon.h"

@class GameLevel;

@interface LevelLoader : NSObject {  
}
+(void)loadAll;
+(GameLevel*)getLevel:(int)n inEpisode:(NSString*)episodePath;
+(int)levelCount;
+(int)getNumLevelsInEpisode:(NSString*)episodePath;
+(NSMutableArray*)getNumAchievementsInEpisode:(NSString*)episodePath;
+(float)getEpisodeCompletion:(NSString*)episodePath;
@end

//////////////////////////////////////////

@interface BodyLoad : NSObject {
    NSMutableArray* groups;
}

@property (nonatomic, assign) NSMutableArray* groups;
-(id)initWithPath:(NSString*)path;
-(id)initWithString:(NSString*)data;
@end

//////////////////////////////////////////

@interface GroupLoad : NSObject {
    NSMutableDictionary* attributes;
    NSString* typeName;
}
@property (nonatomic, assign) NSString* typeName;
-(id)initWithString:(NSString*)data;
-(Boolean)hasAttribute:(NSString*)key;
-(int)getAttributeBool:(NSString*)name;
-(int)getAttributeInt:(NSString*)name;
-(float)getAttributeFloat:(NSString*)name;
-(Vector2D)getAttributePosition:(NSString*)name;
-(Vector2D)getAttributeVector2D:(NSString*)name;
-(NSString*)getAttributeString:(NSString*)name;
@end

//////////////////////////////////////////

@interface AttributeLoad : NSObject {
    NSString* value;
}
-(id)initWithString:(NSString*)data;
-(Boolean)toBool;
-(int)toInt;
-(float)toFloat;
-(Vector2D)toVector2D;
-(NSString*)toString;
@end