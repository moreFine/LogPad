//
//  LogPadCenterView.m
//  XJKHealth
//
//  Created by wangwei on 2019/4/22.
//  Copyright © 2019 WW. All rights reserved.
//

#import "LogPadCenterView.h"
#import "WWTextView.h"
@interface LogPadCenterView()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *panView;
@property (nonatomic, strong) WWTextView *textView;
@property (nonatomic, assign) int originalCharacter;
@property (nonatomic, assign) int currentCharacter;
@property (nonatomic, strong) NSFileHandle *pipeReadHandle;
@end
@implementation LogPadCenterView
-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        [self creatUI];
    }
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]){
        [self creatUI];
    }
    return self;
}
-(void)creatUI{
    self.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.9];
    self.textView = [[WWTextView alloc] initWithFrame:self.bounds];
    self.textView.placeholder = @"\n日志打印区域";
    self.textView.editable = false;
    self.textView.selectable = false;
    [self addSubview:self.textView];
    
    self.panView = [[UIView alloc] init];
    self.panView.backgroundColor = [UIColor clearColor];
    self.panView.layer.cornerRadius = 50.0;
    self.panView.layer.masksToBounds = true;
    [self addSubview:self.panView];
    self.panView.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *leftConstraint1 = [NSLayoutConstraint constraintWithItem:self.panView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *rightConstraint1 = [NSLayoutConstraint constraintWithItem:self.panView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.panView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:kNilOptions multiplier:1.0 constant:100];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.panView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:kNilOptions multiplier:1.0 constant:100];
    
    [self.panView addConstraints:@[widthConstraint,heightConstraint]];
    [self addConstraints:@[leftConstraint1,rightConstraint1]];
    
    UIPanGestureRecognizer *panGestrure = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    panGestrure.delegate = self;
    [self.panView addGestureRecognizer:panGestrure];
}
-(void)setType:(NSUInteger)type{
    _type = type;
    [self startMonitorSystemLog];
}
-(void)startMonitorSystemLog{
    //保存重定向前的文件描述符
    NSPipe * pipe = [NSPipe pipe];
    self.pipeReadHandle = [pipe fileHandleForReading] ;
    int pipeFileHandle = [[pipe fileHandleForWriting] fileDescriptor];
    if (self.type){
        self.originalCharacter = dup(STDERR_FILENO);
        self.currentCharacter = dup2(pipeFileHandle, STDERR_FILENO);
    } else {
        self.originalCharacter = dup(STDOUT_FILENO);
        self.currentCharacter = dup2(pipeFileHandle, STDOUT_FILENO);
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(monitorAction:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:self.pipeReadHandle] ;
    [self.pipeReadHandle readInBackgroundAndNotify];
}
-(void)monitorAction:(NSNotification *)notification{
    
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    CGFloat contentLength = 0;
    if (self.colorSwitch){
        CGFloat r = (arc4random() % 180) / 255.0;
        CGFloat g = (arc4random() % 180) / 255.0;
        CGFloat b = (arc4random() % 180) / 255.0;
        NSAttributedString *attributeContent = [[NSAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0],NSForegroundColorAttributeName:[UIColor colorWithRed:r green:g blue:b alpha:1.0]}];
        NSMutableAttributedString *currentAttributeContent = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
        [currentAttributeContent appendAttributedString:attributeContent];
        self.textView.attributedText = currentAttributeContent;
        contentLength = currentAttributeContent.string.length - 1;
    } else {
        NSString *currentContent = [NSString stringWithFormat:@"%@\n%@",self.textView.text,content];
        self.textView.text = currentContent;
        contentLength = currentContent.length - 1;
    }
    NSRange visibleRange;
    visibleRange.location = contentLength;
    visibleRange.length = 0;
    [self.textView scrollRangeToVisible:visibleRange];
    [[notification object] readInBackgroundAndNotify];
}
-(void)removeMonitor{
    dup2(self.originalCharacter, self.currentCharacter);
    //恢复重定后需要移除通知否则会导致CPU使用率激增，造成程序卡顿
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)panAction:(UIPanGestureRecognizer *)pan{
    CGPoint currentPoint = [pan translationInView:self.superview];
    self.center = CGPointMake(self.center.x+currentPoint.x, self.center.y+currentPoint.y);
    [pan setTranslation:CGPointZero inView:self.superview];
    if (pan.state == UIGestureRecognizerStateBegan || pan.state == UIGestureRecognizerStateChanged){
        self.panView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    } else {
        self.panView.backgroundColor = [UIColor clearColor];
    }
}
@end
