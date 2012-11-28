//
//  UserPreferenceDefine.m
//  BreezyReader
//
//  Created by Jin Jin on 10-7-20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UserPreferenceDefine.h"

#define PREFERENCEBUNDLENAME_PHONE	@"UserDefaultSetting_phone"
#define PREFERENCEBUNDLENAME_PAD	@"UserDefaultSetting_pad"

@implementation UserPreferenceDefine

static NSDictionary* preferenceBundle = nil;

+(void)valueChangedForKey:(NSString*)key value:(id)value{
	[[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

+(NSDictionary*)userPreferenceBundle{
	if (!preferenceBundle){
		
		NSString* bundleName = PREFERENCEBUNDLENAME_PHONE;
		
		NSString *filePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"plist"];
		
		preferenceBundle = [[NSDictionary alloc] initWithContentsOfFile:filePath];
	}
	
	return preferenceBundle;
}

#pragma mark - new for Breezy Reader 2
+(id)valueForIdentifier:(NSString*)identifier{
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:identifier];
    
    if (obj == nil){
        NSDictionary* setting = [self userPreferenceBundle];
        obj = [setting objectForKey:identifier];
    }
    
    DebugLog(@"value for identifier: %@ is %@",identifier, obj);
    
    return obj;
}

+(BOOL)boolValueForIdentifier:(NSString*)identifier{
    return [[self valueForIdentifier:identifier] boolValue];
}

+(void)valueChangedForIdentifier:(NSString*)identifier value:(id)value{
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:identifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
