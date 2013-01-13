//
//  JJMovieAudioPlayer.h
//  iShare
//
//  Created by Jin Jin on 13-1-12.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>

@interface JJMovieAudioPlayer : NSObject

-(void)moreData:(const ALvoid*)buffer
         length:(ALsizei)length
      frequency:(ALsizei)freq
         format:(int)format;

#pragma mark - play back control
-(void)play;
-(void)pause;
-(void)stop;
-(void)resume;

@end
