//
//  JJHTTPSerivce.m
//  iShare
//
//  Created by Jin Jin on 12-9-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJHTTPSerivce.h"
#import "HTTPServer.h"
#import "FileOperationWrap.h"
#import "ISUserPreferenceDefine.h"
#import "ISHTTPConnection.h"
#import "GetAddresses.h"

@interface JJHTTPSerivce ()

@property (nonatomic, strong) HTTPServer* httpServer;

@end

@implementation JJHTTPSerivce

static NSInteger Default_Port = 80;

+(JJHTTPSerivce*)sharedSerivce{
    static dispatch_once_t onceToken;
    static JJHTTPSerivce* service = nil;
    dispatch_once(&onceToken, ^{
        service = [[self alloc] initWithPort:Default_Port];
        [service.httpServer setConnectionClass:[ISHTTPConnection class]];
    });
    
    return service;
}

+(BOOL)isServiceRunning{
    JJHTTPSerivce* instance = [JJHTTPSerivce sharedSerivce];
    return [instance.httpServer isRunning];
}

+(BOOL)authEnabled{
    JJHTTPSerivce* instance = [JJHTTPSerivce sharedSerivce];
    return instance.authEnabled;
}

-(BOOL)authEnabled{
    return [ISUserPreferenceDefine HttpShareAuthEnabled];
}

-(void)setAuthEnabled:(BOOL)authEnabled{
    [ISUserPreferenceDefine setHttpShareAuthEnabled:authEnabled];
}

-(void)setPort:(NSUInteger)port{
    self.httpServer.port = port;
    [ISUserPreferenceDefine setHttpSharePort:port];
    if ([[self class] isServiceRunning]){
        [self stopService];
        [self startService];
    }
}

-(void)setUsername:(NSString*)username{
    [ISUserPreferenceDefine setHttpShareUsername:username];
}

-(void)setPassword:(NSString*)password{
    [ISUserPreferenceDefine setHttpSharePassword:password];
}

-(id)initWithPort:(NSInteger)port{
    self = [super init];
    if (self){
        self.httpServer = [[HTTPServer alloc] init];
        
        // Tell the server to broadcast its presence via Bonjour.
        // This allows browsers such as Safari to automatically discover our service.
        [self.httpServer setType:@"_http._tcp."];
        // Normally there's no need to run our server on any specific port.
        // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
        // However, for easy testing you may want force a certain port so you can just hit the refresh button.
        [self.httpServer setPort:port];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
        NSString *currentLanguage = [languages objectAtIndex:0];
        
        NSString* webRoot = nil;
        if ([[currentLanguage lowercaseString] isEqualToString:@"zh_hans"]){
            webRoot = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"web_cn"];
        }else{
            webRoot = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"web_en"];
        }
        
        
        [self.httpServer setDocumentRoot:webRoot];
    }
    
    return self;
}

-(BOOL)startService{
    return [self.httpServer start:NULL];
}

-(BOOL)stopService{
    [self.httpServer stop:NO];
    return YES;
}

- (NSString *)fullURLString{
    return [NSString stringWithFormat:@"http://%@:%d", [self deviceIPAdress], self.httpServer.port];
}

- (NSString *)deviceIPAdress {
    InitAddresses();
    GetIPAddresses();
    GetHWAddresses();
    NSString* address = (ip_names[1] == NULL)?[NSString stringWithFormat:@"%s", ip_names[0]]:[NSString stringWithFormat:@"%s", ip_names[1]];
    
    return address;
}

@end
