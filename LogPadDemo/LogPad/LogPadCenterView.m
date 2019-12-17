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
#import "LogRedirectController.h"

@interface LogPadCenterView()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *panView;
@property (nonatomic, strong) WWTextView *textView;
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
    self.textView.selectable = true;
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
    memoryShowLabel.backgroundColor = [self randomColor];
    [containerView addArrangedSubview:memoryShowLabel];
    memoryShowLabel.userInteractionEnabled = true;
    UITapGestureRecognizer *scrollTop = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToTopACtion)];
    [memoryShowLabel addGestureRecognizer:scrollTop];
    
    UILabel *cpuShowLabel = [[UILabel alloc] init];
    cpuShowLabel.text = @"_ _";
    cpuShowLabel.layer.cornerRadius = 2;
    cpuShowLabel.layer.masksToBounds = true;
    cpuShowLabel.adjustsFontSizeToFitWidth = true;
    cpuShowLabel.textAlignment = NSTextAlignmentCenter;
    cpuShowLabel.backgroundColor = [self randomColor];
    [containerView addArrangedSubview:cpuShowLabel];
    cpuShowLabel.userInteractionEnabled = true;
    UITapGestureRecognizer *scrollBottom = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToBottomAction)];
    [cpuShowLabel addGestureRecognizer:scrollBottom];
    
    UILabel *fpsShowLabel = [[UILabel alloc] init];
    fpsShowLabel.text = @"_ _";
    fpsShowLabel.layer.cornerRadius = 2;
    fpsShowLabel.layer.masksToBounds = true;
    fpsShowLabel.adjustsFontSizeToFitWidth = true;
    fpsShowLabel.textAlignment = NSTextAlignmentCenter;
    fpsShowLabel.backgroundColor = [self randomColor];
    [containerView addArrangedSubview:fpsShowLabel];
    
    UIButton *readButton = [[UIButton alloc] init];
    readButton.layer.cornerRadius = 2;
    readButton.layer.masksToBounds = true;
    [readButton setTitle:@"read" forState:UIControlStateNormal];
    [readButton addTarget:self action:@selector(readAction) forControlEvents:UIControlEventTouchUpInside];
    readButton.backgroundColor = [self randomColor];
    [containerView addArrangedSubview:readButton];
    
    UIButton *clearButton = [[UIButton alloc] init];
    clearButton.layer.cornerRadius = 2;
    clearButton.layer.masksToBounds = true;
    [clearButton setTitle:@"clear" forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
    clearButton.backgroundColor = [self randomColor];
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
-(void)clearAction{
    if (self.colorSwitch){
        self.textView.attributedText = nil;
    } else {
        self.textView.text = @"";
    }
}
-(void)readAction{
    NSString *log = [[LogRedirectController shareInstance] readLogFromFile:^NSData * _Nonnull(NSData * _Nonnull LogData) {
        return LogData;
    }];
    NSMutableAttributedString *attributeContent = [[NSMutableAttributedString alloc] init];
    if (log){
        NSArray<NSString *> *logArray = [log componentsSeparatedByString:@"\r\n"];
        [logArray enumerateObjectsUsingBlock:^(NSString * _Nonnull fragmentStr, NSUInteger idx, BOOL * _Nonnull stop) {
            NSAttributedString *fragmentAtttStr = [[NSAttributedString alloc] initWithString:fragmentStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0],NSForegroundColorAttributeName:[self randomColor]}];
            [attributeContent appendAttributedString:fragmentAtttStr];
        }];
    }
    self.textView.attributedText = attributeContent;
}
-(void)scrollToTopACtion{
    [self.textView scrollRangeToVisible:NSMakeRange(0, 1)];
}
-(void)scrollToBottomAction{
    [self.textView scrollRangeToVisible:NSMakeRange(0, self.textView.attributedText.description.length)];
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
-(UIColor *)randomColor{
    return [UIColor colorWithRed:(arc4random()%100+100)/255.0 green:(arc4random()%100+100)/255.0 blue:(arc4random()%100+100)/255.0 alpha:1];
}
@end
