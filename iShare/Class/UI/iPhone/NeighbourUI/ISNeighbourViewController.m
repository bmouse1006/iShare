//
//  ISNeighbourViewController.m
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISNeighbourViewController.h"

@interface ISNeighbourViewController ()

@property (nonatomic, strong) NSMutableArray* services;
@property (nonatomic, strong) NSNetServiceBrowser* afpBrowser;
@property (nonatomic, strong) NSNetServiceBrowser* smbBrowser;

@end

@implementation ISNeighbourViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.services = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //stop all browser
    [self.afpBrowser stop];
    [self.smbBrowser stop];
    //start searching bonjour services
    self.afpBrowser = [[NSNetServiceBrowser alloc] init];
    self.afpBrowser.delegate = self;
    //aftovertcp is service for apple file sharing
    [self.afpBrowser searchForServicesOfType:@"_afpovertcp._tcp" inDomain:@""];
//    [self.serviceBrowser searchForServicesOfType:@"_smb._tcp" inDomain:@""];
    //smb is service for microsoft file sharing
    self.smbBrowser = [[NSNetServiceBrowser alloc] init];
    self.smbBrowser.delegate = self;
    [self.smbBrowser searchForServicesOfType:@"_smb._tcp" inDomain:@""];
}

#pragma mark - tableview delegate

#pragma mark - tableview datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.services count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    NSNetService* service = [self.services objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", service.name, service.type];
    
    return cell;
}

#pragma mark - service browser delegate
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    [self.services insertObject:aNetService atIndex:0];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

@end
