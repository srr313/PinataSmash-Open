//
//  ScrollComponent.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/29/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screen.h"

typedef enum {
    kDirection_Horizontal,
    kDirection_Vertical,
} eDirection;

@interface ScrollComponent : ScreenControl {
    NSMutableArray* pages;
    float velocity;
    float startMove;
    float previousMove;
    float currentMove;
    float screenOffset;
    float targetOffset;
    int lastScreenPage;
    eDirection direction;
    float screenPageOffset;
    Boolean highlightCurrentPage;
    Boolean lockToNearestPage;
    Boolean changingPage;
    int currentPage;
    Boolean moveStarted;
    float targetT;
}

@property (nonatomic) eDirection direction;
@property (nonatomic) float screenPageOffset;
@property (nonatomic) Boolean highlightCurrentPage;
@property (nonatomic) Boolean lockToNearestPage;

-(id)init;
-(void)dealloc;
-(void)tick:(float)timeElapsed;
-(Boolean)processEvent:(TapEvent)evt;
-(void)addControl:(ScreenControl*)control toPage:(int)page;
-(void)setPage:(int)p;
-(float)pageOffset:(int)p;
-(int)currentPage;
@end
