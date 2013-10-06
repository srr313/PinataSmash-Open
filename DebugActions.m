//
//  DebugActions.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/10/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "DebugActions.h"

@implementation DebugActions

@synthesize useLocks;

+(DebugActions*)getDebugActions {
    static DebugActions* sDebugActions = nil;
    if (!sDebugActions) {
        sDebugActions = [[DebugActions alloc] init];
    }
    return sDebugActions;
}

-(id)init {
    if (self == [super init]) {
        useLocks = true;
    }
    return self;
}

@end
