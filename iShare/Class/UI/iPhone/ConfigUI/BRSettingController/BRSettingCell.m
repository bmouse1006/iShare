//
//  BRSettingCell.m
//  BreezyReader2
//
//  Created by 金 津 on 12-5-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "BRSettingCell.h"
#import "UserPreferenceDefine.h"
#import "BRSettingCustomBaseView.h"

@interface BRSettingCell ()

@property (nonatomic, strong) NSDictionary* config;
@property (nonatomic, strong) BRSettingCustomBaseView* customView;

@end

@implementation BRSettingCell

@synthesize config = _config;
@synthesize delegate = _delegate;
@synthesize customView = _customView;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.textLabel.font = [UIFont boldSystemFontOfSize:15];
        self.detailTextLabel.font = [UIFont systemFontOfSize:15];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.customView.frame = self.contentView.bounds;
}

-(void)setCellConfig:(NSDictionary*)config{
    self.config = config;
    [self updateCell];
}

-(void)updateCell{
    NSString* type = [[self.config objectForKey:@"type"] lowercaseString];
    NSString* identifier = [self.config objectForKey:@"identifier"];
    
    self.textLabel.text = NSLocalizedString([self.config objectForKey:@"name"], nil);
    self.detailTextLabel.text = nil;
    [self.customView removeFromSuperview];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryView = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    
    if ([type isEqualToString:@"switch"]){
        UISwitch* switcher = [[UISwitch alloc] init];
        switcher.on = [UserPreferenceDefine boolValueForIdentifier:identifier];
        [switcher addTarget:self action:@selector(boolValueChanged:) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = switcher;
    }else if ([type isEqualToString:@"more"]){
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.detailTextLabel.text = NSLocalizedString([UserPreferenceDefine valueForIdentifier:[self.config objectForKey:@"nextIdentifier"]], nil);
    }else if ([type isEqualToString:@"pick"]){
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        id value = [UserPreferenceDefine valueForIdentifier:identifier];
        if (value){
            self.detailTextLabel.text = NSLocalizedString([value description], nil);
        }
    }else if([type isEqualToString:@"custom"]){
        NSString* className = [self.config objectForKey:@"customViewClass"];
        self.customView = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:nil] objectAtIndex:0];
        [self.contentView addSubview:self.customView];
    }

}

#pragma mark - action
-(void)boolValueChanged:(id)sender{
    UISwitch* switcher = (UISwitch*)sender;
    NSNumber* newValue = [NSNumber numberWithBool:switcher.on];
    
    if ([self.delegate respondsToSelector:@selector(valueChangedForIdentifier:newValue:)]){
        [self.delegate valueChangedForIdentifier:[self.config objectForKey:@"identifier"] newValue:newValue];
    }
}

@end
