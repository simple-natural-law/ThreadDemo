//
//  CustomRunLoopSource.h
//  ThreadDemo
//
//  Created by 张诗健 on 2018/7/4.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import <Foundation/Foundation.h>


// 调度例程
void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef runloop, CFStringRef mode);

// 处理例程
void RunLoopSourcePerformRoutine (void *info);

// 取消例程
void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef runloop, CFStringRef mode);



@interface CustomRunLoopSource : NSObject

@property (nonatomic) CFRunLoopSourceRef runLoopSource;

// 命令缓冲区
@property (nonatomic, strong) NSMutableArray *commandArray;

// 添加输入源到run loop中
- (void)addToRunLoop:(CFRunLoopRef)runloop withMode:(CFRunLoopMode)mode;

// 废弃输入源
- (void)invalidate;


- (void)sourceFired;

- (void)addCommand:(NSInteger)command withData:(id)data;

- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runloop;

@end


@interface RunLoopContext : NSObject

@property (nonatomic, readonly) CFRunLoopRef runloop;

@property (nonatomic, strong, readonly) CustomRunLoopSource *runLoopSource;

- (instancetype)initWithSource:(CustomRunLoopSource *)source andRunLoop:(CFRunLoopRef)runloop;

@end
