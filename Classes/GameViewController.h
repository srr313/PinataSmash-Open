//
//  GameViewController.h
//
//  Created by Sean Rosenbaum on 10/2/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "EAGLView.h"

@interface GameViewController : UIViewController {
    EAGLView* glView;
}

@property (nonatomic, retain) IBOutlet EAGLView* glView;

- (void)didBecomeActive;
-(void)startAnimation;
-(void)stopAnimation;

@end
