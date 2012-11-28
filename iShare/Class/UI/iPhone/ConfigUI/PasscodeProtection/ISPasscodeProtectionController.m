//
//  ISPasscodeProtectionController.m
//  iShare
//
//  Created by Jin Jin on 12-11-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISPasscodeProtectionController.h"
#import "ISUserPreferenceDefine.h"
#import "PAPasscodeViewController.h"
#import "SVProgressHUD.h"

@interface ISPasscodeProtectionController (){
    BOOL _notFirstAppear;
}

@end

@implementation ISPasscodeProtectionController

static CGFloat ProgressHUDDuration = 1.5f;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"nav_title_passcodesetting", nil);
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_texture"]];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([ISUserPreferenceDefine passcodeEnabled] == YES && _notFirstAppear == NO){
        //show passcode UI
        [self checkPasscodeWithCompletionBlock:^{
            [self dismissViewControllerAnimated:YES completion:NULL];
        } failedAttemptBlock:^(NSInteger attempts){
            if (attempts >= 3){
                [self dismissViewControllerAnimated:YES completion:NULL];
                [self.navigationController popToRootViewControllerAnimated:NO];
            }
        } cancelBlock:^{
            [self.navigationController popToRootViewControllerAnimated:NO];
        }];
    }
    _notFirstAppear = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - passcode controller delegate
-(void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - table view delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([ISUserPreferenceDefine passcodeEnabled] == YES){
        if (indexPath.row == 0){
            //disable passcode -- enter old passcode and disable
            [self disablePasscode];
        }else if (indexPath.row == 1){
            //change passcode -- enter old passcode and set new passcode
            [self changePasscode];
        }
    }else{
        //enable passcode -- enter passcode and enable
        [self setPasscode];
    }
    
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

-(void)checkPasscodeWithCompletionBlock:(PasscodeDidEnterBlock)block failedAttemptBlock:(PasscodeDidFailedAttemptBlock)failedBlock cancelBlock:(PasscodeDidCancelBlock)cancelBlock{
    
    PAPasscodeViewController* passcodeController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
    passcodeController.passcode = [ISUserPreferenceDefine passcode];
    passcodeController.delegate = self;
    passcodeController.didEnterBlock = block;
    passcodeController.didFailedAttemptBlock = failedBlock;
    passcodeController.didCancelBlock = cancelBlock;
    
    [self presentViewController:passcodeController animated:YES completion:NULL];
}

-(void)setPasscode{
    __block typeof(self) blockSelf = self;
    
    PAPasscodeViewController* passcodeController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
    passcodeController.delegate = self;
    passcodeController.didSetBlock = ^{
        DebugLog(@"passcode did set. code is %@", passcodeController.passcode);
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"progress_message_passcodeisenabled", nil) duration:ProgressHUDDuration];
        [ISUserPreferenceDefine setPasscode:passcodeController.passcode];
        [blockSelf.tableView reloadData];
        [blockSelf dismissViewControllerAnimated:YES completion:NULL];
    };
    
    [self presentViewController:passcodeController animated:YES completion:NULL];
}

-(void)disablePasscode{
    [self checkPasscodeWithCompletionBlock:^{
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"progress_message_passcodeisdisabled", nil) duration:ProgressHUDDuration];
        [ISUserPreferenceDefine setPasscode:nil];
        [self.tableView reloadData];
        [self dismissViewControllerAnimated:YES completion:NULL];
    } failedAttemptBlock:^(NSInteger attempts){
        if (attempts >= 3){
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
    } cancelBlock:NULL];
}

-(void)changePasscode{
    __block typeof(self) blockSelf = self;
    
    PAPasscodeViewController* passcodeController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionChange];
    passcodeController.delegate = self;
    passcodeController.passcode = [ISUserPreferenceDefine passcode];
    passcodeController.didChangeBlock = ^{
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"progress_message_passcodeischanged", nil) duration:ProgressHUDDuration];
        DebugLog(@"Passcode did change. New code is %@", passcodeController.passcode);
        [ISUserPreferenceDefine setPasscode:passcodeController.passcode];
        [blockSelf dismissViewControllerAnimated:YES completion:NULL];
    };
    
    [self presentViewController:passcodeController animated:YES completion:NULL];
}

#pragma mark - table view datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ([ISUserPreferenceDefine passcodeEnabled] == YES){
        return 2;
    }else{
        return 1;
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    
    if ([ISUserPreferenceDefine passcodeEnabled] == YES){
        if (indexPath.row == 0){
            cell.textLabel.text = NSLocalizedString(@"cell_title_disablepasscode", nil);
        }else if (indexPath.row == 1){
            cell.textLabel.text = NSLocalizedString(@"cell_title_changepasscode", nil);
        }
    }else{
        cell.textLabel.text = NSLocalizedString(@"cell_title_enablepasscode", nil);
    }
    
    return cell;
}

@end
