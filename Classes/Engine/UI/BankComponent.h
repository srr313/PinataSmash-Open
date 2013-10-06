//
//  BankComponent.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/1/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screen.h"

@interface BankComponent : ButtonControl {
    int startAmount;
    int currentAmount;
    int targetAmount;
    float changeTime;
}

-(id)initAt:(Vector2D)pos withAmount:(int)amount;
-(void)tick:(float)timeElapsed;
-(void)adjustAmountBy:(int)amount;
-(void)setAmount:(int)amount;

@end
