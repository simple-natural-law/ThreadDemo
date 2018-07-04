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

@property (nonatomic, strong) NSTimer *timer;

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
    
    if (self.context)
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    }
}

- (void)timerFired:(NSTimer *)timer
{
    [self.context.runLoopSource addCommand:10000 withData:@{@"target":self,@"selector":NSStringFromSelector(@selector(exampleMethod))}];
    
    [self.context.runLoopSource fireAllCommandsOnRunLoop:self.context.runloop];
}

- (void)removeSourceWithContext:(RunLoopContext *)context
{
    self.context = nil;
    
    [self.timer invalidate];
    
    self.timer = nil;
}


- (void)exampleMethod
{
    NSLog(@"当前线程 ----> %@",[NSThread currentThread].name);
    
    NSLog(@"**** 处理输入源传入的事件 ****\n");
}

@end
