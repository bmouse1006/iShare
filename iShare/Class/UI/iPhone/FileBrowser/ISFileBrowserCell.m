//
//  ISFileListCell.m
//  iShare
//
//  Created by Jin Jin on 12-8-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISFileBrowserCell.h"
#import "FileItem.h"
#import "FileOperationWrap.h"
#import "ISUserPreferenceDefine.h"
#import "NSDictionary+FileOperationWrap.h"

@interface ISFileBrowserCell ()

@property (nonatomic, strong) FileItem* item;
@property (nonatomic, strong) FileThumbnailRequest* request;

@end

@implementation ISFileBrowserCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    self.textLabel.font = [UIFont boldSystemFontOfSize:16];
    self.detailTextLabel.font = [UIFont systemFontOfSize:14];
    self.sizeLabel.font = self.detailTextLabel.font;
    self.sizeLabel.textColor = self.detailTextLabel.textColor;
    [self.contentView addSubview:self.sizeLabel];
    [self.contentView addSubview:self.thumbnailImageView];
    CGRect frame = self.thumbnailImageView.frame;
    frame.origin.x = 5.0f;
    frame.origin.y = 5.0f;
    self.thumbnailImageView.frame = frame;
    
    self.textLabel.highlightedTextColor = self.textLabel.textColor;
    self.detailTextLabel.highlightedTextColor = self.detailTextLabel.textColor;
    self.sizeLabel.highlightedTextColor = self.sizeLabel.textColor;
}

-(void)configCell:(FileItem *)item{
    self.item = item;
    
    [self updateCell];
    
    [self setNeedsLayout];
}

-(void)updateCell{
    self.textLabel.text = [self.item.filePath lastPathComponent];
    if ([[self.item.attributes fileType] isEqualToString:NSFileTypeDirectory]){
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.accessoryView = nil;
    }else{
        self.accessoryType = UITableViewCellAccessoryNone;
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        view.backgroundColor = [UIColor clearColor];
        self.accessoryView = view;
    }
    
    [self.request removeDelegate];
    self.request = [FileThumbnailRequest requestWithFilepath:self.item.filePath size:self.thumbnailImageView.frame.size delegate:self];
    [self.request startAsync];
        
    NSString* dateString = [NSString stringWithFormat:@"%@", [self.item.attributes modificationDateWithFormate:@"yyyy-MM-dd HH:mm"]];
    self.detailTextLabel.text = dateString;
    
    NSString* sizeString = [self.item.attributes normalizedFileSize];
    self.sizeLabel.text = sizeString;
    [self.sizeLabel sizeToFit];
}

-(void)requestFinished:(FileThumbnailRequest *)request thumbnail:(UIImage *)thumbnail{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.thumbnailImageView.image = thumbnail;
        [self setNeedsLayout];
    });
}

-(FileItem*)cellItem{
    return self.item;
}

-(void)layoutSubviews{
    
    static CGFloat ImageSpace = 5.0f;
    
    [super layoutSubviews];
    
    BOOL hideThumbnail = self.thumbnailImageView.hidden = (self.thumbnailImageView.image == nil);
    
    CGRect frame;
    
    if (hideThumbnail){
        frame = self.detailTextLabel.frame;
        frame.origin.x = ImageSpace;
        frame.size.width = self.contentView.frame.size.width - frame.origin.x;
        self.detailTextLabel.frame = frame;
        
        frame = self.textLabel.frame;
        frame.origin.x = ImageSpace;
        frame.size.width = self.contentView.frame.size.width - frame.origin.x;
        self.textLabel.frame = frame;
    }else{
        frame = self.detailTextLabel.frame;
        frame.origin.x = ImageSpace * 2 + self.thumbnailImageView.frame.size.width;
        frame.size.width = self.contentView.frame.size.width - frame.origin.x;
        self.detailTextLabel.frame = frame;
        
        frame = self.textLabel.frame;
        frame.origin.x = ImageSpace * 2 + self.thumbnailImageView.frame.size.width;
        frame.size.width = self.contentView.frame.size.width - frame.origin.x;
        self.textLabel.frame = frame;
    }
    
    frame = self.sizeLabel.frame;
    frame.size.height = self.detailTextLabel.frame.size.height;
    frame.origin.y = self.detailTextLabel.frame.origin.y;
    frame.origin.x = self.contentView.frame.size.width - frame.size.width;
    self.sizeLabel.frame = frame;
}

@end
