//
//  iShareTest.m
//  iShareTest
//
//  Created by Jin Jin on 12-8-12.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "iShareTest.h"
#import "FileOperationWrap.h"

@implementation iShareTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    STFail(@"Unit tests are not implemented yet in iShareTest");
}

-(void)test2{
    NSString* home = [FileOperationWrap homePath];
    NSString* filepath = [home stringByAppendingPathComponent:@"action.png"];
    UIDocument* document = [[UIDocument alloc] initWithFileURL:[NSURL fileURLWithPath:filepath]];
    NSLog(@"document type is %@", document.fileType);
    
}

@end
