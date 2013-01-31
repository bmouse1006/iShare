//
//  FileThumbnailRequest.m
//  iShare
//
//  Created by Jin Jin on 13-1-31.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import "FileThumbnailRequest.h"
#import "JJThumbnailCache.h"
#import "FileOperationWrap.h"
#import "ISUserPreferenceDefine.h"
#import "JJMoviePlayerController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface FileThumbnailRequest()

@property (nonatomic, weak) id<FileThumbnailRequestDelegate> delegate;
@property (nonatomic, assign) CGSize size;

@end

@implementation FileThumbnailRequest

+(id)requestWithFilepath:(NSString*)filepath size:(CGSize)size delegate:(id<FileThumbnailRequestDelegate>)delegate{
    FileThumbnailRequest* request = [[FileThumbnailRequest alloc] init];
    request.filepath = filepath;
    request.delegate = delegate;
    request.size = size;
    
    return request;
}

-(NSOperationQueue*)queue{
    static NSOperationQueue* queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}

-(void)startAsync{
    [[self queue] addOperation:self];
}

-(void)removeDelegate{
    self.delegate = nil;
}

-(void)main{
    FileContentType type = [[FileOperationWrap sharedWrap] fileTypeWithFilePath:self.filepath];

    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(self.size.width*scale, self.size.height*scale);
    NSURL* url = [NSURL fileURLWithPath:self.filepath];
    
    BOOL previewEnabled = [ISUserPreferenceDefine enableThumbnail];
    UIViewContentMode contentMode = UIViewContentModeScaleAspectFit;
    
    UIImage* image = [JJThumbnailCache thumbnailForURL:url andSize:size mode:contentMode];
    
    if (type == FileContentTypeImage && previewEnabled){
        if (image == nil){
            image = [JJThumbnailCache storeThumbnail:[UIImage imageWithContentsOfFile:self.filepath] forURL:url size:size mode:contentMode];
        }
    }else if (type == FileContentTypeMovie && previewEnabled){
        if (image == nil){
            JJMoviePlayerSnapshotRequest* request = [JJMoviePlayerSnapshotRequest requestWithFilepath:self.filepath delegate:nil];
            image = [request startSync];
            image = [JJThumbnailCache storeThumbnail:image forURL:url size:size mode:contentMode];
        }
    }else if (type == FileContentTypeAppleMovie && previewEnabled){
        if (image == nil){
            NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                             forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:opts];
            AVAssetImageGenerator* imageCapture = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
            imageCapture.appliesPreferredTrackTransform = YES;
            NSError* error = nil;
            CGImageRef cgImage = [imageCapture copyCGImageAtTime:CMTimeMakeWithSeconds(5,30) actualTime:NULL error:&error];
            UIImage* tempImage = [UIImage imageWithCGImage:cgImage];
            image = [JJThumbnailCache storeThumbnail:tempImage forURL:url size:size mode:contentMode];
        }
    }else{
        image = [UIImage imageNamed:[self thumbnailNameForFile:self.filepath]];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestFinished:thumbnail:)]){
        [self.delegate requestFinished:self thumbnail:image];
    }
}

-(NSString*)thumbnailNameForFile:(NSString*)filePath{
    NSString* namePreview = @"fileicon_";
    NSString* thumbnail = nil;
    
    FileContentType type = [[FileOperationWrap sharedWrap] fileTypeWithFilePath:filePath];
    NSString* ext = [[filePath pathExtension] lowercaseString];
    if (type == FileContentTypeDirectory){
        thumbnail = @"fileicon_folder";
    }else{
        thumbnail = [namePreview stringByAppendingString:ext];
        NSString* thumbpath = [[NSBundle mainBundle] pathForResource:thumbnail ofType:@"png"];
        if (thumbpath == nil){
            switch (type) {
                case FileContentType7Zip:
                case FileContentTypeRAR:
                case FileContentTypeZip:
                    thumbnail = @"fileicon_compressed";
                    break;
                case FileContentTypeImage:
                    thumbnail = @"fileicon_image";
                    break;
                case FileContentTypeAppleMovie:
                case FileContentTypeMovie:
                    thumbnail = @"fileicon_movie";
                    break;
                case FileContentTypeMusic:
                    thumbnail = @"fileicon_music";
                    break;
                case FileContentTypeText:
                    thumbnail = @"fileicon_txt";
                    break;
                default:
                    thumbnail = @"fileicon_bg";
                    break;
            }
        }
    }
    
    return thumbnail;
}

@end
