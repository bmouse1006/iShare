//
//  JJThumbnailCache.m
//  BreezyReader2
//
//  Created by  on 12-3-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "JJThumbnailCache.h"
#import "NSString+MD5.h"

@interface JJThumbnailCache(){
    NSMutableDictionary* _imgCache;
}

+(id)sharedCache;

-(NSString*)cachePath;
-(UIImage*)clippedThumbnailImage:(UIImage*)thumb size:(CGSize)size;
-(UIImage*)cachedImageInMemoryForURL:(NSURL*)url;
-(UIImage*)cachedImageInMemoryForURL:(NSURL*)url andSize:(CGSize)size;
-(void)saveImage:(UIImage*)image toMemoryCacheForURL:(NSURL*)url;
-(void)saveImage:(UIImage*)image toMemoryCacheForURL:(NSURL*)url andSize:(CGSize)size;

@end

@implementation JJThumbnailCache

static JJThumbnailCache* _cache = nil;
static NSString* _cachePath = nil;

-(id)init{
    self = [super init];
    if (self){
        _imgCache = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMemroyWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)receivedMemroyWarning:(NSNotification*)notification{
    [_imgCache removeAllObjects];
}

-(NSString*)cachePath{
    if (_cachePath == nil){
        _cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailClipCache"];
        NSFileManager* fm = [NSFileManager defaultManager];
        BOOL isDictionary = NO;
        if ([fm fileExistsAtPath:_cachePath isDirectory:&isDictionary] == NO){
            [fm createDirectoryAtPath:_cachePath withIntermediateDirectories:NO attributes:nil error:NULL];
        }
    }
    
    return _cachePath;
}

+(UIImage*)storeThumbnail:(UIImage *)thumb forURL:(NSURL *)url size:(CGSize)size{
    return [self storeThumbnail:thumb forURL:url size:size mode:UIViewContentModeScaleAspectFill];
}

+(UIImage*)storeThumbnail:(UIImage *)thumb forURL:(NSURL *)url size:(CGSize)size mode:(UIViewContentMode)mode{
    NSString* filePath = [self filePathForStoredThumbnailOfURL:url andSize:size mode:mode];
    UIImage* nail = [[self sharedCache] clippedThumbnailImage:thumb size:size mode:mode];
    [UIImageJPEGRepresentation(nail, 0.6) writeToFile:filePath atomically:YES];
    [[self sharedCache] saveImage:nail toMemoryCacheForURL:url andSize:size mode:mode];
    return nail;
}

+(NSString*)filePathForStoredThumbnailOfURL:(NSURL*)url{
    NSString* filename = [[[url absoluteString] md5] stringByAppendingPathExtension:@"jpg"];
    return [[[self sharedCache] cachePath] stringByAppendingPathComponent:filename];
}

+(NSString*)filePathForStoredThumbnailOfURL:(NSURL*)url andSize:(CGSize)size{
    return [self filePathForStoredThumbnailOfURL:url andSize:size mode:UIViewContentModeScaleAspectFill];
}

+(NSString*)filePathForStoredThumbnailOfURL:(NSURL*)url andSize:(CGSize)size mode:(UIViewContentMode)mode{
    NSString* rawString = [NSString stringWithFormat:@"%@%@%d", [url absoluteString], NSStringFromCGSize(size), mode];
    NSString* filename = [[rawString md5] stringByAppendingPathExtension:@"jpg"];
    return [[[self sharedCache] cachePath] stringByAppendingPathComponent:filename];
}

+(UIImage*)thumbnailForURL:(NSURL*)url{
    UIImage* image = [[self sharedCache] cachedImageInMemoryForURL:url];
    if (image == nil){
        image = [UIImage imageWithContentsOfFile:[self filePathForStoredThumbnailOfURL:url]];
        [[self sharedCache] saveImage:image toMemoryCacheForURL:url];
    }
    return image;
}

+(UIImage*)thumbnailForURL:(NSURL *)url andSize:(CGSize)size{
    return [self thumbnailForURL:url andSize:size mode:UIViewContentModeScaleAspectFill];
}

+(UIImage*)thumbnailForURL:(NSURL *)url andSize:(CGSize)size mode:(UIViewContentMode)mode{
    UIImage* image = [[self sharedCache] cachedImageInMemoryForURL:url andSize:size mode:mode];
    if (image == nil){
        //        DebugLog(@"image: %@", [self filePathForStoredThumbnailOfURL:url andSize:size]);
        image = [UIImage imageWithContentsOfFile:[self filePathForStoredThumbnailOfURL:url andSize:size mode:mode]];
        [[self sharedCache] saveImage:image toMemoryCacheForURL:url andSize:size mode:mode];
    }
    return image;
}

+(id)sharedCache{
    if (_cache == nil){
        _cache = [[JJThumbnailCache alloc] init];
    }
    
    return _cache;
}

-(UIImage*)cachedImageInMemoryForURL:(NSURL*)url{
    return [_imgCache objectForKey:[[self class] filePathForStoredThumbnailOfURL:url]];
}

-(UIImage*)cachedImageInMemoryForURL:(NSURL*)url andSize:(CGSize)size{
    return [self cachedImageInMemoryForURL:url andSize:size mode:UIViewContentModeScaleAspectFill];
}

-(UIImage*)cachedImageInMemoryForURL:(NSURL*)url andSize:(CGSize)size mode:(UIViewContentMode)mode{
    return [_imgCache objectForKey:[[self class] filePathForStoredThumbnailOfURL:url andSize:size mode:mode]];
}

-(void)saveImage:(UIImage*)image toMemoryCacheForURL:(NSURL*)url{
    if (image != nil){
        [_imgCache setObject:image forKey:[[self class] filePathForStoredThumbnailOfURL:url]];
    }
}

-(void)saveImage:(UIImage*)image toMemoryCacheForURL:(NSURL*)url andSize:(CGSize)size{
    return [self saveImage:image toMemoryCacheForURL:url andSize:size mode:UIViewContentModeScaleAspectFill];
}

-(void)saveImage:(UIImage*)image toMemoryCacheForURL:(NSURL*)url andSize:(CGSize)size mode:(UIViewContentMode)mode{
    if (image != nil){
        [_imgCache setObject:image
                      forKey:[[self class] filePathForStoredThumbnailOfURL:url andSize:size mode:mode]];
    }
}

-(UIImage*)clippedThumbnailImage:(UIImage*)thumb size:(CGSize)size{
    return [self clippedThumbnailImage:thumb size:size mode:UIViewContentModeScaleAspectFill];
}

-(UIImage*)clippedThumbnailImage:(UIImage*)thumb size:(CGSize)size mode:(UIViewContentMode)mode{
    CGSize clipSize = CGSizeMake(size.width*[UIScreen mainScreen].scale, size.height*[UIScreen mainScreen].scale);
    CGSize imageSize = thumb.size; 
    
    CGFloat scale = clipSize.width/imageSize.width;
    if (scale < clipSize.height/imageSize.height){
        scale = clipSize.height/imageSize.height;
    }
    
    CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    imageRect = CGRectApplyAffineTransform(imageRect, CGAffineTransformMakeScale(scale, scale));
    
    UIGraphicsBeginImageContext(imageRect.size);
    
    [thumb drawInRect:imageRect];
    
    UIImage* tmpImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGRect clipRect = CGRectZero;
    
    if (mode == UIViewContentModeScaleAspectFit){
        clipRect = imageRect;
    }else{
        clipRect = CGRectMake((imageRect.size.width-clipSize.width)/2, (imageRect.size.height-clipSize.height)/2, clipSize.width, clipSize.height);
    }
    
    CGImageRef cgImage = CGImageCreateWithImageInRect(tmpImage.CGImage, clipRect);
    UIImage* clipedImage = [UIImage imageWithCGImage:cgImage];
    if (cgImage){
        CFRelease(cgImage);
    }
    
    return clipedImage;
}

@end
