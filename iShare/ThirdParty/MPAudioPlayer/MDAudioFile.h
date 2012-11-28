//
//  AudioFile.h
//  MobileTheatre
//
//  Created by Matt Donnelly on 28/06/2010.
//  Copyright 2010 Matt Donnelly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface MDAudioFile : NSObject <NSCoding>

@property (nonatomic, strong) NSURL *filePath;
@property (nonatomic, strong) NSDictionary *fileInfoDict;
@property (nonatomic, retain) AVURLAsset* asset;

- (MDAudioFile *)initWithPath:(NSURL *)path;
- (NSString *)title;
- (NSString *)artist;
- (NSString *)album;
- (float)duration;
- (NSString *)durationInMinutes;
- (UIImage *)coverImage;

@end
