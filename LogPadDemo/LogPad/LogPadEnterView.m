//
//  LogPadEnterView.m
//  XJKHealth
//
//  Created by wangwei on 2019/4/22.
//  Copyright © 2019 xiaweidong. All rights reserved.
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
    struct kinfo_proc   info;
    size_t              size;
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    info.kp_proc.p_flag = 0;
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    // Call sysctl.
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    // We're being debugged if the P_TRACED flag is set.
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
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
        self.backgroundColor = [UIColor colorWithRed:71/255.0 green:158/255.0 blue:229/255.0 alpha:1.0];
        
        [self.layer setShadowColor:[UIColor colorWithRed:71/255.0 green:158/255.0 blue:229/255.0 alpha:1.0].CGColor];
        [self.layer setShadowOffset:CGSizeMake(0, 0)];
        [self.layer setShadowOpacity:1.0];
        [self.layer setShadowRadius:self.bounds.size.width/2.0];
        self.layer.cornerRadius = self.bounds.size.width/2.0;
        [self.layer setMasksToBounds:false];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.titleLabel.text = @"日志";
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
        self.logCenter = [[LogPadCenterView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height / 2.0)];
        self.logCenter.colorSwitch = self.colorSwitch;
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
