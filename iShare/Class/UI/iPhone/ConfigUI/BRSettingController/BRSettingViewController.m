//
//  BRSettingViewController.m
//  BreezyReader2
//
//  Created by 金 津 on 12-5-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "BRSettingViewController.h"
#import "UserPreferenceDefine.h"
#import "BRSettingCustomBaseView.h"
#import "BRSettingCell.h"
#import "JJPickerView.h"

@interface BRSettingViewController ()

@end

@implementation BRSettingViewController

@synthesize settingConfigs = _settingConfigs;
@synthesize pickerData = _pickerData;
@synthesize pickerIdentifier = _pickerIdentifier;


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self){
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[self.tableView visibleCells] makeObjectsPerformSelector:@selector(updateCell)];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - getter and setter
-(NSArray*)settingConfigs{
    if (_settingConfigs == nil){
        NSURL* url = [[NSBundle mainBundle] URLForResource:[self settingFilename] withExtension:@"plist"];
        _settingConfigs = [NSArray arrayWithContentsOfURL:url];
    }
    
    return _settingConfigs;
}

-(NSString*)settingFilename{
    return @"BRSettingConfig";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.settingConfigs count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[self.settingConfigs objectAtIndex:section] objectForKey:@"configs"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BRSettingCell";
    BRSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[BRSettingCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.delegate = self;
    }
    
    [cell setCellConfig:[self objectAtIndexPath:indexPath]];
    // Configure the cell...
    
    return cell;
}

-(id)objectAtIndexPath:(NSIndexPath*)indexPath{
    return [[[self.settingConfigs objectAtIndex:indexPath.section] objectForKey:@"configs"] objectAtIndex:indexPath.row];
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* config = [self objectAtIndexPath:indexPath];
    NSString* type = [[config objectForKey:@"type"] lowercaseString];
    if ([type isEqualToString:@"more"]){
        NSString* next = [config objectForKey:@"next"];
        NSString* mode = [config objectForKey:@"mode"];
        id controller = [[NSClassFromString(next) alloc] initWithNibName:next bundle:nil];
        if (controller){
            if ([mode isEqualToString:@"pop"]){
                [self presentViewController:controller animated:YES completion:NULL];
            }else{
                [self.navigationController pushViewController:controller animated:YES];
            }
        }
    }else if([type isEqualToString:@"pick"]){
        self.pickerData = [config objectForKey:@"values"];
        self.pickerIdentifier = [config objectForKey:@"identifier"];
        JJPickerView* picker = [JJPickerView loadFromBundle];
        picker.dataSource = self;
        picker.delegate = self;
        picker.baseViewDelegate = self;
        picker.titleLabel.text = NSLocalizedString([config objectForKey:@"name"], nil);
        // scrolls the specified row to center.
        [picker show];
    }
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString* titleKey = [[self.settingConfigs objectAtIndex:section] objectForKey:@"name"];
    return NSLocalizedString(titleKey, nil);
}

-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    NSString* titleKey = [[self.settingConfigs objectAtIndex:section] objectForKey:@"footertext"];
    return NSLocalizedString(titleKey, nil);
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat height = 44.0f;
    NSDictionary* config = [self objectAtIndexPath:indexPath];
    if ([[[config objectForKey:@"type"] lowercaseString] isEqualToString:@"custom"]){
        Class customClass = NSClassFromString([config objectForKey:@"customViewClass"]);
        height = [customClass heightForCustomView];
    }
    
    return height;
}

#pragma mark - setting cell actions delegate
-(void)valueChangedForIdentifier:(NSString*)identifier newValue:(id)value{
    DebugLog(@"value changed for identifier: %@", identifier);
    [UserPreferenceDefine valueChangedForIdentifier:identifier value:value];
}

#pragma mark - picker data source
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [self.pickerData count];
}

#pragma mark - picker delegate
//-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
//    DebugLog(@"%@", [[self.pickerData objectAtIndex:row] description]);
//    return [[self.pickerData objectAtIndex:row] description];
//}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0f, 0.0f, [pickerView rowSizeForComponent:component].width-12, [pickerView rowSizeForComponent:component].height)];
    
    [label setText:NSLocalizedString([[self.pickerData objectAtIndex:row] description], nil)];
    [label setTextAlignment:UITextAlignmentCenter];
    label.backgroundColor = [UIColor clearColor];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    [UserPreferenceDefine valueChangedForIdentifier:self.pickerIdentifier value:[self.pickerData objectAtIndex:row]];
}

#pragma mark - jj view delegate
-(void)viewWillShow:(BaseView *)view{
    NSInteger row = [self.pickerData indexOfObject:[UserPreferenceDefine valueForIdentifier:self.pickerIdentifier]];
    [((JJPickerView*)view).picker selectRow:row inComponent:0 animated:NO];
}

-(void)viewDidDismiss:(BaseView *)view{
    [self.tableView reloadData];
}

@end
