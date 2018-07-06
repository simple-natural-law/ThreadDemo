//
//  ViewController.m
//  ThreadDemo
//
//  Created by 张诗健 on 2018/6/3.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "ViewController.h"
#import <pthread/pthread.h>
#import "CustomRunLoopSource.h"
#import "CustomRunLoopSourceClient.h"


@interface ViewController ()<NSPortDelegate>
{
    NSInteger count;
}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


/*
 * 创建线程
 */
- (IBAction)creatThreadA:(id)sender
{
    // 创建一个线程对象
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadAMainMethod) object:nil];
    
    // 设置线程名称（方便调试）
    thread.name = @"threadA";
    
    // 设置线程的优先级，默认为0.5
    [thread setThreadPriority:0.6];
    
    // 设置可以从任何位置访问的线程局部存储（例如，我们可以使用它通过线程的run loop的多次迭代来保存状态信息）
    [thread.threadDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"ThreadShouldExitNow"];
    
    // 启动线程
    [thread start];
}


- (IBAction)creatThreadB:(id)sender
{
    // 使用类方法直接分离一个新线程
    [NSThread detachNewThreadSelector:@selector(threadBMainMethod) toTarget:self withObject:nil];
}



- (IBAction)creatThreadC:(id)sender
{
    pthread_attr_t attr;
    pthread_t posixThreadID;
    int returnVal;
    
    returnVal = pthread_attr_init(&attr);
    
    assert(!returnVal);
    
    // 设置线程的分离状态
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    
    assert(!returnVal);
    
    // 创建线程
    int threadError = pthread_create(&posixThreadID, &attr, &PosixThreadMainRoutine, NULL);
    
    returnVal = pthread_attr_destroy(&attr);
    
    assert(!returnVal);
    
    if (threadError != 0)
    {
        // report an error
    }
    
}


- (void)threadAMainMethod
{
    NSLog(@"线程A");
    
    for (NSInteger i = 0; i < 100; i++)
    {
        // 创建自动释放池，以便及时释放对象资源。否则，这些对象会一直保留，直到线程退出。
        @autoreleasepool
        {
            NSString *str = [NSString stringWithFormat:@"%ld",i];
            NSLog(@"%@",str);
        }
    }
    
    NSLog(@"线程A退出");
}

- (void)threadBMainMethod
{
    NSLog(@"线程B");
    
    for (NSInteger i = 0; i < 10; i++)
    {
        NSLog(@"%ld",i);
    }
    
    NSLog(@"线程B退出");
}


void* PosixThreadMainRoutine(void* data)
{
    // do some work here
    NSLog(@"线程C");
    
    for (NSInteger i = 0; i < 10; i++)
    {
        NSLog(@"%ld",i);
    }
    
    NSLog(@"线程C退出");
    
    return NULL;
}



// 使用NSRunLoop来配置 Run Loop
- (IBAction)launchThreadA:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(threadAMainRoutline) toTarget:self withObject:nil];
}

- (void)threadAMainRoutline
{
    NSLog(@"进入线程A");
    
    NSThread *thread = [NSThread currentThread];
    
    [thread.threadDictionary setObject:[NSNumber numberWithInteger:0] forKey:@"repeatCount"];
    
    // 获取当前线程的run loop对象
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    // 创建一个run loop观察者，并将其与run loop关联起来。
    CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopObserverCallBack, &context);
    
    if (observer)
    {
        CFRunLoopRef cfLoop = [runLoop getCFRunLoop];
        
        CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);
    }
    
    NSInteger loopCount = 20;
    
    // 使用此方法创建定时器时，会自动附加定时器源到当前线程的run loop上。
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    
    while (loopCount)
    {
        // 进入事件处理循环
        //[runLoop run];
        
        // 进入事件处理循环，并在指定的日期自动退出事件处理循环。
        //[runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];
        
        // 以特定的模式进入事件处理循环，并在指定的日期自动退出事件处理循环。
        // 如果启动run loop并处理输入源或达到指定的超时值，则返回YES; 否则，如果无法启动run loop，则返回NO。
        BOOL done = [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];
        
        if (!done)
        {
            NSLog(@"启动 run loop 失败!!!");
        }
        
        loopCount--;
    }
    
    NSLog(@"退出线程A");
}


- (void)timerFire:(NSTimer *)timer
{
    NSThread *thread = [NSThread currentThread];
    
    NSInteger repeatCount = [[thread.threadDictionary objectForKey:@"repeatCount"] integerValue];
    
    repeatCount++;
    
    [thread.threadDictionary setObject:[NSNumber numberWithInteger:repeatCount] forKey:@"repeatCount"];
    
    NSLog(@"============= %ld",repeatCount);
}



