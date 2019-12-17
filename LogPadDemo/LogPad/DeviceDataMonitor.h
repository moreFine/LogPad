//
//  DeviceDataMonitor.h
//  WW
//
//  Created by wangwei on 2019/8/7.
//  Copyright © 2019 WW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
void RegisterExceptionHandler(void);
@interface DeviceDataMonitor : NSObject
@property (nonatomic, copy) void(^CPUUtilization)(CGFloat value);
@property (nonatomic, copy) void(^FPS)(CGFloat value);
@property (nonatomic, copy) void(^MemoryUsage)(CGFloat value);
+(instancetype)shareInstance;
-(void)startMonitor;
-(BOOL)debugger;
@end

NS_ASSUME_NONNULL_END
