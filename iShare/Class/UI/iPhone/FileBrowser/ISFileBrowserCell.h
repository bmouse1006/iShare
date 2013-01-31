//
//  ISFileListCell.h
//  iShare
//
//  Created by Jin Jin on 12-8-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISFileBrowserCellInterface.h"
#import "FileThumbnailRequest.h"

@interface ISFileBrowserCell : UITableViewCell<ISFileBrowserCellInterface, FileThumbnailRequestDelegate>

@property (nonatomic, strong) IBOutlet UILabel* sizeLabel;
@property (nonatomic, strong) IBOutlet UIImageView* thumbnailImageView;

@end
