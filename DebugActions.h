//
//  DebugActions.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/10/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEBUG_ACTIONS [DebugActions getDebugActions]

@interface DebugActions : NSObject {
    Boolean useLocks;
}

+(DebugActions*)getDebugActions;
@property (nonatomic) Boolean useLocks;

@end