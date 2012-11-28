//
//  JJAudioPlayerManager.h
//  iShare
//
//  Created by Jin Jin on 12-8-19.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "MDAudioFile.h"

typedef enum {
    JJAudioPlayerModeSequence = 1,
    JJAudioPlayerModeSequenceLoop = 2,
    JJAudioPlayerModeShuffle = 4,
    JJAudioPlayerModeRepeatOne = 8
}JJAudioPlayerMode;

@interface JJAudioPlayerManager : NSObject<AVAudioSessionDelegate>

@property (nonatomic, readonly) NSArray* currentPlayList;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) JJAudioPlayerMode playerMode;

+(JJAudioPlayerManager*)sharedManager;

-(NSArray*)defaultList;
-(void)addToDefaultPlayList:(MDAudioFile*)audioFile playNow:(BOOL)playNow;
-(void)removeAudioFilFromPlayList:(MDAudioFile*)audioFile;
-(AVAudioPlayer*)currentPlayer;
-(AVAudioPlayer*)playerForMusicAtIndex:(NSInteger)index inPlayList:(NSArray*)playList;
-(AVAudioPlayer*)playerForNextMusic;
-(AVAudioPlayer*)playerForPreviousMusic;
-(BOOL)canGoNextTrack;
-(BOOL)canGoPreviouseTrack;

@end
