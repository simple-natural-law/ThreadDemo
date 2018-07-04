//
//  CustomRunLoopSourceClient.h
//  ThreadDemo
//
//  Created by 张诗健 on 2018/7/4.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RunLoopContext;

@interface CustomRunLoopSourceClient : NSObject

+ (instancetype)shared;

- (void)registerSourceWithContext:(RunLoopContext *)context;

- (void)removeSourceWithContext:(RunLoopContext *)context;

@end
