//
//  ISWifiViewController.m
//  iShare
//
//  Created by Jin Jin on 12-9-10.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISWifiViewController.h"
#import "ISUserPreferenceDefine.h"
#import "JJHTTPSerivce.h"

#define kInputPortAlertViewTag      100
#define kInputUsernameAlertViewTag  200
#define kInputPasswordAlertViewTag  300

@interface ISWifiViewController ()

@property (nonatomic, strong) NSMutableArray* cells;

@end

@implementation ISWifiViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.cells = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"cell_title_wifishare", nil);
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = nil;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_texture"]];

    [self.view addSubview:self.tableView];
    
    [self configCells];
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

-(void)configCells{
    
    self.enableCell.textLabel.text = NSLocalizedString(@"cell_title_enablehttp", nil);
    self.portCell.textLabel.text = NSLocalizedString(@"cell_title_httpport", nil);
    self.portCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [ISUserPreferenceDefine httpSharePort]];
    self.authEnableCell.textLabel.text = NSLocalizedString(@"cell_title_authenable", nil);
    self.authUsernameCell.textLabel.text = NSLocalizedString(@"cell_title_authusername", nil);
    self.authUsernameCell.detailTextLabel.text = [ISUserPreferenceDefine httpShareUsername];
    self.authPasswordCell.textLabel.text = NSLocalizedString(@"cell_title_authpassword", nil);
    self.authPasswordCell.detailTextLabel.text = [ISUserPreferenceDefine httpSharePassword];
    
    [self.cells removeAllObjects];
    [self.cells addObject:self.enableCell];
    self.httpEnableSwitch.on = [JJHTTPSerivce isServiceRunning];
    self.authEnableSwitch.on = [JJHTTPSerivce authEnabled];
    if ([JJHTTPSerivce isServiceRunning]){
        [self.cells addObject:self.portCell];
        [self.cells addObject:self.authEnableCell];
        if ([[JJHTTPSerivce sharedSerivce] authEnabled]){
            [self.cells addObject:self.authUsernameCell];
            [self.cells addObject:self.authPasswordCell];
        }
    }
}

#pragma mark - table view delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == self.portCell){
        UIAlertView* portAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"cell_title_httpport", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
        portAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        portAlert.tag = kInputPortAlertViewTag;
        UITextField* textField = [portAlert textFieldAtIndex:0];
        textField.text = [NSString stringWithFormat:@"%d", [ISUserPreferenceDefine httpSharePort]];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.delegate = self;
        [portAlert show];
    }else if (cell == self.authUsernameCell){
        UIAlertView* usernameAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"cell_title_authusername", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
        usernameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        usernameAlert.tag = kInputUsernameAlertViewTag;
        UITextField* textField = [usernameAlert textFieldAtIndex:0];
        textField.text = [ISUserPreferenceDefine httpShareUsername];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [usernameAlert show];
    }else if (cell == self.authPasswordCell){
        UIAlertView* passwordAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"cell_title_authpassword", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
        passwordAlert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        passwordAlert.tag = kInputPasswordAlertViewTag;
        UITextField* textField = [passwordAlert textFieldAtIndex:0];
        textField.text = [ISUserPreferenceDefine httpSharePassword];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [passwordAlert show];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0){
        return [NSString stringWithFormat:NSLocalizedString(@"section_title_wificonfig", nil), [[JJHTTPSerivce sharedSerivce] fullURLString]];
    }
    
    return nil;
}

#pragma mark - table view datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return [self.cells count];;
            break;
        
        default:
            break;
    }
    
    return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self.cells objectAtIndex:indexPath.row];
}

#pragma mark - switch action;
-(IBAction)httpEnableSwitchValueChanged:(id)sender{
    
    NSMutableArray* rows = [NSMutableArray array];
    
    if (self.httpEnableSwitch.on){
        if ([[JJHTTPSerivce sharedSerivce] startService]){
            [self.cells addObject:self.portCell];
            [self.cells addObject:self.authEnableCell];
            [rows addObject:[NSIndexPath indexPathForRow:1 inSection:0]];
            [rows addObject:[NSIndexPath indexPathForRow:2 inSection:0]];
            if ([JJHTTPSerivce authEnabled]){
                [self.cells addObject:self.authUsernameCell];
                [self.cells addObject:self.authPasswordCell];
                [rows addObject:[NSIndexPath indexPathForRow:3 inSection:0]];
                [rows addObject:[NSIndexPath indexPathForRow:4 inSection:0]];
            }
            [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationAutomatic];
        }else{
            [self.httpEnableSwitch setOn:NO animated:YES];
        }
    }else{
        if ([[JJHTTPSerivce sharedSerivce] stopService]){
            NSArray* cells = [NSArray arrayWithArray:self.cells];
            [cells enumerateObjectsUsingBlock:^(UITableViewCell* cell, NSUInteger idx, BOOL* stop){
                if (cell != self.enableCell){
                    [self.cells removeObject:cell];
                    [rows addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                }
            }];
            [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationAutomatic];
        }else{
            [self.httpEnableSwitch setOn:YES animated:YES];
        }
    }
}

-(IBAction)authEnableSwitchValueChanged:(id)sender{
    NSMutableArray* rows = [NSMutableArray array];
    
    JJHTTPSerivce* service = [JJHTTPSerivce sharedSerivce];
    service.authEnabled = self.authEnableSwitch.on;
    
    if (service.authEnabled){
        [self.cells addObject:self.authUsernameCell];
        [self.cells addObject:self.authPasswordCell];
        
        NSInteger index1 = [self.cells indexOfObject:self.authPasswordCell];
        NSInteger index2 = [self.cells indexOfObject:self.authUsernameCell];
        
        if (index1 != NSNotFound){
            [rows addObject:[NSIndexPath indexPathForRow:index1 inSection:0]];
        }
        
        if (index2 != NSNotFound){
            [rows addObject:[NSIndexPath indexPathForRow:index2 inSection:0]];
        }

        [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationAutomatic];
    }else{
        NSInteger index1 = [self.cells indexOfObject:self.authPasswordCell];
        NSInteger index2 = [self.cells indexOfObject:self.authUsernameCell];
        
        [self.cells removeObject:self.authUsernameCell];
        [self.cells removeObject:self.authPasswordCell];
        
        if (index1 != NSNotFound){
            [rows addObject:[NSIndexPath indexPathForRow:index1 inSection:0]];
        }
        
        if (index2 != NSNotFound){
            [rows addObject:[NSIndexPath indexPathForRow:index2 inSection:0]];
        }
        
        [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    JJHTTPSerivce* service = [JJHTTPSerivce sharedSerivce];
    
    if (buttonIndex == 1){
        UITextField* textField = [alertView textFieldAtIndex:0];
        switch (alertView.tag) {
            case kInputPortAlertViewTag:
                [service setPort:[textField.text integerValue]];
                break;
            case kInputUsernameAlertViewTag:
                [service setUsername:textField.text];
                break;
            case kInputPasswordAlertViewTag:
                [service setPassword:textField.text];
                break;
            default:
                break;
        }
        
        [self configCells];
        [self.tableView reloadData];
    }
}

#pragma mark - text field delegate, for port input text field
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString* newValue = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSInteger newPort = [newValue integerValue];
    
    return (newPort <= 65535 && newPort > 0) || newValue.length == 0;
}

@end
