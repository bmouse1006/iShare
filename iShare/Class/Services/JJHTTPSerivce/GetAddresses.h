
//
//  GetAddress.h
//  iShare
//
//  Created by Jin Jin on 12-9-12.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#ifndef iShare_GetAddress_h
#define iShare_GetAddress_h

#define MAXADDRS    32

extern char *if_names[MAXADDRS];
extern char *ip_names[MAXADDRS];
extern char *hw_addrs[MAXADDRS];
extern unsigned long ip_addrs[MAXADDRS];

// Function prototypes

void InitAddresses();
void FreeAddresses();
void GetIPAddresses();
void GetHWAddresses();

#endif
