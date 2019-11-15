//  自定义带placeholder和限制文案显示的textView
//  WWTextView.h
//  WW
//
//  Created by wangwei on 2018/7/26.
//  Copyright © 2018年 WW. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger ,limitTextType) {
    DEFAULT        = 0, //(0/100)
    TEXT_SERIAL    = 1  //(还可以输入0个字)
};
@class WWTextView;
@protocol WWTextViewDelegate <NSObject>
@optional
-(void)textViewBeginEditing:(WWTextView *)textView;
-(void)textView:(WWTextView *)textView textDidChange:(NSString *)text adjustHeight:(CGFloat) height;
@end

@interface WWTextView : UIView
@property (nonatomic, copy) NSString *text;               ///textView的文本内容
@property (nonatomic, copy) NSAttributedString *attributedText;     //textView的富文本内容
@property (nonatomic, strong) UIColor  *color;            ///textView的文本颜色
@property (nonatomic, strong) UIFont   *font;             ///textView的文本字号

@property (nonatomic, assign) BOOL editable;              ///是否允许编辑
@property (nonatomic, assign) BOOL selectable;            ///文本是否可选择
@property (nonatomic, assign) BOOL scrollEnabled;         ///是否可以滚动

@property (nonatomic, strong) UIColor  *placeholderColor; ///textView placeholder的文本颜色
@property (nonatomic, strong) UIFont   *placeholderFont;  ///textView placeholder的文本字号
@property (nonatomic, strong) NSString *placeholder;      ///textView placeholder的文本内容  ****文本后于颜色、字号设置

@property (nonatomic, strong) UIColor  *limitTextColor;   ///限制显示文本颜色
@property (nonatomic, strong) UIFont   *limitFont;        ///限制显示文本字号
@property (nonatomic, assign) NSInteger limitLength;      ///不设置输入限制长度时，textView的下部分限制显示文本就不会出现
@property (nonatomic, assign) limitTextType limitTextType;       ///限制文本显示格式
@property (nonatomic, assign) BOOL limitLabelHidden;      ///textView的下部分限制显示文本是否显示（显示：false,隐藏：true）
@property (nonatomic, weak) id<WWTextViewDelegate> delegate;
@property (nonatomic, assign) NSInteger maxTextH;         ///最大文本高度
@property (nonatomic, assign) BOOL enableEdit;            ///textView是否可编辑（默认为true）
@property (nonatomic, assign) BOOL userDraging;           ///用户拖拽中
-(instancetype)init NS_UNAVAILABLE;
/**
 设置边框
 @param borderWidth 边框宽度
 @param color 边框颜色
 */
- (void)setBorderWidth:(float)borderWidth withColor:(UIColor *)color;

/**
 设置边框圆角
 @param radius 圆角半径
 */
- (void)setCornerRadius:(float)radius;

/**
 滚动到指定的范围

 @param range 范围
 */
- (void)scrollRangeToVisible:(NSRange)range;
@end
