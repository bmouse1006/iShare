//
//  ISUserPreferenceDefine.h
//  iShare
//
//  Created by Jin Jin on 12-9-11.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "UserPreferenceDefine.h"

@interface ISUserPreferenceDefine : UserPreferenceDefine

+(BOOL)enableThumbnail;
+(BOOL)rememberStatusOfWifiShare;
+(BOOL)wifiShareIsEnabled;
+(BOOL)HttpShareAuthEnabled;
+(void)setHttpShareAuthEnabled:(BOOL)encrypted;
+(NSString*)httpShareUsername;
+(void)setHttpShareUsername:(NSString*)username;
+(NSString*)httpSharePassword;
+(void)setHttpSharePassword:(NSString*)password;
+(NSUInteger)httpSharePort;
+(void)setHttpSharePort:(NSUInteger)port;
+(void)setHttpShareStarted:(BOOL)started;
+(BOOL)shouldAutoStartHTTPShare;
+(BOOL)passcodeEnabled;
+(NSString*)passcode;
+(void)setPasscode:(NSString*)passcode;

@end
