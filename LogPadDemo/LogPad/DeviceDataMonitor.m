//
//  DeviceDataMonitor.m
//  WW
//
//  Created by wangwei on 2019/8/7.
//  Copyright © 2019 WW. All rights reserved.
//

#import "DeviceDataMonitor.h"
#import <mach/mach.h>
#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>
#import "LogRedirectController.h"

@interface DeviceDataMonitor()
{
    CFRunLoopObserverRef _runloopObserver;
@public
    dispatch_semaphore_t _synLock;
    CFRunLoopActivity _runLoopActivity;
}
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTimestamp;
@end
@implementation DeviceDataMonitor
+(instancetype)shareInstance{
    static DeviceDataMonitor *monitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[DeviceDataMonitor alloc] init];
    });
    return monitor;
}
-(void)startMonitor{
    self.lastTimestamp = 0;
    [self fpsMonitor];
    [self startFluencyMonitor];
}
-(void)stopMonitor{
    [self.displayLink invalidate];
    self.displayLink = nil;
    if (_runloopObserver){
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _runloopObserver, kCFRunLoopCommonModes);
        CFRelease(_runloopObserver);
        _runloopObserver = NULL;
    }
}
-(void)cpuMonitor{
    kern_return_t kr;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0;
    
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        if (self.CPUUtilization){
            self.CPUUtilization(-1);
            return;
        }
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    float tot_cpu = 0;
    for (int j = 0; j < thread_count; j++){
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return;
        }
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            //线程不为空闲线程
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
    }
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    if (self.CPUUtilization){
        self.CPUUtilization(tot_cpu);
    }
}
-(void)memoryMonitor{
    int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if (kernReturn != KERN_SUCCESS) {
        if (self.MemoryUsage){
            self.MemoryUsage(-1);
        }
    }
    memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
    if (self.MemoryUsage){
        self.MemoryUsage(memoryUsageInByte/1024.0/1024.0);
    }
}
-(void)fpsMonitor{
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fpsCaculateAction)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}
-(void)fpsCaculateAction{
    if (self.lastTimestamp == 0){
        self.lastTimestamp = self.displayLink.timestamp;
        return;
    }
    static NSInteger count = 0;
    count++;
    NSTimeInterval dert = self.displayLink.timestamp - self.lastTimestamp;
    if (dert < 1){
        return;
    } else {
        self.lastTimestamp = self.displayLink.timestamp;
        CGFloat fps = count/dert;
        count = 0;
        if (self.FPS){
            self.FPS(fps);
        }
        [self cpuMonitor];
        [self memoryMonitor];
    }
}
-(void)startFluencyMonitor{
    _synLock = dispatch_semaphore_create(0);
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    _runloopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, true, 0, &runLoopObserverCallBack, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _runloopObserver, kCFRunLoopCommonModes);
    [self fluencyMonitorAction];
}
-(void)fluencyMonitorAction{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            //没有上锁的话lockNumber == 0
            long lockNumber = dispatch_semaphore_wait(self->_synLock, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
            if (lockNumber != 0){
                if (!self->_runloopObserver) {
                    self->_synLock = 0;
                    self->_runLoopActivity = 0;
                    return;
                }
                if (self->_runLoopActivity == kCFRunLoopBeforeSources || self->_runLoopActivity == kCFRunLoopAfterWaiting){
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        //捕获当前执行的函数栈
                        NSLog(@"▶️▶️▶️发生了卡顿◀️◀️◀️");
                        NSLog(@"%@",NSThread.callStackSymbols);
                    });
                }
            }
        }
    });
}
-(BOOL)debugger{
    if (combinedXcode()){
        return true;
    } else {
        return false;
    }
}

+(BOOL)processInfoForPID:(int)pid procInfo:(struct kinfo_proc*)procInfo{
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}
+(NSTimeInterval)processStartTime{
    struct kinfo_proc kProcInfo;
    if ([self processInfoForPID:[[NSProcessInfo processInfo] processIdentifier] procInfo:&kProcInfo]) {
        return kProcInfo.kp_proc.p_un.__p_starttime.tv_sec * 1000.0 + kProcInfo.kp_proc.p_un.__p_starttime.tv_usec / 1000.0;
    } else {
        NSAssert(NO, @"无法取得进程的信息");
        return 0;
    }
}
static bool combinedXcode(void) {
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;  //进程信息结构体
    size_t              size;
    info.kp_proc.p_flag = 0;
    mib[0] = CTL_KERN;        //最大进程数
    mib[1] = KERN_PROC;       //进程列表
    mib[2] = KERN_PROC_PID;   //进程id
    mib[3] = getpid();        //获取目前进程的父进程识别码
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    return false;//(info.kp_proc.p_flag & P_TRACED) != 0;
}
static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    DeviceDataMonitor *monitor = (__bridge DeviceDataMonitor*)info;
    monitor->_runLoopActivity = activity;
    
    dispatch_semaphore_t semaphore = monitor->_synLock;
    dispatch_semaphore_signal(semaphore);
}
static int fatal_signals[] = { SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGSEGV, SIGTRAP, SIGTERM, SIGKILL,};
static int fatal_signal_num = sizeof(fatal_signals) / sizeof(fatal_signals[0]);
static NSUncaughtExceptionHandler *_previousHandler;
void RegisterExceptionHandler(void){
    //保存其它使用NSSetUncaughtExceptionHandler的SDK设置的handler
    _previousHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&HandleException);
}
void SignalHandler(int signalType){
    NSLog(@"signal handler = %d",signalType);
}
void HandleException(NSException *exception){
    if (_previousHandler){
        _previousHandler(exception);
    }
    for (int i = 0; i < fatal_signal_num ; ++i){
        signal(fatal_signals[i], SignalHandler);
    }
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSArray *symbols = [exception callStackSymbols];                // 异常发生时的调用栈
    NSMutableString* strSymbols = [[ NSMutableString alloc ] init]; //将调用栈拼成输出日志的字符串
    for (NSString* item in symbols){
        [strSymbols appendString: item];
        [strSymbols appendString: @"\n" ];
    }
    //获取当前时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    
    NSString *crashString = [NSString stringWithFormat:@"---EXCEPTION_INFO---\n%@\nExceptionName：%@\nReason：%@\nCallTrace：\n%@\n\r\n", dateStr, name, reason, strSymbols];
    [[LogRedirectController shareInstance] writeLogToFile:crashString customHandler:nil];
}
@end
