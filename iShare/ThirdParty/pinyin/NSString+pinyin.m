//
//  NSString+pinyin.m
//  MeetingPlatform
//
//  Created by  on 12-2-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NSString+pinyin.h"
#import "pinyin.h"

@implementation NSString (pinyin)

-(NSString*)pinyinString{
    char* string = (char*)malloc(sizeof(char)*self.length+1);
    int i = 0;
    for (; i<self.length; i++){
        string[i] = pinyinFirstLetter([self characterAtIndex:i]);
    }
    string[i] = '\0';
    NSString* initial = [NSString stringWithCString:string encoding:NSUTF8StringEncoding];
    free(string);
    return initial;
}

@end
