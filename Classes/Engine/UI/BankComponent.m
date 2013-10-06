//
//  BankComponent.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/1/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "BankComponent.h"

#define BANK_COUNT_TIME 1.5f

@interface BankComponent()
-(void)showAmount;
@end


@implementation BankComponent

-(id)initAt:(Vector2D)pos withAmount:(int)amount {
    if (self == [super initAt:pos withTexture:kTexture_BankPanel andText:kLocalizedString_Null]) {
        startAmount = 0;
        currentAmount = 0;
        targetAmount = 0;
        changeTime = 0.0f;
        tilting = true;
        [self setAmount: amount];
    }
    return self;
}

-(void)tick:(float)timeElapsed {
    [super tick:timeElapsed];
    
    if (currentAmount != targetAmount) {
        changeTime = fminf(changeTime+timeElapsed/BANK_COUNT_TIME,1.0f);
        int nextAmount = startAmount*(1.0f-changeTime) + targetAmount*changeTime;
        if (nextAmount != currentAmount) {
            currentAmount = nextAmount;
            [self showAmount];
        }
    }
}

-(void)adjustAmountBy:(int)amount {
    startAmount = currentAmount;
    targetAmount = currentAmount + amount;
    changeTime = 0.0f;
}

-(void)setAmount:(int)amount {
    startAmount = amount;
    currentAmount = amount;
    targetAmount = amount;
    changeTime = 0.0f;
    [self showAmount];
}

-(void)showAmount {
    if (textControl) {
        [children removeObject:textControl];
        [textControl release];
        textControl = nil;
    }
    
    NSString* amountString = [NSString stringWithFormat:@"%d", currentAmount]; // todo localize
    Vector2D textPosition = Vector2DMake(position.x,position.y-0.25f*ToGameScaleY(dimensions.y));    
    textControl = [[TextControl alloc] 
        initAt:textPosition
        withString:amountString
        andDimensions:Vector2DMake(ToGameScaleX(dimensions.x),ToGameScaleY(dimensions.y))
        andAlignment:UITextAlignmentCenter
        andFontName:DEFAULT_FONT andFontSize:32];
    textControl.jiggling = true;
    textControl.hasShadow = false;
    [self addChild:textControl];
    
    [self bounce];
}

@end
