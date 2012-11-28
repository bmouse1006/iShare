//
//  ISUserPreferenceDefine.m
//  iShare
//
//  Created by Jin Jin on 12-9-11.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISUserPreferenceDefine.h"

#define kEnableThumbnail @"enableThumbnail"
#define kRememberWIFIShare @"rememberWIFIShare"
#define kWifiShareIsEnabled @"wifiShareIsEnabled"
#define kHTTPShareAuthEnabled @"HttpShareAuthEnabled"
#define kHTTPShareUsername @"httpShareUsername"
#define kHTTPSharePassword @"httpSharePassword"
#define kHTTPSharePort @"httpSharePort"
#define kPasscodeEnabled @"passcodeEnabled"
#define kEnteredPasscode @"enteredPasscode"

@implementation ISUserPreferenceDefine

+(void)initialize{
    [super initialize];
//    [self setPasscode:nil];
    if ([self passcodeEnabled] == NO){
        [self setPasscode:nil];
    }
//    [self valueChangedForIdentifier:kEnableThumbnail value:[NSNumber numberWithBool:YES]];
//    [self valueChangedForIdentifier:kRememberWIFIShare value:[NSNumber numberWithBool:YES]];
}

+(NSString*)passcode{
    return [self valueForIdentifier:kEnteredPasscode];
}

+(void)setPasscode:(NSString*)passcode{
    [self valueChangedForIdentifier:kEnteredPasscode value:passcode];
    if ([self passcodeEnabled]){
        [self valueChangedForIdentifier:@"isPasscodeEnabled" value:@"cell_title_passcodeenabled"];
    }else{
        [self valueChangedForIdentifier:@"isPasscodeEnabled" value:@"cell_title_passcodedisabled"];
    }
}

+(BOOL)enableThumbnail{
    return [self boolValueForIdentifier:kEnableThumbnail];
}

+(BOOL)rememberStatusOfWifiShare{
    return [self boolValueForIdentifier:kRememberWIFIShare];
}

+(BOOL)wifiShareIsEnabled{
    return [self boolValueForIdentifier:kWifiShareIsEnabled];
}

+(BOOL)shouldAutoStartHTTPShare{
    return ([self rememberStatusOfWifiShare] && [self wifiShareIsEnabled]);
}

+(BOOL)HttpShareAuthEnabled{
    return [self boolValueForIdentifier:kHTTPShareAuthEnabled];
}

+(void)setHttpShareAuthEnabled:(BOOL)encrypted{
    [self valueChangedForIdentifier:kHTTPShareAuthEnabled value:[NSNumber numberWithBool:encrypted]];
}

+(NSString*)httpShareUsername{
    return [self valueForIdentifier:kHTTPShareUsername];
}

+(void)setHttpShareUsername:(NSString*)username{
    [self valueChangedForIdentifier:kHTTPShareUsername value:username];
}

+(NSString*)httpSharePassword{
    return [self valueForIdentifier:kHTTPSharePassword];
}

+(void)setHttpSharePassword:(NSString*)password{
    [self valueChangedForIdentifier:kHTTPSharePassword value:password];
}

+(NSUInteger)httpSharePort{
    return [[self valueForIdentifier:kHTTPSharePort] integerValue];
}

+(void)setHttpSharePort:(NSUInteger)port{
    [self valueChangedForIdentifier:kHTTPSharePort value:[NSNumber numberWithInteger:port]];
}

+(void)setHttpShareStarted:(BOOL)started{
    [self valueChangedForIdentifier:kWifiShareIsEnabled value:[NSNumber numberWithBool:started]];
}

+(BOOL)passcodeEnabled{
    return [self passcode].length != 0;
}

@end
