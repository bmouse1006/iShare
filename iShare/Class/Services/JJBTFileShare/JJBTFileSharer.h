//
//  JJBTFileSharer.h
//  iShare
//
//  Created by Jin Jin on 12-9-6.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "JJBTSender.h"

#define CurrentVersion @"1.0"

typedef enum {
    JJBTFileSharerStatusStandBy,
    JJBTFileSharerStatusSending,
    JJBTFileSharerStatusReceiving
} JJBTFileSharerStatus;

@class JJBTFileSharer;

@protocol JJBTFileSharerDelegate <NSObject>

//配对失败
//-(void)sharerPairFailed:(JJBTFileSharer*)sharer withError:(NSError*)error;
//配对成功
//-(void)sharerPairSucceeded:(JJBTFileSharer*)sharer;
//文件发送状态
-(void)sharerDidStartSending:(JJBTFileSharer*)sharer;
-(void)sharerDidEndSending:(JJBTFileSharer*)sharer;
-(void)sharerDidStartReceiving:(JJBTFileSharer*)sharer headContent:(NSDictionary*)headContent;
-(void)sharerDidEndReceiving:(JJBTFileSharer*)sharer;

-(void)sharer:(JJBTFileSharer*)sharer willStartSendingWithIdentifier:(NSString*)identifier;
-(void)sharer:(JJBTFileSharer*)sharer willStartReceivingWithIdentifier:(NSString*)identifier;
-(void)sharer:(JJBTFileSharer*)sharer didSendBytes:(long long)bytes identifier:(NSString*)identifier;
-(void)sharer:(JJBTFileSharer *)sharer didReceiveBytes:(long long)bytes identifier:(NSString *)identifier;
-(void)sharer:(JJBTFileSharer*)sharer finishedSendingWithIdentifier:(NSString*)identifier;
-(void)sharer:(JJBTFileSharer*)sharer finishedReceivingWithIdentifier:(NSString*)identifier;

-(void)sharer:(JJBTFileSharer*)sharer currentTransitionFailed:(NSError*)error;
-(void)sharerTransitionCancelled:(JJBTFileSharer*)sharer;

-(void)sharerIsDisconnectedWithPair:(JJBTFileSharer*)sharer;

@end

@interface JJBTFileSharer : NSObject<GKSessionDelegate, JJBTSenderDelegate>

@property (nonatomic, weak) id<JJBTFileSharerDelegate> delegate;
@property (nonatomic, readonly) JJBTFileSharerStatus status;
@property (nonatomic, readonly) NSArray* currentTransferingFiles;
@property (nonatomic, readonly) NSString* currentTransferingFile;

+(id)defaultSharer;
+(void)setDefaultGKSession:(GKSession*)session;

-(NSArray*)allSenders;

-(BOOL)isConnected;
-(NSString*)nameOfPair;
//-(void)shakingHands;
-(void)sendFiles:(NSArray*)files;
-(void)sendPhotos:(NSArray*)photos;

-(void)cancelSending;
-(void)endSession;
//
-(JJBTFileSharerStatus)status;
-(NSInteger)countOfSendingFiles;
-(NSInteger)countOfReceivingFiles;

@end
