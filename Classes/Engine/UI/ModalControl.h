//
//  ModalControl.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/1/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screen.h"

@interface ModalControl : ScreenControl {
    SEL closeSelector;
    id closeResponder;
    float particleT;
    float timeForNextParticle;
    ButtonControl* closeButton;
}

+(ModalControl*)createModalWithMessage:(eLocalizedString)message andArg:(NSObject*)arg andFontSize:(int)fontSize;
+(ModalControl*)createModalWithMessage:(eLocalizedString)message andArg:(NSObject*)arg andButton:(ButtonControl*)button;
+(ModalControl*)createModalWithMessage:(eLocalizedString)message andArg:(NSObject*)arg andImages:(NSArray*)images;

@property (nonatomic,assign) ButtonControl* closeButton;

-(id)init;
-(Boolean)isInside:(CGPoint)p;
-(Boolean)processEvent:(TapEvent)evt;
-(void)setCloseResponder:(id)resp andSelector:(SEL)sel;

@end
