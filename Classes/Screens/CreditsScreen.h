//
//  CreditsScreen.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 12/28/10.
//  Copyright 2010 Double Jump. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screen.h"

@interface CreditsScreen : Screen {
    NSMutableArray* credits;
    NSArray* entries;
}

-(id)initWithFlowManager:(id<FlowManager>)fm;

@end
