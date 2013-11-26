//
//  JJNearbySharingService.h
//  iShare
//
//  Created by Jin Jin on 13-9-10.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

static NSString* kServiceType = @"iShare-jinjin";

@class JJNearbySharingService;

@protocol JJNearbySharingServiceDelegate <NSObject>


@end

@interface JJNearbySharingService : NSObject<MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate>

@property (readonly) NSString* serviceName;

+(void)setDefaultService:(JJNearbySharingService*)service;
+(JJNearbySharingService*)defaultService;

-(id)initWithName:(NSString*)serviceName;

-(void)startService;
-(void)stopService;
-(BOOL)isRunning;

-(void)startBrowserPeers;

-(void)sendFileAtURL:(NSURL*)url toPeer:(MCPeerID*)peer;

@end
