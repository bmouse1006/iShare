//
//  ISHTTPDownloadResponse.m
//  iShare
//
//  Created by Jin Jin on 12-9-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISHTTPDownloadResponse.h"

@implementation ISHTTPDownloadResponse

- (NSDictionary *)httpHeaders{
    
    NSString* disposition = [NSString stringWithFormat:@"attachment;filename=%@", [self.filePath lastPathComponent]];
    return @{@"Content-Disposition":disposition};
}

@end
