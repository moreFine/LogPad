//
//  LogPadEnterView.m
//  WW
//
//  Created by wangwei on 2019/4/22.
//  Copyright © 2019 WW. All rights reserved.
//
#import "LogPadEnterView.h"
#import "LogPadCenterView.h"
#import "DeviceDataMonitor.h"
@interface LogPadEnterView()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) LogPadCenterView *logCenter;
@end
@implementation LogPadEnterView
static LogPadEnterView *_enterView = nil;
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
    if ([[DeviceDataMonitor shareInstance] debugger]){
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
