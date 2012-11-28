//
//  JJThumbnailCache.h
//  BreezyReader2
//
//  Created by  on 12-3-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JJThumbnailCache : NSObject

+(UIImage*)storeThumbnail:(UIImage*)thumb forURL:(NSURL*)url size:(CGSize)size;
+(UIImage*)storeThumbnail:(UIImage *)thumb forURL:(NSURL *)url size:(CGSize)size mode:(UIViewContentMode)mode;
+(NSString*)filePathForStoredThumbnailOfURL:(NSURL*)url;
+(NSString*)filePathForStoredThumbnailOfURL:(NSURL*)url andSize:(CGSize)size;
+(NSString*)filePathForStoredThumbnailOfURL:(NSURL*)url andSize:(CGSize)size mode:(UIViewContentMode)mode;
+(UIImage*)thumbnailForURL:(NSURL*)url;
+(UIImage*)thumbnailForURL:(NSURL *)url andSize:(CGSize)size;
+(UIImage*)thumbnailForURL:(NSURL *)url andSize:(CGSize)size mode:(UIViewContentMode)mode;

@end
