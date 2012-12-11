//
//  AudioPlay.h
//  iShare
//
//  Created by Jin Jin on 12-12-6.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#include "libavformat/avformat.h"

@interface AudioPlay : NSObject{
    ALCcontext *mContext;
    ALCdevice *mDevice;
    
    ALuint outSourceID;
}


@property (nonatomic) ALCcontext *mContext;
@property (nonatomic) ALCdevice *mDevice;

- (void)openAudioFromQueue:(unsigned char*)data dataSize:(UInt32)dataSize rate:(int)rate;
-(void)enqueueAudioPacket:(AVFrame*)audioFrame;

-(void)openAL;

-(void)playSound;
-(void)stopSound;
-(void)cleanUpOpenALID;
-(void)cleanUpOpenAL;

@end
