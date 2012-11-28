//
//  ISPhotoBrowserDataSource.m
//  iShare
//
//  Created by Jin Jin on 12-8-12.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISPhotoBrowserDelegate.h"

@interface ISPhotoBrowserDelegate()

@property (nonatomic, strong) NSArray* imageFilePaths;

@end

@implementation ISPhotoBrowserDelegate

-(id)initWithImageFilePaths:(NSArray*)filePaths{
    self = [super init];
    if (self){
        self.imageFilePaths = filePaths;
    }
    
    return self;
}

- (NSInteger)numberOfPhotos{
    return [self.imageFilePaths count];
}

- (UIImage *)imageAtIndex:(NSInteger)index{
    return [UIImage imageWithContentsOfFile:[self.imageFilePaths objectAtIndex:index]];
}

//- (UIImage *)thumbImageAtIndex:(NSInteger)index{
//    
//}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser{
    return [self.imageFilePaths count];
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index{
    MWPhoto* photo = [[MWPhoto alloc] initWithFilePath:[self.imageFilePaths objectAtIndex:index]];
    return photo;
}

@end
