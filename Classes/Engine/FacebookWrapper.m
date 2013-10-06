//
//  FacebookWrapper.m
//  Electric Species
//
//  Created by Sean Rosenbaum on 11/6/10.
//  Copyright 2010 BlitShake LLC. All rights reserved.
//

#ifdef ENABLE_FACEBOOK_DIRECT

#import "FacebookWrapper.h"
#import "GameCommon.h"

@implementation FacebookWrapper

+(Facebook*)getFacebook {
    static Facebook* sFacebook = nil;
    if (sFacebook == nil) {
        sFacebook = [[Facebook alloc] initWithAppId:FACEBOOK_API_KEY];
    }
    return sFacebook;
}

+(void)publishToFacebook:(eLocalizedString)message 
            andImagePath:(NSString*)imagePath 
            andDelegate:(id<FBDialogDelegate>)delegate {
    NSString* facebookName = LocalizeText(message);
    NSString* facebookCaption = LocalizeText(kLocalizedString_Caption);    
    NSString* facebookDescription = LocalizeText(kLocalizedString_Description); 
    NSString* facebookMessagePrompt = LocalizeText(kLocalizedString_MessagePrompt); 

    SBJSON *jsonWriter = [SBJSON new];

    NSDictionary* actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys: 
                                    @"Piñata Smash", @"text",
                                    @"http://on.fb.me/9hREU9", @"href", 
                                    nil], nil];

    NSString *actionLinksStr = [jsonWriter stringWithObject:actionLinks];
    
    NSDictionary* media = [NSArray arrayWithObjects: [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"image", @"type",
                                    imagePath, @"src",
                                    FACEBOOK_APP_URL, @"href",
                                    nil], nil];
                                    
    NSDictionary* attachment = [NSDictionary dictionaryWithObjectsAndKeys:
                                    facebookName, @"name",               
                                    facebookCaption, @"caption",         
                                    facebookDescription, @"description", 
                                    media, @"media",
                                    FACEBOOK_APP_URL, @"href", 
                                    nil];
                                    
    NSString *attachmentStr = [jsonWriter stringWithObject:attachment];
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    FACEBOOK_API_KEY, @"api_key",
                                    facebookMessagePrompt,  @"user_message_prompt",
                                    actionLinksStr, @"action_links",
                                    attachmentStr, @"attachment",
                                    nil];
                                    
    [jsonWriter release];

    [FACEBOOK_OBJ dialog: @"stream.publish"
            andParams:params
            andDelegate:self];
}

+(void)authorizeWithDelegate:(id<FBSessionDelegate>)delegate {
    NSArray* permissions =  [NSArray arrayWithObjects: 
                      @"publish_stream", 
                      @"offline_access", // necessary?
                      nil];
    [FACEBOOK_OBJ authorize:permissions delegate:delegate]; 
}

@end

#endif
