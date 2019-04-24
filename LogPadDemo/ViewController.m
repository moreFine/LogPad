//
//  ViewController.m
//  LogPadDemo
//
//  Created by wangwei on 2019/4/24.
//  Copyright © 2019 wangwei. All rights reserved.
//

#import "ViewController.h"
#import "LogPadEnterView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:true block:^(NSTimer * _Nonnull timer) {
        NSLog(@"我就是这么简单嘛,大兄弟！");
    }];
    LogPadEnterView *logPad = [[LogPadEnterView alloc] initWithFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 70, 50, 50)];
    logPad.colorSwitch = true;
    [logPad show];
}


@end