// 使用CFRunLoopRef来配置 Run Loop
- (IBAction)launchThreadB:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(threadBMainRoutline) toTarget:self withObject:nil];
}

- (void)threadBMainRoutline
{
    NSLog(@"进入线程B");
    
    BOOL done = NO;
    
    CFRunLoopRef cfLoop = CFRunLoopGetCurrent();
    
    CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopObserverCallBack, &context);
    
    if (observer)
    {
        CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);
    }
    
    NSInteger loopCount = 5;
    
    // Add your sources or timers to the run loop and do any other setup.
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    
    do
    {
        // Start the run loop but return after each source is handled.
        SInt32 result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 4.0, YES);
        
        // If a source explicitly stopped the run loop, or if there are no
        // sources or timers, go ahead and exit.
        if (result == kCFRunLoopRunStopped || result == kCFRunLoopRunFinished)
        {
            done = YES;
        }
        
        // Check for any other exit conditions here and set the
        // done variable as needed.
        
        loopCount--;
        
        if (loopCount == 0)
        {
            done = YES;
        }
        
    } while (!done);
    
    NSLog(@"退出线程B");
}



/// 自定义输入源
- (IBAction)launchThreadC:(id)sender
{
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadCMainRoutline) object:nil];
    
    // 设置线程名称（方便调试）
    thread.name = @"CustomRunLoopSourceThread";
    
    [thread start];
    
    count = 5;
    
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(inputEvent:) userInfo:nil repeats:YES];
}


- (void)threadCMainRoutline
{
    NSLog(@"进入线程C ----> %@",[NSThread currentThread].name);
    
    BOOL done = NO;
    
    CFRunLoopRef cfLoop = CFRunLoopGetCurrent();
    
    CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopObserverCallBack, &context);
    
    if (observer)
    {
        CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);
    }
    
    NSInteger loopCount = 10;
    
    // Add your sources or timers to the run loop and do any other setup.
    CustomRunLoopSource *source = [[CustomRunLoopSource alloc] init];
    
    [source addToRunLoop:cfLoop withMode:kCFRunLoopDefaultMode];
    
    do
    {
        // Start the run loop but return after each source is handled.
        SInt32 result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10.0, YES);
        
        // If a source explicitly stopped the run loop, or if there are no
        // sources or timers, go ahead and exit.
        if (result == kCFRunLoopRunStopped || result == kCFRunLoopRunFinished)
        {
            done = YES;
        }
        
        // Check for any other exit conditions here and set the
        // done variable as needed.
        
        loopCount--;
        
        if (loopCount == 0)
        {
            done = YES;
        }
        
    } while (!done);
    
    NSLog(@"退出线程C");
}


- (void)inputEvent:(NSTimer *)timer
{
    [[CustomRunLoopSourceClient shared] addTarget:self WithSelector:@selector(exampleMethod)];
    
    count--;
    
    if (count == 0)
    {
        [timer invalidate];
        
        timer = nil;
    }
}

- (void)exampleMethod
{
    sleep(2);
    
    NSLog(@"\n当前线程 ----> %@\n",[NSThread currentThread].name);
    
    NSLog(@"\n**** 处理输入源传入的事件 ****\n");
}

// 配置定时器源
- (IBAction)installTimerSource:(id)sender
{
    // 第一种方式
    NSTimer *timerA = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0] interval:1.0 target:self selector:@selector(timerActionA:) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:timerA forMode:NSDefaultRunLoopMode];
    
    // 第二种方式
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(timerActionB:) userInfo:nil repeats:YES];
    
    // 第三种方式
    CFRunLoopTimerContext context = {0, NULL, NULL, NULL, NULL};
    
    CFRunLoopTimerRef timerC = CFRunLoopTimerCreate(kCFAllocatorDefault, 1.0, 3.0, 0, 0, &CFTimerCallBack, &context);
    
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), timerC, kCFRunLoopDefaultMode);
}

- (void)timerActionA:(NSTimer *)timer
{
    NSLog(@"timerA fire");
    
    [timer invalidate];
}


- (void)timerActionB:(NSTimer *)timer
{
    NSLog(@"timerB fire");
    
    [timer invalidate];
}

void CFTimerCallBack (CFRunLoopTimerRef timer, void *info)
{
    NSLog(@"timerC fire");
    
    CFRunLoopTimerInvalidate(timer);
}


// run loop 观察者回调
void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"进入 run loop");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"定时器即将触发");
            break;
        case kCFRunLoopBeforeSources:
            NSLog(@"不是基于端口的输入源即将触发");
            break;
        case kCFRunLoopBeforeWaiting:
            NSLog(@"线程即将进入休眠状态");
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"线程刚被唤醒");
            break;
        case kCFRunLoopExit:
            NSLog(@"退出 run loop");
            break;
        default:
            break;
    }
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
