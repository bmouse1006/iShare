//
//  JJYUVDisplayView.h
//  iShare
//
//  Created by Jin Jin on 13-1-5.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import <GLKit/GLKit.h>

typedef unsigned char BYTE;

typedef struct _YUVVideoPicture
{
    BYTE* data[4];      // [4] = alpha channel, currently not used
    int linesize[4];   // [4] = alpha channel, currently not used
    
    unsigned width;
    unsigned height;
    
} YUVVideoPicture;

@interface JJYUVDisplayView : GLKView <GLKViewDelegate>

-(void)setVideoPicture:(YUVVideoPicture*)picture;

@end
