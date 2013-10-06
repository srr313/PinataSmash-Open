//
//  ScrollComponent.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 10/29/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "ScrollComponent.h"
#import "EAGLView.h"

@interface ScrollComponent()
-(float)screenSize;
-(void)nextPage;
-(void)previousPage;
@end


@implementation ScrollComponent

@synthesize direction, screenPageOffset, highlightCurrentPage, lockToNearestPage;

-(id)init {
    if (self == [super init]) {
        pages = [[NSMutableArray alloc] init];
                
        Vector2D screenDimensions = GetGLDimensions();
        currentMove             = 0.0f;
        previousMove            = 0.0f;        
        position                = Vector2DMul(screenDimensions, 0.5f);
        dimensions              = screenDimensions;
        direction               = kDirection_Horizontal;
        screenPageOffset        = 0.65f;
        highlightCurrentPage    = true;
        lockToNearestPage       = true;
        changingPage            = false;
        currentPage             = 0;
        moveStarted             = false;
        targetT                 = 0.0f;
    }
    return self;
}

-(void)dealloc {    
    [pages release];
    [super dealloc];
}

-(void)setDirection:(eDirection)dir {
    direction = dir;
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];

    if (changingPage) {
        targetT += 2.0f*timeElapsed;
        if (targetT >= 1.0f) {
            targetT = 1.0f;
            changingPage = false;
        }
        screenOffset    += targetT*(targetOffset-screenOffset);
    }

    float screenSize        = [self screenSize];
    float screenPageSize    = screenPageOffset*screenSize;
    int screenPage          = fmaxf(0.0f, nearbyintf(screenOffset/screenPageSize));

    for (NSDictionary* pageEntry in pages) {
        NSMutableArray* pageElements = [pageEntry objectForKey:@"ELEMENTS"];
        int pageNumber = [[pageEntry valueForKey:@"PAGE"] intValue];
        float pageOffset = pageNumber*screenPageSize;
        
        for (ScreenControl* control in pageElements) {
            Vector2D controlPosition = control.basePosition;
            if (direction == kDirection_Horizontal) {
                controlPosition.x += pageOffset-screenOffset;
            }
            else {
                controlPosition.y -= pageOffset-screenOffset;
            }
            control.position = controlPosition;
            
            if (pageNumber==screenPage) {
                if (highlightCurrentPage) {
                    [control setColor:COLOR3D_WHITE];
                }
            }
            else {
                if (highlightCurrentPage) {
                    [control setColor:Color3DMake(1.0f, 1.0f, 1.0f, 0.7f)];
                }
            }
        }
    }
}

-(Boolean)processEvent:(TapEvent)evt {
    
    float location = (direction==kDirection_Horizontal) 
                        ? evt.location.x : -evt.location.y;

    if (evt.type == kTapEventType_Start) {
        previousMove    = location;
        currentMove     = location;
        startMove       = location;
        moveStarted     = true;
    }
    else if (moveStarted && evt.type == kTapEventType_Move) {
        previousMove = currentMove;    
        currentMove = location;    
        
        if (!changingPage) {
            if (currentMove-startMove>50.0f) {
                [self previousPage];
                moveStarted = false;
            }
            else if (currentMove-startMove<-50.0f) {
                [self nextPage];        
                moveStarted = false;                
            }
        }
    }
    else if (evt.type == kTapEventType_End) {
        previousMove    = 0.0f;
        currentMove     = 0.0f;
        moveStarted     = false;
    }
    
    if ([super processEvent:evt]) {
        return true;
    }
    
    for (ScreenControl* child in children) {
        if ([child isInside:evt.location] && [child processEvent:evt]) {
            return true;
        }
    }
            
    return false;
}

-(void)addControl:(ScreenControl*)control toPage:(int)page {
    [super addChild:control];
    
    if ([control isKindOfClass:[ButtonControl class]]) {
        ((ButtonControl*)control).respondOnRelease = true;    
    }
    
    NSMutableDictionary* pageEntry = nil;
    NSMutableArray* pageElements = nil;

    for (NSMutableDictionary* entry in pages) {
        if ([[entry valueForKey:@"PAGE"] isEqualToNumber:[NSNumber numberWithInt:page]]) {
            pageEntry = entry;
            break;
        }
    }
        
    if (pageEntry) {
        pageElements = [pageEntry valueForKey:@"ELEMENTS"];
    }
    else {
        pageElements = [NSMutableArray array];
        
        NSDictionary* entryDict = [[NSMutableDictionary alloc] 
                                    initWithObjectsAndKeys:
                                        [NSNumber numberWithInt:page], @"PAGE", 
                                        pageElements, @"ELEMENTS", nil];                
        [pages addObject:entryDict];
                            
        NSSortDescriptor* descriptor = [[NSSortDescriptor alloc] initWithKey:@"PAGE" ascending:YES]; 
        NSArray* sortArray = [[NSArray alloc] initWithObjects:descriptor, nil];
        
        [pages sortUsingDescriptors: sortArray];
        
        [entryDict release];
        [sortArray release];
        [descriptor release];
    }
    
    [pageElements addObject:control];
}

-(void)setPage:(int)p {
    screenOffset    = [self pageOffset:p];
    currentPage     = p;
}

-(int)currentPage {
    return currentPage;
}

-(float)pageOffset:(int)p {
    return p*[self screenSize]*screenPageOffset;
}

-(float)screenSize {
    return (direction==kDirection_Horizontal) ? GetGLWidth() : GetGLHeight();
}

-(void)nextPage {
    int current = [self currentPage];
    if (current < pages.count-1) {
        ++currentPage;
    
        targetOffset = [self pageOffset:currentPage];   
        targetT      = 0.0f;        
        changingPage = true;     
    }  
}

-(void)previousPage {
    int current = [self currentPage];
    if (current > 0) {
        --currentPage;
    
        targetOffset = [self pageOffset:currentPage];            
        targetT      = 0.0f;
        changingPage = true;        
    }
}
    
@end
