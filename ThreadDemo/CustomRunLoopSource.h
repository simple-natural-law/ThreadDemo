//
//  CustomRunLoopSource.h
//  ThreadDemo
//
//  Created by 张诗健 on 2018/7/4.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomRunLoopSource : NSObject

@property (nonatomic) CFRunLoopSourceRef runLoopSourceRef;

// 命令缓冲区
@property (nonatomic, strong) NSMutableArray *commandArray;


- (void)addToCurrentRunLoop;

- (void)invalidate;

- (void)sourceFired;

- (void)addCommand:(NSInteger)command withData:(id)data;

- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runloop;

@end
