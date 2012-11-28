//
//  AudioFile.m
//  MobileTheatre
//
//  Created by Matt Donnelly on 28/06/2010.
//  Copyright 2010 Matt Donnelly. All rights reserved.
//

#import "MDAudioFile.h"
#import "JJThumbnailCache.h"

@interface MDAudioFile ()

@end

@implementation MDAudioFile

- (MDAudioFile *)initWithPath:(NSURL *)path
{
	if (self = [super init]) 
	{
		self.filePath = path;
        [self setupMusicInfoWithPath:self.filePath];
	}
	
	return self;
}

-(void)setupMusicInfoWithPath:(NSURL*)filePath{
    self.fileInfoDict = [self songID3TagsWithFilePathURL:filePath];
    self.asset = [AVURLAsset assetWithURL:filePath];
}

- (NSDictionary *)songID3TagsWithFilePathURL:(NSURL*)filePathURL
{
	AudioFileID fileID = nil;
	OSStatus error = noErr;
	
	error = AudioFileOpenURL((__bridge CFURLRef)filePathURL, kAudioFileReadPermission, 0, &fileID);
	if (error != noErr) {
        NSLog(@"AudioFileOpenURL failed");
    }
	
	UInt32 id3DataSize  = 0;
    char *rawID3Tag    = NULL;
	
    error = AudioFileGetPropertyInfo(fileID, kAudioFilePropertyID3Tag, &id3DataSize, NULL);
    if (error != noErr)
        NSLog(@"AudioFileGetPropertyInfo failed for ID3 tag");
	
    rawID3Tag = (char *)malloc(id3DataSize);
    if (rawID3Tag == NULL)
        NSLog(@"could not allocate %ld bytes of memory for ID3 tag", id3DataSize);
    
    error = AudioFileGetProperty(fileID, kAudioFilePropertyID3Tag, &id3DataSize, rawID3Tag);
    if( error != noErr )
        NSLog(@"AudioFileGetPropertyID3Tag failed");
	
	UInt32 id3TagSize = 0;
    UInt32 id3TagSizeLength = 0;
	
	error = AudioFormatGetProperty(kAudioFormatProperty_ID3TagSize, id3DataSize, rawID3Tag, &id3TagSizeLength, &id3TagSize);
	
    if (error != noErr) {
        NSLog( @"AudioFormatGetProperty_ID3TagSize failed" );
        switch(error) {
            case kAudioFormatUnspecifiedError:
                NSLog( @"Error: audio format unspecified error" ); 
                break;
            case kAudioFormatUnsupportedPropertyError:
                NSLog( @"Error: audio format unsupported property error" ); 
                break;
            case kAudioFormatBadPropertySizeError:
                NSLog( @"Error: audio format bad property size error" ); 
                break;
            case kAudioFormatBadSpecifierSizeError:
                NSLog( @"Error: audio format bad specifier size error" ); 
                break;
            case kAudioFormatUnsupportedDataFormatError:
                NSLog( @"Error: audio format unsupported data format error" ); 
                break;
            case kAudioFormatUnknownFormatError:
                NSLog( @"Error: audio format unknown format error" ); 
                break;
            default:
                NSLog( @"Error: unknown audio format error" ); 
                break;
        }
    }	
	
	CFDictionaryRef piDict = nil;
    UInt32 piDataSize = sizeof(piDict);
	
    error = AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary, &piDataSize, &piDict);
    if (error != noErr)
        NSLog(@"AudioFileGetProperty failed for property info dictionary");
	
	free(rawID3Tag);
	
	return (__bridge NSDictionary*)piDict;
}

- (NSString *)title
{
	if ([self.fileInfoDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Title]]) {
		return [self.fileInfoDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Title]];
	}
	
	else {
		NSString *url = [self.filePath absoluteString];
		NSArray *parts = [url componentsSeparatedByString:@"/"];
		return [parts objectAtIndex:[parts count]-1];
	}
	
	return nil;
}

- (NSString *)artist
{
	if ([self.fileInfoDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Artist]])
		return [self.fileInfoDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Artist]];
	else
		return @"";
}

- (NSString *)album
{
	if ([self.fileInfoDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Album]])
		return [self.fileInfoDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Album]];
	else
		return @"";
}

- (float)duration
{
	if ([self.fileInfoDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_ApproximateDurationInSeconds]])
		return [[self.fileInfoDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_ApproximateDurationInSeconds]] floatValue];
	else
		return 0;
}

- (NSString *)durationInMinutes
{	
	return [NSString stringWithFormat:@"%d:%02d", (int)[self duration] / 60, (int)[self duration] % 60, nil];
}

- (UIImage *)coverImage
{
    UIImage* artwork = nil;
    for (NSString* format in [self.asset availableMetadataFormats]){
        for (AVMetadataItem* metaData in [self.asset metadataForFormat:format]){
            if ([metaData.commonKey isEqualToString:@"artwork"]){
                artwork = [JJThumbnailCache thumbnailForURL:[self.asset URL] andSize:CGSizeMake(100, 100)];
                if (artwork == nil){
                    artwork = [UIImage imageWithData:[(NSDictionary*)metaData.value objectForKey:@"data"]];
                    [JJThumbnailCache storeThumbnail:artwork forURL:[self.asset URL] size:CGSizeMake(100, 100)];
                }
            }
        }
    }
	return (artwork)?artwork:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AudioPlayerNoArtwork" ofType:@"png"]];
}


#pragma mark - encoding and decoding
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.filePath forKey:@"filePath"];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self){
        self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
        [self setupMusicInfoWithPath:self.filePath];
    }
    
    return self;
}

@end
