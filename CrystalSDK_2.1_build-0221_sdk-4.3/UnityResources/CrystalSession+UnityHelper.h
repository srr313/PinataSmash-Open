//
//  CrystalSession+UnityHelper.h
//  Crystal
//
//  Created by Jai Byron on 25/01/2011.
//  Copyright 2011 Chillingo Ltd. All rights reserved.
//


#include "CrystalSession.h"

//	Helper functions to assist in data conversion for Unity Layer.

@interface CrystalSession (UnityHelper)

+ (NSString*) convertToNSString:(id)dataObject;
+ (id) convertDataStringToObject:(NSString*)dataString;

@end
