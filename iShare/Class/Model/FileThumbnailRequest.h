//
//  FileThumbnailRequest.h
//  iShare
//
//  Created by Jin Jin on 13-1-31.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FileThumbnailRequest;

@protocol FileThumbnailRequestDelegate <NSObject>

-(void)requestFinished:(FileThumbnailRequest*)request thumbnail:(UIImage*)thumbnail;

@end

@interface FileThumbnailRequest : NSOperation

@property (nonatomic, copy) NSString* filepath;

+(id)requestWithFilepath:(NSString*)filepath size:(CGSize)size delegate:(id<FileThumbnailRequestDelegate>)delegate;

-(void)startAsync;
-(void)removeDelegate;

@end
