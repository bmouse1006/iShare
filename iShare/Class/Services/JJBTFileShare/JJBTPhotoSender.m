//
//  JJBTPhotoSender.m
//  iShare
//
//  Created by Jin Jin on 12-10-13.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJBTPhotoSender.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface JJBTPhotoSender(){
    long long _size;
}

@end

@implementation JJBTPhotoSender

-(id)init{
    self = [super init];
    if (self){
        _size = -1;
    }
    
    return self;
}

-(long long)sizeOfObject{
    if (_size < 0){
        ALAsset* asset = self.sendingObj;
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        _size = [rep size];
    }

    return _size;
}

-(NSInputStream*)readStream{
    
    static const NSInteger BufferSize = 1024*1024;
    
    ALAsset* asset = self.sendingObj;
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    
    long long totalSize = [rep size];
    long long offset = 0;
    NSMutableData* imageData = [NSMutableData data];
    uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
    
    while (offset < totalSize) {
        NSUInteger read = [rep getBytes:buffer fromOffset:offset length:BufferSize error:NULL];
        [imageData appendBytes:buffer length:read];
        offset += read;
    }
    
    free(buffer);
    
    return [NSInputStream inputStreamWithData:imageData];
}

-(BTSenderType)type{
    return BTSenderTypePhoto;
}

-(NSString*)name{
    ALAsset* asset = self.sendingObj;
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    
    return [rep filename];
}

@end
