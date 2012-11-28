//
//  JJBTSender.m
//  iShare
//
//  Created by Jin Jin on 12-10-13.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJBTSender.h"

@interface JJBTSender(){
    __strong NSString* _identifier;
}

@end

@implementation JJBTSender

-(long long)sizeOfObject{
    return 0;
}

-(NSString*)name{
    return @"";
}

-(BTSenderType)type{
    return BTSenderTypeUnknown;
}

-(BOOL)sendDataInBuffer:(UInt8*)buffer length:(NSUInteger)length error:(NSError **)error;{
    NSData* data = [NSData dataWithBytes:buffer length:length];
    return [self.session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:error];
}

-(NSInputStream*)readStream{
    return nil;
}

-(void)main{
    @autoreleasepool {
        //get png data
        NSInputStream* readStream = [self readStream];
        [readStream open];
        
        self.finishedSize = 0;
        
        @try {      
            NSError* error = nil;
            if ([self.delegate respondsToSelector:@selector(btSenderStartedSending:)]){
                [self.delegate btSenderStartedSending:self];
            }
            //send head block
            BOOL result = [self.session sendDataToAllPeers:[self headBlock] withDataMode:GKSendDataReliable error:&error];
            DebugLog(@"sending head, result is %d, error is %@", result, error);
            if (error){
                @throw [self exceptionWithMessage:[error localizedDescription]];
            }
            long long total = 0;
            //send body
            while([readStream hasBytesAvailable] && self.isCancelled == NO){
                DebugLog(@"sending body");
                UInt8 buffer[BTBlockSize];
                buffer[0] = BTTransitionBlockTypeBody;
                //create head
                NSInteger readLength = [readStream read:buffer+BTBlockHeadSize maxLength:BTBlockSize-BTBlockHeadSize];
                if (readLength > 0){
                    NSData* sendData = [NSData dataWithBytes:buffer length:readLength+BTBlockHeadSize];
                    error = nil;
                    BOOL start = [self.session sendDataToAllPeers:sendData withDataMode:GKSendDataReliable error:&error];
                    if (start == NO || error){
                        //error happened
                        if ([self.delegate respondsToSelector:@selector(btSender:failedWithError:)]){
                            [self.delegate btSender:self failedWithError:error];
                            @throw [self exceptionWithMessage:[error localizedDescription]];
                        }
                    }else{
                        total += readLength;
                        if ([self.delegate respondsToSelector:@selector(btSender:finishedBytes:)]){
                            [self.delegate btSender:self finishedBytes:total];
                        }
                        
                        self.finishedSize = total;
                    }
                }
                
                [NSThread sleepForTimeInterval:0.03];
            }
            
            //send tail block
            [self.session sendDataToAllPeers:[self tailBlock] withDataMode:GKSendDataReliable error:&error];
            DebugLog(@"sending tail");
            if ([self.delegate respondsToSelector:@selector(btSenderFinishedSending:)]){
                [self.delegate btSenderFinishedSending:self];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Error happened in BT transimission: %@", exception.reason);
            [self.session sendDataToAllPeers:[self errorBlock] withDataMode:GKSendDataReliable error:NULL];
        }
        @finally {
            [readStream close];
        }

    }
}

//BTTransitionBlockTypeHead开始
//后面跟传输类型（文件，照片），名称，大小，统一标识符
//限制在一个block长度(8K)之内
-(NSData*)headBlock{
    
    NSDictionary* parameters = @{@"type" : [NSString stringWithFormat:@"%d", self.type], @"name":self.name, @"size":[NSString stringWithFormat:@"%llu", self.sizeOfObject], @"identifier":[self identifier], @"version":[[self class] version]};
    
    NSData* paramData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONReadingAllowFragments error:NULL];
    
    return [self blockWithType:BTTransitionBlockTypeHead data:paramData];
}

//BTTransitionBlockTypeTail开头
//后面跟文件名
//限制在一个block长度(8K)之内
-(NSData*)tailBlock{
    static NSString* tailString = @"******BTTransferTail******";
    return [self blockWithType:BTTransitionBlockTypeTail data:[tailString dataUsingEncoding:NSUTF8StringEncoding]];
}

//BTTransitionBlockTypeError开头
//后面跟文件名
//限制在一个block长度(8K)之内
-(NSData*)errorBlock{
    static NSString* errorString = @"******BTTransferError******";
    return [self blockWithType:BTTransitionBlockTypeTail data:[errorString dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSData*)blockWithType:(BTTransitionBlockType)type data:(NSData*)data{
    return [self blockWithType:type buff:[data bytes] length:[data length]];
}

-(NSData*)blockWithType:(BTTransitionBlockType)type buff:(const void*)buff length:(NSUInteger)length{
    UInt8 blockBuff[length + 1];
    
    blockBuff[0] = type;
    memcpy(blockBuff+1, buff, length);
    
    return [NSData dataWithBytes:blockBuff length:length+1];
}

-(NSException*)exceptionWithMessage:(NSString*)message{
    return [NSException exceptionWithName:@"BT Transimission Exception" reason:message userInfo:nil];
}

-(NSString*)identifier{
    if (_identifier == nil){
        NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
        _identifier = [NSString stringWithFormat:@"%.0f%d", interval, (NSInteger)self];
    }
    
    return _identifier;
}

+(NSString*)version{
    //version of protocol
    return @"1.0";
}

@end
