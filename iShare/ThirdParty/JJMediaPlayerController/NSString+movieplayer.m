//
//  NSString+movieplayer.m
//  iShare
//
//  Created by Jin Jin on 13-1-23.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import "NSString+movieplayer.h"

@implementation NSString (movieplayer)

+(NSString*)stringFromDurationTimeInterval:(NSTimeInterval)duration{
    
    if (duration < 0){
        return @"00:00";
    }
    
    NSInteger dur = (NSInteger)duration;
    NSInteger secs = dur % 60;
    NSInteger mins = (dur % 3600) / 60;
    NSInteger hours = dur / 3600;
    
    if (hours > 0){
        return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, mins, secs];
    }else{
        return [NSString stringWithFormat:@"%02d:%02d", mins, secs];
    }
}

@end
