//
//  ISBTReceivingCell.h
//  iShare
//
//  Created by Jin Jin on 12-10-19.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISBTReceivingCell : UITableViewCell

@property (nonatomic, copy) NSString* identifier;

-(void)configCell:(NSDictionary*)receivingFileItem;

-(void)setReceivedBytes:(long long)bytes;

@end
