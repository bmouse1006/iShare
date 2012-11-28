//
//  ISShareServiceBaseDataSource.h
//  iShare
//
//  Created by Jin Jin on 12-8-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileShareServiceItem.h"

@class ISShareServiceBaseDataSource;

@protocol ISShareServiceBaseDataSourceDelegate <NSObject>

@optional
-(void)dataSourceDidFinishLoading:(ISShareServiceBaseDataSource*)dataSource;
-(void)dataSourceDidFailLoading:(ISShareServiceBaseDataSource*)dataSource error:(NSError*)error;

@end

@interface ISShareServiceBaseDataSource : NSObject<UITableViewDataSource>

@property (nonatomic, weak) id<ISShareServiceBaseDataSourceDelegate> delegate;
@property (nonatomic, strong) NSMutableArray* items;
@property (nonatomic, strong) NSString* workingPath;

-(id)initWithWorkingPath:(NSString*)workingPath;

-(void)startLoading;
-(void)loadContent;
-(BOOL)isLoading;
-(void)finishLoading;
-(void)failedLoading:(NSError*)error;
-(id)objectAtIndexPath:(NSIndexPath*)indexPath;
-(void)removeObjectAtIndexPath:(NSIndexPath*)indexPath;

@end
