//
//  JJMovieAudioPlayer.m
//  iShare
//
//  Created by Jin Jin on 13-1-12.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import "JJMovieAudioPlayer.h"
#import <OpenAL/alc.h>

@interface JJMovieAudioPlayer (){
}

@property (nonatomic, strong) NSCondition* condition;

@end

@implementation JJMovieAudioPlayer{
    ALCcontext* _mContext;
    ALCdevice* _mDevice;
    
    ALuint _outSourceID;
}

-(void)dealloc{
    [self tearDownAL];
}

-(id)init{
    self = [super init];
    
    if (self){
        [self setupAL];
        self.condition = [[NSCondition alloc] init];
    }
    
    return self;
}



-(void)setupAL{
    //获取device
    _mDevice=alcOpenDevice(NULL);
    if (_mDevice) {
        //将context关联到device
        _mContext=alcCreateContext(_mDevice, NULL);
        alcMakeContextCurrent(_mContext);
    }

    //生成一个source
    alGenSources(1, &_outSourceID);
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    alSourcef(_outSourceID, AL_PITCH, 1.0f);
    alSourcef(_outSourceID, AL_GAIN, Volume);
    alSourcei(_outSourceID, AL_LOOPING, AL_FALSE);
    alSourcei(_outSourceID, AL_SOURCE_TYPE, AL_STREAMING);
}

-(void)tearDownAL{
    // Delete the Buffers
    [self clearBuffers];
    // Delete the Sources
    alDeleteSources(1, &_outSourceID);
    //Release context
    alcDestroyContext(_mContext);
    //Close device
    alcCloseDevice(_mDevice);
}

/**
 comes with more audio data
 @param buffer: pointer of buffer, length: length of buffer
 @return nil
 @exception nil
 */
-(void)moreData:(const ALvoid*)buffer length:(ALsizei)length frequency:(ALsizei)freq format:(int)format{
    @autoreleasepool {

        ALuint bufferID;
        //生成buffer
        alGenBuffers(1, &bufferID);
        //添加数据
        alBufferData(bufferID, format, buffer, length, freq);
        //将buffer链接到一个source
        alSourceQueueBuffers(_outSourceID, 1, &bufferID);
        
        [self play];
        
        [self updatePlayBuffers];
    }
}

-(void)updatePlayBuffers{

    [self.condition lock];
    
    int processed, queued;
    
    alGetSourcei(_outSourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(_outSourceID, AL_BUFFERS_QUEUED, &queued);
    
    while(processed--)
    {
        ALuint buff;
        alSourceUnqueueBuffers(_outSourceID, 1, &buff);
        alDeleteBuffers(1, &buff);
    }
    
    [self.condition unlock];
}

#pragma mark - setter and getter
static CGFloat Volume = 1.0f;

-(CGFloat)currentVolume{
    return Volume;
}

-(void)setVolume:(CGFloat)volume{
    Volume = volume;
    alSourcef(_outSourceID, AL_GAIN, volume);
}

#pragma mark - get duration in buffer
-(int)numberOfQueuedBuffer{
    [self.condition lock];
    
    int processed, queued;
    
    alGetSourcei(_outSourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(_outSourceID, AL_BUFFERS_QUEUED, &queued);
    
    [self.condition unlock];
    
    return queued - processed;
}

#pragma mark - play back control
-(void)play{
    ALint stateVaue;
    alGetSourcei(_outSourceID, AL_SOURCE_STATE, &stateVaue);
    if (stateVaue != AL_PLAYING)
    {
        alSourcePlay(_outSourceID);
        
        ALenum error;
        
        if((error = alGetError()) != AL_NO_ERROR) {
            NSLog(@"error starting source: %x\n", error);
        }
    }
}

-(void)pause{
    alSourcePause(_outSourceID);
}

-(void)stop{
    alSourceStop(_outSourceID);
}

-(void)clearBuffers{
    
    [self.condition lock];
    
    int queued;
    alGetSourcei(_outSourceID, AL_BUFFERS_QUEUED, &queued);
    
    while(queued--)
    {
        ALuint buff;
        alSourceUnqueueBuffers(_outSourceID, 1, &buff);
        alDeleteBuffers(1, &buff);
    }
    
    [self.condition unlock];
}

@end
