//
//  LogPadEnterView.h
//  XJKHealth
//
//  Created by wangwei on 2019/4/22.
//  Copyright © 2019 WW. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger,LOG_TYPE){
    LG_STDOUT_FILENO  =  0, //使用printf自定义的log输出
    LG_STDERR_FILENO  =  1  //使用fprintf自定义的log输出或者系统封装的的NSLog
};
NS_ASSUME_NONNULL_BEGIN
@interface LogPadEnterView : UIView

@property (nonatomic, assign) LOG_TYPE logType; //日志输出类型，默认值：LG_STDERR_FILENO
@property (nonatomic, assign) BOOL colorSwitch; //文本是否设置随机颜色

-(instancetype)init NS_UNAVAILABLE;

/**
   显示logPad入口
 */
-(void)show;

@end

NS_ASSUME_NONNULL_END
