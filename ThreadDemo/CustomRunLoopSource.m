//
//  CustomRunLoopSource.m
//  ThreadDemo
//
//  Created by 张诗健 on 2018/7/4.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "CustomRunLoopSource.h"
#import "CustomRunLoopSourceClient.h"

@interface CustomRunLoopSource ()

@property (nonatomic, strong) NSLock *lock;

@end

@implementation CustomRunLoopSource

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        CFRunLoopSourceContext context = {0, (__bridge void *)(self), NULL, NULL, NULL, NULL, NULL, &RunLoopSourceScheduleRoutine, &RunLoopSourceCancelRoutine, &RunLoopSourcePerformRoutine};
        
        self.runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
        
        self.commandArray = [[NSMutableArray alloc] init];
        
        self.lock = [[NSLock alloc] init];
    }
    
    return self;
}

- (void)addToRunLoop:(CFRunLoopRef)runloop withMode:(CFRunLoopMode)mode
{
    CFRunLoopAddSource(runloop, self.runLoopSource, mode);
}


- (void)invalidate
{
    CFRunLoopSourceInvalidate(self.runLoopSource);
}


- (void)sourceFired
{
    for (NSDictionary *info in self.commandArray)
    {
        NSDictionary *data = info[@"data"];

        id target = data[@"target"];

        SEL selector = NSSelectorFromString(data[@"selector"]);
        
        if (!target) return;
        
        NSMethodSignature *methodSignature = [target methodSignatureForSelector:selector];
        
        if (methodSignature == nil)
        {
            methodSignature = [[target class] instanceMethodSignatureForSelector:selector];
        }
        
        if (methodSignature == nil) return;
        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        
        [invocation setTarget:target];
        
        [invocation setSelector:selector];
        
        [invocation invoke];
    }
    
    [self.lock lock];
    
    [self.commandArray removeAllObjects];
    
    [self.lock unlock];
}


- (void)addCommand:(NSInteger)command withData:(id)data
{
    [self.lock lock];
    [self.commandArray addObject:@{@"command":@(command),@"data":data}];
    [self.lock unlock];
}


- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runloop
{
    if (self.commandArray.count)
    {
        CFRunLoopSourceSignal(self.runLoopSource);
        
        CFRunLoopWakeUp(runloop);
    }
}


void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef runloop, CFStringRef mode)
{
    CustomRunLoopSource *source = (__bridge CustomRunLoopSource *)(info);
    
    RunLoopContext *context = [[RunLoopContext alloc] initWithSource:source andRunLoop:runloop];
    
    NSLog(@"将输入源通知给感兴趣的客户端");
    
    [[CustomRunLoopSourceClient shared] performSelectorOnMainThread:@selector(registerSourceWithContext:) withObject:context waitUntilDone:NO];
}


void RunLoopSourcePerformRoutine (void *info)
{
    NSLog(@"自定义输入源触发");
    
    CustomRunLoopSource *source = (__bridge CustomRunLoopSource *)(info);
    
    [source sourceFired];
}


void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef runloop, CFStringRef mode)
{
    CustomRunLoopSource *source = (__bridge CustomRunLoopSource *)(info);
    
    RunLoopContext *context = [[RunLoopContext alloc] initWithSource:source andRunLoop:runloop];
    
    NSLog(@"通知客户端输入源已经无效");
    
    [[CustomRunLoopSourceClient shared] performSelectorOnMainThread:@selector(removeSourceWithContext:) withObject:context waitUntilDone:YES];
}

@end





@interface RunLoopContext ()

@property (nonatomic) CFRunLoopRef runloop;

@property (nonatomic, strong) CustomRunLoopSource *runLoopSource;

@end



@implementation RunLoopContext

- (instancetype)initWithSource:(CustomRunLoopSource *)source andRunLoop:(CFRunLoopRef)runloop
{
    self = [super init];
    
    if (self)
    {
        self.runLoopSource = source;
        
        self.runloop = runloop;
    }
    
    return self;
}

@end
