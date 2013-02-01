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

-(void)startAccordingly{
    
    if ([ISUserPreferenceDefine enableThumbnail] == NO){//如果用户不需要显示缩略图，显示图标
        UIImage* image = [UIImage imageNamed:[self thumbnailNameForFile:self.filepath]];
        [self notifyDelegate:image];
    }else if( [self couldHasPreview:self.filepath] == NO){//如果当前文件无法显示缩略图，则只显示图标
        UIImage* image = [UIImage imageNamed:[self thumbnailNameForFile:self.filepath]];
        [self notifyDelegate:image];
    }else{//可以显示缩略图
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize size = CGSizeMake(self.size.width*scale, self.size.height*scale);
        NSURL* url = [NSURL fileURLWithPath:self.filepath];
        
        UIViewContentMode contentMode = UIViewContentModeScaleAspectFit;
        
        //获取缓存的缩略图
        UIImage* image = [JJThumbnailCache thumbnailForURL:url andSize:size mode:contentMode];
        
        if (image){//已缓存
            [self notifyDelegate:image];
        }else{//未缓存
            [[self queue] addOperation:self];
        }

    }
}

-(void)removeDelegate{
    self.delegate = nil;
}

-(void)main{
    @autoreleasepool {
        FileContentType type = [[FileOperationWrap sharedWrap] fileTypeWithFilePath:self.filepath];
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize size = CGSizeMake(self.size.width*scale, self.size.height*scale);
        NSURL* url = [NSURL fileURLWithPath:self.filepath];
        
        BOOL previewEnabled = [ISUserPreferenceDefine enableThumbnail];
        UIViewContentMode contentMode = UIViewContentModeScaleAspectFit;
        
        UIImage* image = nil;
        
        if (type == FileContentTypeImage && previewEnabled){
            image = [JJThumbnailCache storeThumbnail:[UIImage imageWithContentsOfFile:self.filepath] forURL:url size:size mode:contentMode];
        }else if (type == FileContentTypeMovie && previewEnabled){
            
            image = [JJMoviePlayerController snapshotWithFilepath:self.filepath time:1.0];
            image = [JJThumbnailCache storeThumbnail:image forURL:url size:size mode:contentMode];
            
        }else if (type == FileContentTypeAppleMovie && previewEnabled){
            NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                             forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:opts];
            AVAssetImageGenerator* imageCapture = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
            imageCapture.appliesPreferredTrackTransform = YES;
            NSError* error = nil;
            CGImageRef cgImage = [imageCapture copyCGImageAtTime:CMTimeMakeWithSeconds(5,30) actualTime:NULL error:&error];
            UIImage* tempImage = [UIImage imageWithCGImage:cgImage];
            image = [JJThumbnailCache storeThumbnail:tempImage forURL:url size:size mode:contentMode];
        }else{
            image = [UIImage imageNamed:[self thumbnailNameForFile:self.filepath]];
            image = [JJThumbnailCache storeThumbnail:image forURL:url size:size mode:contentMode];
        }
        
        [self notifyDelegate:image];
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

-(void)notifyDelegate:(UIImage*)image{
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestFinished:thumbnail:)]){
        BOOL isMain = [NSThread isMainThread];
        
        if (isMain){
            [self.delegate requestFinished:self thumbnail:image];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate requestFinished:self thumbnail:image];
            });
        }
    }
}

-(BOOL)couldHasPreview:(NSString*)filepath{
    FileContentType type = [[FileOperationWrap sharedWrap] fileTypeWithFilePath:filepath];
    
    return type == FileContentTypeAppleMovie || type == FileContentTypeMovie || type == FileContentTypeImage;
}

@end
