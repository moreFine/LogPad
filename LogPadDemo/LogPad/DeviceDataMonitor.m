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
}
-(void)stopMonitor{
    [self.displayLink invalidate];
    self.displayLink = nil;
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
-(BOOL)debugger{
    if (combinedXcode()){
        return true;
    } else {
        return false;
    }
}
static bool combinedXcode(void) {
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;  //进程信息结构体
    size_t              size;
    info.kp_proc.p_flag = 0;
    mib[0] = CTL_KERN;       //最大进程数
    mib[1] = KERN_PROC;      //进程列表
    mib[2] = KERN_PROC_PID;  //进程id
    mib[3] = getpid();       //获取目前进程的父进程识别码
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    return ((info.kp_proc.p_flag & P_TRACED) != 0);
}
void RegisterExceptionHandler(void){
    NSSetUncaughtExceptionHandler(&HandleException);
}
void HandleException(NSException *exception){
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
