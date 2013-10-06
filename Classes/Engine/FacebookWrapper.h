//
//  FacebookWrapper.h
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/6/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#ifdef ENABLE_FACEBOOK_DIRECT

#import <Foundation/Foundation.h>
#import "FBConnect.h"
#import "Localize.h"

#define FACEBOOK_OBJ [FacebookWrapper getFacebook]

@interface FacebookWrapper : NSObject {

}

+(void)publishToFacebook:(eLocalizedString)message 
                    andImagePath:(NSString*)imagePath 
                    andDelegate:(id<FBDialogDelegate>)delegate;
+(void)authorizeWithDelegate:(id<FBSessionDelegate>)delegate;

@end

#endif