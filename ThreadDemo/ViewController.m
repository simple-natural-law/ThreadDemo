//
//  ViewController.m
//  ThreadDemo
//
//  Created by 张诗健 on 2018/6/3.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "ViewController.h"
#import <pthread/pthread.h>


@interface ViewController ()

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


#pragma mark - main function of thread
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



/*
 * 配置 Run Loop
 */
- (IBAction)launchThreadA:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(threadAMainRoutline) toTarget:self withObject:nil];
}

- (IBAction)launchThreadB:(id)sender
{
    
}


- (void)threadAMainRoutline
{
    NSLog(@"进入线程A");
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    
    NSInteger loopCount = 20;
    
    NSThread *thread = [NSThread currentThread];
    
    [thread.threadDictionary setObject:[NSNumber numberWithInteger:0] forKey:@"repeatCount"];
    
    // 获取当前线程的run loop对象
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    while (loopCount)
    {
        // 进入事件处理循环，到达指定的时间点后自动退出事件处理循环。
        [runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
