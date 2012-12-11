//
//  AudioPlay.m
//  iShare
//
//  Created by Jin Jin on 12-12-6.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "AudioPlay.h"

@interface AudioPlay()

@end

@implementation AudioPlay

@synthesize mDevice, mContext;

-(void)openAL
{
    mDevice=alcOpenDevice(NULL);
    if (mDevice) {
        mContext=alcCreateContext(mDevice, NULL);
        alcMakeContextCurrent(mContext);
    }
    
    alGenSources(1, &outSourceID);
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    alSourcef(outSourceID, AL_PITCH, 1.0f);
    alSourcef(outSourceID, AL_GAIN, 1.0f);
    alSourcei(outSourceID, AL_LOOPING, AL_FALSE);
    alSourcef(outSourceID, AL_SOURCE_TYPE, AL_STREAMING);
    
    [NSTimer scheduledTimerWithTimeInterval: 1/1000.0
                                     target:self
                                   selector:@selector(updateQueueBuffer)
                                   userInfo: nil
                                    repeats:YES];
}

-(void)dealloc{
    [self cleanUpOpenALID];
    [self cleanUpOpenAL];
}

- (void) openAudioFromQueue:(unsigned char*)data dataSize:(UInt32)dataSize rate:(int)rate
{
    @autoreleasepool {
        NSCondition* ticketCondition= [[NSCondition alloc] init];
        [ticketCondition lock];
        
        ALuint bufferID = 0;
        alGenBuffers(1, &bufferID);
        
        alBufferData(bufferID, AL_FORMAT_STEREO16, data, dataSize, rate);
        alSourceQueueBuffers(outSourceID, 1, &bufferID);
        
        [self updateQueueBuffer];
        
        ALint stateVaue;
        alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue);
        
        [ticketCondition unlock];
    }
}

-(void)enqueueAudioPacket:(AVFrame*)audioFrame{
    @autoreleasepool {
        
        NSCondition* ticketCondition= [[NSCondition alloc] init];
        [ticketCondition lock];
        
        ALuint bufferID = 0;
        alGenBuffers(1, &bufferID);
        
        alBufferData(bufferID, AL_FORMAT_MONO16, audioFrame->data[0], audioFrame->linesize[0], audioFrame->sample_rate);
        alSourceQueueBuffers(outSourceID, 1, &bufferID);
        
        [self updateQueueBuffer];
        
        ALint stateVaue;
        alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue);
        
        [ticketCondition unlock];
    }
}


- (BOOL) updateQueueBuffer
{
    ALint stateVaue;
    int processed, queued;
    
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue);
    
    if (stateVaue != AL_PLAYING)
    {
        alSourcePlay(outSourceID);
//        return NO;
    }
    
    alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(outSourceID, AL_BUFFERS_QUEUED, &queued);
    
    NSLog(@"Processed = %d\n", processed);
    NSLog(@"Queued = %d\n", queued);
    
    while(processed--)
    {
        ALuint buff;
        alSourceUnqueueBuffers(outSourceID, 1, &buff);
        alDeleteBuffers(1, &buff);
    }
    
    return YES;
}

-(void)playSound{
    alSourcePlay(outSourceID);
}

-(void)stopSound{
    alSourceStop(outSourceID);
}

-(void)cleanUpOpenALID{
    [self stopSound];
    alDeleteSources(1, &outSourceID);
}

-(void)cleanUpOpenAL{
    alcCloseDevice(mDevice);
}

@end
