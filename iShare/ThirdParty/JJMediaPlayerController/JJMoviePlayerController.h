//
//  JJMoviePlayerController.h
//  iShare
//
//  Created by Jin Jin on 12-12-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    JJMoviePlaybackStatePlay,
    JJMoviePlaybackStatePause,
    JJMoviePlaybackStateStop
} JJMoviePlaybackState;

@interface JJMoviePlayerController : NSObject

@property (nonatomic, readonly) CGSize natrualSize;
@property (nonatomic, readonly) NSTimeInterval playableDuration;
@property (nonatomic, readonly) JJMoviePlaybackState playbackState;
@property (nonatomic, assign) NSTimeInterval initialPlaybackTime;

@property (nonatomic, readonly) UIWindow* window;
@property (nonatomic, readonly) UIView* view;
@property (nonatomic, readonly) UIView* backgroundView;

/**
 init of JJMoviePlayerController with file path
 @param filePath
 @return id
 @exception nil
 */
-(id)initWithFilepath:(NSString*)filePath;

/**
 init of JJMoviePlayerController with input stream
 @param input stream
 @return id
 @exception nil
 */
-(id)initWithInputStream:(NSInputStream*)inputStream;

-(void)prepareToPlay;
-(void)cleanUpPlay;
//playback control
-(void)play;
-(void)stop;
-(void)pause;

@end
