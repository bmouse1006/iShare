//
//  JJAudioPlayerManager.m
//  iShare
//
//  Created by Jin Jin on 12-8-19.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJAudioPlayerManager.h"
#import "MDAudioFile.h"
#import <MediaPlayer/MediaPlayer.h>

#define PlayListStoreFolder @"PlayListStoreFolder"
#define DefaultPlayListStoreFile @"DefaultPlayListStoreFile"
#define OtherPlayListStoreFile @"OtherPlayListStoreFile"

@interface JJAudioPlayerManager(){
    NSArray* _currentPlayList;
}

@property (nonatomic, strong) AVAudioPlayer* currentPlayer;
@property (nonatomic, strong) NSMutableArray* defaultPlayList;

@end

@implementation JJAudioPlayerManager

+(void)initialize{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[UIApplication sharedApplication] canBecomeFirstResponder];
}

+(JJAudioPlayerManager*)sharedManager{
    static dispatch_once_t onceToken;
    static JJAudioPlayerManager* _sharedManager;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

+(AVAudioPlayer*)currentPlayer{
    return [self sharedManager].currentPlayer;
}

+(NSInteger)currentIndex{
    return [self sharedManager].currentIndex;
}

-(id)init{
    self = [super init];
    if (self){
        self.playerMode = JJAudioPlayerModeSequence;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        //restore play list
        [self restoreDefaultPlayList];
    }
    
    return self;
}

-(AVAudioPlayer*)playerWithContentOfURL:(NSURL*)URL error:(NSError**)error{
    
    AVAudioPlayer* player = self.currentPlayer;
    
    if ([[player.url absoluteString] isEqualToString:[URL absoluteString]]){
        return player;
    }
    
    [player stop];
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:error];
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setDelegate:self];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    
    self.currentPlayer = player;
    
    if (sessionError){
        NSLog(@"session error is %@", [sessionError localizedDescription]);
    }
    
    return player;
}

#pragma mark -

-(NSArray*)defaultList{
    return [NSArray arrayWithArray:self.defaultPlayList];
}

-(void)removeAudioFilFromPlayList:(MDAudioFile*)audioFile{
    __block NSInteger index = -1;
    
    if ([[self.currentPlayer.url absoluteString] isEqualToString:[audioFile.filePath absoluteString]]){
        [self.currentPlayer stop];
        self.currentPlayer = nil;
    }
    
    [self.defaultPlayList enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(MDAudioFile* audio, NSUInteger idx, BOOL* stop){
        if ([[audioFile.filePath absoluteString] isEqualToString:[audio.filePath absoluteString]]){
            index = idx;
            *stop = YES;
        }
    }];
    
    if (index >= 0){
        [self.defaultPlayList removeObjectAtIndex:index];
    }
}

-(void)addToDefaultPlayList:(MDAudioFile*)audioFile playNow:(BOOL)playNow{
    //search
    NSUInteger existsIndex = -1;
    BOOL exists = [self audioFile:audioFile existsInPlayList:self.defaultPlayList index:&existsIndex];
    
    if (exists == NO){
        existsIndex = [self.defaultPlayList count];
        [self.defaultPlayList addObject:audioFile];
    }
    
    if (playNow){
        _currentPlayList = self.defaultPlayList;
        AVAudioPlayer* player = [self playerForMusicAtIndex:existsIndex inPlayList:self.defaultPlayList];
        if ([player isPlaying] == NO){
            [player play];
        }
    }
}

-(AVAudioPlayer*)playerForMusicAtIndex:(NSInteger)index inPlayList:(NSArray*)playList{
    if (index < 0 || index >= [playList count]){
        return nil;
    }
    
    self.currentIndex = index;
    [self.currentPlayer stop];
    MDAudioFile* audioFile = [playList objectAtIndex:self.currentIndex];
    self.currentPlayer = [self playerWithContentOfURL:audioFile.filePath error:NULL];
    
    if (NSClassFromString(@"MPNowPlayingInfoCenter")) {
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:audioFile.title forKey:MPMediaItemPropertyTitle];
        [dict setObject:audioFile.artist forKey:MPMediaItemPropertyArtist];
        [dict setObject:audioFile.album forKey:MPMediaItemPropertyAlbumTitle];
        [dict setObject:audioFile.filePath forKey:MPMediaItemPropertyAssetURL];
        
        MPMediaItemArtwork * mArt = [[MPMediaItemArtwork alloc] initWithImage:audioFile.coverImage];
        [dict setObject:mArt forKey:MPMediaItemPropertyArtwork];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
    }
    
    return self.currentPlayer;
}

