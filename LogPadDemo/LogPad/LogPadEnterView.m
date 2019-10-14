//
//  LogPadEnterView.m
//  WW
//
//  Created by wangwei on 2019/4/22.
//  Copyright © 2019 WW. All rights reserved.
//
#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>

#import "LogPadEnterView.h"
#import "LogPadCenterView.h"

@interface LogPadEnterView()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) LogPadCenterView *logCenter;
@end
@implementation LogPadEnterView
static LogPadEnterView *_enterView = nil;
static bool combinedXcode(void)
// Returns true if the current process is being debugged (either running under the debugger or has a debugger attached post facto).
{
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;  //进程信息结构体
    size_t              size;
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    info.kp_proc.p_flag = 0;
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    mib[0] = CTL_KERN;       //最大进程数
    mib[1] = KERN_PROC;      //进程列表
    mib[2] = KERN_PROC_PID;  //进程id
    mib[3] = getpid();       //获取目前进程的父进程识别码
    // Call sysctl.
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    // We're being debugged if the P_TRACED flag is set.
    return false;//((info.kp_proc.p_flag & P_TRACED) != 0);
}
-(instancetype)initWithFrame:(CGRect)frame{
#ifdef DEBUG
#else
    return nil;
#endif
    if (self = [super initWithFrame:frame]){
        [self creatUI];
    }
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
#ifdef DEBUG
#else
    return nil;
#endif
    if (self = [super initWithCoder:aDecoder]){
        [self creatUI];
    }
    return self;
}
-(void)creatUI{
    if (combinedXcode()){
        self.hidden = true;
    } else {
        _logType = LG_STDERR_FILENO;
        self.backgroundColor = [UIColor colorWithRed:71/255.0 green:158/255.0 blue:229/255.0 alpha:1.0];
        [self.layer setShadowColor:[UIColor colorWithRed:71/255.0 green:158/255.0 blue:229/255.0 alpha:1.0].CGColor];
        [self.layer setShadowOffset:CGSizeMake(0, 0)];
        [self.layer setShadowOpacity:1.0];
        [self.layer setShadowRadius:self.bounds.size.width/2.0];
        self.layer.cornerRadius = self.bounds.size.width/2.0;
        [self.layer setMasksToBounds:false];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.titleLabel.text = @"LOG";
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tapGesture];
    }
}
-(void)show{
     [[UIApplication sharedApplication].keyWindow addSubview:self];
}
-(void)tapAction:(UITapGestureRecognizer *)tap{
    if(!self.logCenter){
        self.logCenter = [[LogPadCenterView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height / 1.3)];
        self.logCenter.colorSwitch = self.colorSwitch;
        self.logCenter.type = self.logType == LG_STDERR_FILENO ? 1: 0;
        [[UIApplication sharedApplication].keyWindow addSubview:self.logCenter];
    } else {
        self.logCenter.hidden = !self.logCenter.hidden;
    }
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint currentPoint = [touches.anyObject locationInView:self.superview];
    self.center = currentPoint;
}
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGFloat margin = 10.0;
    CGPoint currentPoint = [touches.anyObject locationInView:self.superview];
    if (currentPoint.y < self.bounds.size.height / 2.0){
        currentPoint.y = self.bounds.size.height / 2.0 + margin;
    }
    if (currentPoint.y > [UIScreen mainScreen].bounds.size.height - self.bounds.size.height / 2.0){
        currentPoint.y = [UIScreen mainScreen].bounds.size.height - self.bounds.size.height / 2.0 - margin;
    }
    if (currentPoint.x >= [UIScreen mainScreen].bounds.size.width / 2.0){
        currentPoint.x = [UIScreen mainScreen].bounds.size.width - self.bounds.size.width / 2.0 - margin;
    } else {
        currentPoint.x = self.bounds.size.width / 2.0 + margin;
    }
    [UIView animateWithDuration:0.5 animations:^{
        self.center = currentPoint;
    }];
}
@end
