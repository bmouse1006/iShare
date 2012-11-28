//
//  UserPreferenceDefine.h
//  BreezyReader
//
//  Created by Jin Jin on 10-7-20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserPreferenceDefine : NSObject

+(id)valueForIdentifier:(NSString*)identifier;
+(BOOL)boolValueForIdentifier:(NSString*)identifier;
+(void)valueChangedForIdentifier:(NSString*)identifier value:(id)value;

+(NSDictionary*)userPreferenceBundle;

@end