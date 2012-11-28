//
//  JJBTSender.h
//  iShare
//
//  Created by Jin Jin on 12-10-13.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#define BTBlockSize 8192
#define BTBlockHeadSize 1

@class JJBTSender;

typedef enum {
    BTSenderTypeFile,
    BTSenderTypePhoto,
    BTSenderTypeUnknown
} BTSenderType;

typedef enum {
    BTTransitionBlockTypeBundleHead = 0,
    BTTransitionBlockTypeBundleTail,
    BTTransitionBlockTypeHead,
    BTTransitionBlockTypeBody,
    BTTransitionBlockTypeTail,
    BTTransitionBlockTypeError
} BTTransitionBlockType;

@protocol JJBTSenderDelegate <NSObject>

-(void)btSenderStartedSending:(JJBTSender*)sender;
-(void)btSender:(JJBTSender*)sender finishedBytes:(long long)finishedBytes;
-(void)btSenderFinishedSending:(JJBTSender*)sender;
-(void)btSenderCancelledSending:(JJBTSender*)sender;
-(void)btSender:(JJBTSender *)sender failedWithError:(NSError*)error;

@end

@protocol JJBTSenderProtocol <NSObject>

@optional
-(NSInputStream*)readStream;
-(NSData*)headBlock;
-(NSData*)tailBlock;
-(NSData*)errorBlock;
-(NSString*)name;
-(long long)sizeOfObject;
-(BTSenderType)type;

@end

@interface JJBTSender : NSOperation<JJBTSenderProtocol>

@property (nonatomic, weak) id<JJBTSenderDelegate> delegate;
@property (nonatomic, strong) id sendingObj;
@property (nonatomic, strong) GKSession* session;
@property (nonatomic, assign) long long finishedSize;

+(NSString*)version;

-(BOOL)sendDataInBuffer:(UInt8*)buffer length:(NSUInteger)length error:(NSError **)error;
-(NSData*)blockWithType:(BTTransitionBlockType)type data:(NSData*)data;
-(NSData*)blockWithType:(BTTransitionBlockType)type buff:(const void*)buff length:(NSUInteger)length;

-(NSString*)identifier;

@end
