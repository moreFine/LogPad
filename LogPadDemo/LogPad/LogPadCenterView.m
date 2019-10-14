//
//  LogPadCenterView.m
//  WW
//
//  Created by wangwei on 2019/4/22.
//  Copyright © 2019 WW. All rights reserved.
//

#import "LogPadCenterView.h"
#import "WWTextView.h"
#import "DeviceDataMonitor.h"

@interface LogPadCenterView()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *panView;
@property (nonatomic, strong) WWTextView *textView;
@property (nonatomic, assign) int originalCharacter;
@property (nonatomic, assign) int currentCharacter;
@property (nonatomic, strong) NSFileHandle *pipeReadHandle;
@property (nonatomic, strong) UILabel *tipsLabel;
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
    self.layer.cornerRadius = 2;
    self.layer.masksToBounds = true;
    self.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.9];
    self.textView = [[WWTextView alloc] initWithFrame:CGRectMake(5, 30, self.bounds.size.width-10, self.bounds.size.height - 35)];
    self.textView.placeholder = @"\n日志打印区域";
    self.textView.editable = false;
    self.textView.selectable = false;
    self.textView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.textView.layer.shadowRadius = 5;
    self.textView.layer.shadowOffset = CGSizeMake(0, 5);
    self.textView.layer.shadowOpacity = 0.4;
    [self addSubview:self.textView];
    
    UIStackView * containerView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 25)];
    containerView.axis = UILayoutConstraintAxisHorizontal;
    containerView.distribution = UIStackViewDistributionFillEqually;
    containerView.spacing = 10;
    containerView.alignment = UIStackViewAlignmentFill;
    
    UILabel *memoryShowLabel = [[UILabel alloc] init];
    memoryShowLabel.text =  @"_ _";
    memoryShowLabel.layer.cornerRadius = 2;
    memoryShowLabel.layer.masksToBounds = true;
    memoryShowLabel.adjustsFontSizeToFitWidth = true;
    memoryShowLabel.textAlignment = NSTextAlignmentCenter;
    memoryShowLabel.backgroundColor = [UIColor colorWithRed:arc4random()%180/255.0 green:arc4random()%180/255.0 blue:arc4random()%180/255.0 alpha:1];
    [containerView addArrangedSubview:memoryShowLabel];
    
    UILabel *cpuShowLabel = [[UILabel alloc] init];
    cpuShowLabel.text = @"_ _";
    cpuShowLabel.layer.cornerRadius = 2;
    cpuShowLabel.layer.masksToBounds = true;
    cpuShowLabel.adjustsFontSizeToFitWidth = true;
    cpuShowLabel.textAlignment = NSTextAlignmentCenter;
    cpuShowLabel.backgroundColor = [UIColor colorWithRed:arc4random()%180/255.0 green:arc4random()%180/255.0 blue:arc4random()%180/255.0 alpha:1];
    [containerView addArrangedSubview:cpuShowLabel];
    
    UILabel *fpsShowLabel = [[UILabel alloc] init];
    fpsShowLabel.text = @"_ _";
    fpsShowLabel.layer.cornerRadius = 2;
    fpsShowLabel.layer.masksToBounds = true;
    fpsShowLabel.adjustsFontSizeToFitWidth = true;
    fpsShowLabel.textAlignment = NSTextAlignmentCenter;
    fpsShowLabel.backgroundColor = [UIColor colorWithRed:arc4random()%180/255.0 green:arc4random()%180/255.0 blue:arc4random()%180/255.0 alpha:1];
    [containerView addArrangedSubview:fpsShowLabel];
    
    UIButton *clearButton = [[UIButton alloc] init];
    clearButton.layer.cornerRadius = 2;
    clearButton.layer.masksToBounds = true;
    [clearButton setTitle:@"清除" forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
    clearButton.backgroundColor = [UIColor colorWithRed:arc4random()%180/255.0 green:arc4random()%180/255.0 blue:arc4random()%180/255.0 alpha:1];
    [containerView addArrangedSubview:clearButton];
    
    [self addSubview:containerView];
    
    self.tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
    self.tipsLabel.text = @"Log内容复制成功";
    self.tipsLabel.textAlignment = NSTextAlignmentCenter;
    self.tipsLabel.font = [UIFont systemFontOfSize:14.0];
    self.tipsLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    self.tipsLabel.textColor = [UIColor whiteColor];
    self.tipsLabel.center = CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
    self.tipsLabel.layer.cornerRadius = 3;
    self.tipsLabel.layer.masksToBounds = true;
    self.tipsLabel.hidden = true;
    [self addSubview:self.tipsLabel];
    
    [self startMonitorSystemLog];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    longPress.minimumPressDuration = 2.0;
    [self addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *panGestrure = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self addGestureRecognizer:panGestrure];
    
    DeviceDataMonitor *deviceMonitor = [DeviceDataMonitor shareInstance];
    deviceMonitor.CPUUtilization = ^(CGFloat value) {
        cpuShowLabel.text = [NSString stringWithFormat:@"CPU:%.0f %%",value];
    };
    deviceMonitor.FPS = ^(CGFloat value) {
        fpsShowLabel.text = [NSString stringWithFormat:@"%.0f FPS",value];
    };
    deviceMonitor.MemoryUsage = ^(CGFloat value) {
        memoryShowLabel.text = [NSString stringWithFormat:@"%.01f M",value];
    };
    [deviceMonitor startMonitor];
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
//若某一次打印的数据量过大的话，系统会分几次输出
-(void)monitorAction:(NSNotification *)notification{
    static NSData *lastData = nil;
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSMutableData *parseData = nil;
    if (lastData){
        parseData = [NSMutableData dataWithData:lastData];
        [parseData appendData:data];
    } else {
        parseData =  [NSMutableData dataWithData:data];
    }
    NSString *content = nil;
    if (parseData){
        content = [[NSString alloc] initWithData:parseData encoding:NSUTF8StringEncoding];
    }
    if (!content && parseData.length > 0){
        //本次发送的data不完整无法解析,需要保存本次并与下次读的数据一起解析
        lastData = [NSData dataWithData:parseData];
        content = @"";
    } else if (!content && parseData.length == 0) {
        content = @"";
        lastData = nil;
    } else {
        lastData = nil;
    }
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textView scrollRangeToVisible:visibleRange];
    });
    [[notification object] readInBackgroundAndNotify];
}
-(void)removeMonitor{
    dup2(self.originalCharacter, self.currentCharacter);
    //恢复重定后需要移除通知否则会导致CPU使用率激增，造成程序卡顿
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)clearAction{
    if (self.colorSwitch){
        self.textView.attributedText = nil;
    } else {
        self.textView.text = @"";
    }
}
-(void)longPressAction:(UILongPressGestureRecognizer *)longPress{
    if (longPress.state == UIGestureRecognizerStateBegan){
        UIPasteboard *pastBoard = [UIPasteboard generalPasteboard];
        if (self.colorSwitch){
            if (self.textView.attributedText.string.length != 0){
                [pastBoard setString:self.textView.attributedText.string];
                self.tipsLabel.hidden = false;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.tipsLabel.hidden = true;
                });
            }
        } else {
            if (self.textView.text.length != 0){
                [pastBoard setString:self.textView.text];
                self.tipsLabel.hidden = false;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.tipsLabel.hidden = true;
                });
            }
        }
    }
}
-(void)panAction:(UIPanGestureRecognizer *)pan{
    CGPoint currentPoint = [pan translationInView:self.superview];
    self.center = CGPointMake(self.center.x+currentPoint.x, self.center.y+currentPoint.y);
    [pan setTranslation:CGPointZero inView:self.superview];
}
@end
