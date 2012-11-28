//
//  ISBTReceivingCell.m
//  iShare
//
//  Created by Jin Jin on 12-10-19.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISBTReceivingCell.h"
#import "FileOperationWrap.h"

@interface ISBTReceivingCell ()

@property (nonatomic, strong) NSMutableDictionary* receivingInfo;

@end

@implementation ISBTReceivingCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configCell:(NSMutableDictionary *)receivingFileItem{
    self.receivingInfo = receivingFileItem;
    self.identifier = [receivingFileItem objectForKey:@"identifier"];
    self.textLabel.text = [self.receivingInfo objectForKey:@"name"];
    //finished size and totle size
    [self updateCell];
}

-(void)setReceivedBytes:(long long)bytes{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.receivingInfo setObject:[NSNumber numberWithLongLong:bytes] forKey:@"receivedBytes"];
        [self updateCell];
    });
}

-(void)updateCell{
    long long receivedBytes = [[self.receivingInfo objectForKey:@"receivedBytes"] longLongValue];
    long long size = [[self.receivingInfo objectForKey:@"size"] longLongValue];
    if (receivedBytes == 0){
        self.detailTextLabel.text = [FileOperationWrap normalizedSize:size];
    }else{
        self.detailTextLabel.text = [NSString stringWithFormat:@"%@/%@", [FileOperationWrap normalizedSize:receivedBytes], [FileOperationWrap normalizedSize:size]];
    }
}

@end
