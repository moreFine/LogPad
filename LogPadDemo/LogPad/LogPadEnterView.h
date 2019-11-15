//
//  LogPadEnterView.h
//  WW
//
//  Created by wangwei on 2019/4/22.
//  Copyright © 2019 WW. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface LogPadEnterView : UIView
@property (nonatomic, assign) BOOL colorSwitch; //文本是否设置随机颜色

-(instancetype)init NS_UNAVAILABLE;
/**
   显示logPad入口
 */
-(void)show;
@end

NS_ASSUME_NONNULL_END
