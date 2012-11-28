//
//  JJBTFileSender.m
//  iShare
//
//  Created by Jin Jin on 12-10-13.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJBTFileSender.h"

@interface JJBTFileSender(){
    long long _size;
}

@end

@implementation JJBTFileSender

-(id)init{
    self = [super init];
    if (self){
        _size = -1;
    }
    
    return self;
}

-(NSInputStream*)readStream{
    return [NSInputStream inputStreamWithFileAtPath:self.sendingObj];
}

-(long long)sizeOfObject{
    
    if (_size < 0){
        NSString* filePath = self.sendingObj;
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
        _size = [attributes fileSize];
    }
    return _size;
}

-(BTSenderType)type{
    return BTSenderTypeFile;
}

-(NSString*)name{
    return [self.sendingObj lastPathComponent];
}


@end
