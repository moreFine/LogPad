//
//  ViewController.m
//  LogPadDemo
//
//  Created by wangwei on 2019/4/24.
//  Copyright © 2019 WW. All rights reserved.
//

#import "ViewController.h"
#import "LogPadEnterView.h"
#define NSLog(FORMAT, ...) fprintf(stderr,"%s %s 第:%d行 %s\n", [[[NSString stringWithUTF8String: __FILE__] lastPathComponent] UTF8String],__func__,__LINE__,[[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String]);
//#define NSLog(FORMAT, ...) printf("[%s 行号:%d]:\n%s\n\n",__func__,__LINE__,[[NSString stringWithFormat:FORMAT,## __VA_ARGS__] UTF8String]);
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    LogPadEnterView *logPad = [[LogPadEnterView alloc] initWithFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 70, 50, 50)];
    logPad.colorSwitch = true;
    logPad.logType = LG_STDERR_FILENO;
    [logPad show];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"打印" style:UIBarButtonItemStylePlain target:self action:@selector(print1)];
    self.navigationItem.rightBarButtonItem = rightItem;
}
-(void)print1{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self print];
    });
}
-(void)print{
    NSLog(@"Log日志打印中...\n");
}

@end
