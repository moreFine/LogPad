//
//  ViewController.m
//  LogPadDemo
//
//  Created by wangwei on 2019/4/24.
//  Copyright © 2019 WW. All rights reserved.
//  *系统NSlog最多输出1070个字符，fprintf输出不限制输出的字符个数。在使用这个库的过程中发现如果使用fprintf输出了过多的字符则会导致卡死主线程的情况。所以在使用输出日志时需要注意。

#import "ViewController.h"
#import "LogPadEnterView.h"
#import "LogRedirectController.h"

#define Log_err(FORMAT, ...) fprintf(stderr,"%s 第:%d行 %s\n", __func__,__LINE__,[[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String])

#define Log_out(FORMAT, ...) fprintf(stdout,"%s 第:%d行 %s\n", __func__,__LINE__,[[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String])

#define Loh_printf(FORMAT, ...) printf("%s 第:%d行 %s\n",__func__,__LINE__,[[NSString stringWithFormat:FORMAT,## __VA_ARGS__] UTF8String]);
@interface ViewController()
@property (nonatomic, strong) LogPadEnterView *logPad;
@property (nonatomic, strong) LogRedirectController *logger;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logPad = [[LogPadEnterView alloc] initWithFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 70, 50, 50)];
    self.logPad.colorSwitch = true;
    [self.logPad show];
    
    UIBarButtonItem *rightItem1 = [[UIBarButtonItem alloc] initWithTitle:@"恢复" style:UIBarButtonItemStylePlain target:self action:@selector(recover)];
    UIBarButtonItem *rightItem2 = [[UIBarButtonItem alloc] initWithTitle:@"重定向" style:UIBarButtonItemStylePlain target:self action:@selector(redirect)];
    self.navigationItem.rightBarButtonItems = @[rightItem1,rightItem2];
    
    UIBarButtonItem *leftItem1 = [[UIBarButtonItem alloc] initWithTitle:@"打印" style:UIBarButtonItemStylePlain target:self action:@selector(print)];
    UIBarButtonItem *leftItem2 = [[UIBarButtonItem alloc] initWithTitle:@"崩溃" style:UIBarButtonItemStylePlain target:self action:@selector(crashAction)];
    self.navigationItem.leftBarButtonItems = @[leftItem1,leftItem2];
    
    self.logger = [LogRedirectController shareInstance];
    self.logger.logType = LG_STDERR_FILENO;
    self.logger.customReadHandler = ^NSData * _Nonnull(NSData * _Nonnull logData) {
        //TODO:- you can do something or return  original value
        return logData;
    };
    self.logger.customWriteHandler = ^NSData * _Nonnull(NSData * _Nonnull logData) {
        //TODO:- you can do something or return  original value
        return logData;
    };
    [self.logger startMonitorSystemLog];
}
-(void)recover{
    [self.logger removeMonitor];
}
-(void)redirect{
    [self.logger startMonitorSystemLog];
}
-(void)print{
    NSLog(@"日志打印中1....");
    Log_err(@"日志打印中2....");
    Log_out(@"日志打印中3....");
    Loh_printf(@"日志打印中4....");
}
-(void)crashAction{
    NSArray *arr = [NSArray new];
    arr[2];
}
@end