-(AVAudioPlayer*)playerForNextMusic{
    if (self.currentIndex+1 >= [self.currentPlayList count]){
        return nil;
    }
    
    NSUInteger newIndex = 0;
	
    if (self.playerMode & JJAudioPlayerModeShuffle){
        newIndex = rand() % [self.currentPlayList count];
    }else if (self.playerMode & JJAudioPlayerModeRepeatOne){
        newIndex = self.currentIndex;
    }else if (self.playerMode & JJAudioPlayerModeSequence){
        newIndex = (self.currentIndex + 1)>=[self.currentPlayList count]?self.currentIndex:self.currentIndex+1;
    }else if (self.playerMode & JJAudioPlayerModeSequenceLoop){
        newIndex = (self.currentIndex + 1)>=[self.currentPlayList count]?0:self.currentIndex+1;
    }
	
    return [self playerForMusicAtIndex:newIndex inPlayList:self.currentPlayList];
}

-(AVAudioPlayer*)playerForPreviousMusic{
    if (self.currentIndex-1 < 0){
        return nil;
    }
    
    NSUInteger newIndex = 0;
	
    if (self.playerMode & JJAudioPlayerModeShuffle){
        newIndex = rand() % [self.currentPlayList count];
    }else if (self.playerMode & JJAudioPlayerModeRepeatOne){
        newIndex = self.currentIndex;
    }else if (self.playerMode & JJAudioPlayerModeSequence){
        newIndex = (self.currentIndex - 1)<0?self.currentIndex:self.currentIndex-1;
    }else if (self.playerMode & JJAudioPlayerModeSequenceLoop){
        newIndex = (self.currentIndex - 1)<0?0:self.currentIndex-1;
    }
    
    return [self playerForMusicAtIndex:newIndex inPlayList:self.currentPlayList];
}

-(BOOL)canGoNextTrack{
    return !(self.currentIndex + 1 == [self.currentPlayList count]);
}

-(BOOL)canGoPreviouseTrack{
    return !(self.currentIndex == 0);
}

#pragma mark - notifications
-(void)willResignActive:(NSNotification*)notification{
    //will resign active
    [self storeDefaultPlayList];
}
//-(void)

#pragma mark - play list

-(BOOL)audioFile:(MDAudioFile*)audioFile existsInPlayList:(NSArray*)playList index:(NSUInteger*)index{
    __block BOOL exists = NO;
    __block NSUInteger existsIndex = -1;
    [playList enumerateObjectsUsingBlock:^(MDAudioFile* item, NSUInteger index, BOOL* stop){
        if ([[item.filePath absoluteString] isEqualToString:[audioFile.filePath absoluteString]]){
            exists = YES;
            existsIndex = index;
            *stop = YES;
        }
    }];

    *index = existsIndex;
    return exists;
}

-(NSArray*)currentPlayList{
    return _currentPlayList;
}

-(void)restoreDefaultPlayList{
    self.defaultPlayList = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:[self defaultPlayListFilePath]]];
    if (self.defaultPlayList == nil){
        self.defaultPlayList = [NSMutableArray array];
    }

}

-(void)storeDefaultPlayList{
    
    BOOL result = [NSKeyedArchiver archiveRootObject:self.defaultPlayList toFile:[self defaultPlayListFilePath]];

    if (result == NO){
        NSLog(@"default play list store failed");
    }
}

-(NSString*)defaultPlayListFilePath{
    NSString* folder = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:PlayListStoreFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:folder] == NO){
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:NULL];
    }
    
    return [folder stringByAppendingPathComponent:DefaultPlayListStoreFile];
}

@end
