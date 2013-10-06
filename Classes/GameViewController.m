//
//  GameViewController.m
//
//  Created by Sean Rosenbaum on 10/2/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#import "GameViewController.h"
#import "CrystalSession.h"
#import "EAGLView.h"
#import "ES1Renderer.h"

@implementation GameViewController

@synthesize glView;

-(void)startAnimation {
    [glView startAnimation];
}

-(void)stopAnimation {
    [glView stopAnimation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIDeviceOrientationPortraitUpsideDown);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {  
    [CrystalSession willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [CrystalSession didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)didBecomeActive {
    if ([glView inGame]) {
        [glView changeFlowState:kFlowState_Pause];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
    [glView release];    
    [super dealloc];
}

@end
