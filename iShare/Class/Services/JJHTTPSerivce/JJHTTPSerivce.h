//
//  JJHTTPSerivce.h
//  iShare
//
//  Created by Jin Jin on 12-9-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JJHTTPSerivce : NSObject

@property (nonatomic, assign) BOOL authEnabled;

+(id)sharedSerivce;
+(BOOL)isServiceRunning;
+(BOOL)authEnabled;

-(void)setPort:(NSUInteger)port;
-(void)setUsername:(NSString*)username;
-(void)setPassword:(NSString*)password;

-(BOOL)startService;
-(BOOL)stopService;

-(NSString*)fullURLString;

@end
