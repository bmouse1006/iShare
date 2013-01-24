//
//  JJMoviePlayerController.h
//  iShare
//
//  Created by Jin Jin on 12-12-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    JJMoviePlaybackStatusInitial,
    JJMoviePlaybackStatusStop,
    JJMoviePlaybackStatusPlay,
    JJMoviePlaybackStatusPause
} JJMoviePlaybackStatus;

@class JJMoviePlayerController;

@protocol JJMoviePlayerControllerDelegate <NSObject>

@optional
-(void)moviePlayerWillStart:(JJMoviePlayerController*)player;
-(void)moviePlayerDidStart:(JJMoviePlayerController*)player;
-(void)moviePlayerWillStop:(JJMoviePlayerController*)player;
-(void)moviePlayerDidStop:(JJMoviePlayerController*)player;
-(void)moviePlayerWillPause:(JJMoviePlayerController*)player;
-(void)moviePlayerDidPause:(JJMoviePlayerController*)player;

@end

@interface JJMoviePlayerController : NSObject

@property (nonatomic, readonly) CGSize natrualSize;
@property (nonatomic, readonly) NSTimeInterval playableDuration;
@property (nonatomic, readonly) NSTimeInterval playedDuration;
@property (nonatomic, readonly) JJMoviePlaybackStatus status;
@property (nonatomic, assign) NSTimeInterval playbackTime;

@property (nonatomic, readonly) UIWindow* window;
@property (nonatomic, readonly) UIView* view;
@property (nonatomic, readonly) UIView* backgroundView;

@property (nonatomic, weak) id<JJMoviePlayerControllerDelegate> delegate;

/**
 get a snapshot synchnizly
 @param file url, time, completion block
 @return nil
 @exception nil
 */
+(void)requestSnapshotOfMovie:(NSString*)filePath
                       atTime:(NSTimeInterval)time
              completionBlock:(void(^)(UIImage*))block;

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
-(void)seekTime:(double)seconds;

-(BOOL)prepareToPlay;
-(void)cleanUpPlay;
//playback control
-(void)play;
-(void)stop;
-(void)pause;
//clean all queues and buffers
-(void)purge;

@end
