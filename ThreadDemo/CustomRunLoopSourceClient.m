//
//  CustomRunLoopSourceClient.m
//  ThreadDemo
//
//  Created by 张诗健 on 2018/7/4.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "CustomRunLoopSourceClient.h"
#import "CustomRunLoopSource.h"


@interface CustomRunLoopSourceClient ()

@property (nonatomic, strong) RunLoopContext *context;

@end


@implementation CustomRunLoopSourceClient

+ (instancetype)shared
{
    static CustomRunLoopSourceClient *customRunLoopSourceClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        customRunLoopSourceClient = [[CustomRunLoopSourceClient alloc] init];
    });
    return customRunLoopSourceClient;
}


- (void)registerSourceWithContext:(RunLoopContext *)context
{
    self.context = context;
    
    [self.context.runLoopSource fireAllCommandsOnRunLoop:self.context.runloop];
}

- (void)addTarget:(id)target WithSelector:(SEL)selector
{
    [self.context.runLoopSource addCommand:10000 withData:@{@"target":target,@"selector":NSStringFromSelector(selector)}];
    
    if (self.context)
    {
        [self.context.runLoopSource fireAllCommandsOnRunLoop:self.context.runloop];
    }
}

- (void)removeSourceWithContext:(RunLoopContext *)context
{
    self.context = nil;
}

@end
