//
//  JJNearbySharingService.m
//  iShare
//
//  Created by Jin Jin on 13-9-10.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import "JJNearbySharingService.h"

@interface JJNearbySharingService ()

@property (nonatomic, copy) NSString* internalName;
@property (nonatomic, strong) MCNearbyServiceAdvertiser* adverties;
@property (nonatomic, strong) MCNearbyServiceBrowser* browser;
@property (nonatomic, strong) NSMutableSet* peers;

@property (nonatomic, strong) MCPeerID* currentPeer;

@end

@implementation JJNearbySharingService

static __strong JJNearbySharingService* sService;

+(void)setDefaultService:(JJNearbySharingService *)service{
    sService = service;
}

+(JJNearbySharingService*)defaultService{
    return sService;
}

-(id)initWithName:(NSString *)serviceName{
    self = [super init];
    if (self){
        self.internalName = serviceName;
        self.currentPeer = [[MCPeerID alloc] initWithDisplayName:self.internalName];
        self.adverties = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.currentPeer
                                                           discoveryInfo:nil
                                                             serviceType:kServiceType];
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.currentPeer
                                                        serviceType:kServiceType];
        
        self.peers = [NSMutableSet set];
    }
    
    return self;
}

-(NSString*)serviceName{
    return self.internalName;
}

#pragma mark - action
-(void)startService{
    [self.adverties startAdvertisingPeer];
}

-(void)stopService{
    [self.adverties stopAdvertisingPeer];
}

-(void)startBrowserPeers{
    [self.browser startBrowsingForPeers];
}

#pragma mark - status
-(BOOL)isRunning{
//    return self.adverties
    return NO;
}

#pragma mark - advertiser delegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler{
    [self.peers addObject:peerID];
    MCSession* session = [[MCSession alloc] initWithPeer:peerID];
    session.delegate = self;
    invitationHandler(YES, session);
}

// Advertising did not start due to an error
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error{
    // TODO
}

#pragma mark - browser delegate
// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
    [self.peers addObject:peerID];
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    [self.peers removeObject:peerID];
}

// Browsing did not start due to an error
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error{
    
}

#pragma mark - session delegate
// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    switch (state) {
        case MCSessionStateConnected:
            break;
        case MCSessionStateConnecting:
            break;
        case MCSessionStateNotConnected:
            break;
        default:
            break;
    }
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
}

@end
