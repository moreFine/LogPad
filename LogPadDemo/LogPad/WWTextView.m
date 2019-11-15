//
//  WWTextView.m
//  WW
//
//  Created by wangwei on 2018/7/26.
//  Copyright © 2018年 WW. All rights reserved.
//

#import "WWTextView.h"

@interface WWTextView()<UITextViewDelegate,UIScrollViewDelegate>
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *limitLabel;
@property (nonatomic, strong) UILabel *placeHolderLabel;
@end

@implementation WWTextView
-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        [self addTextView];
    }
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]){
        [self addTextView];
    }
    return self;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    [self addViews];
}
-(void)addTextView{
    self.textView = [[UITextView alloc] init];
    self.textView.delegate = self;
    self.textView.returnKeyType = UIReturnKeyDone;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.scrollEnabled = self.maxTextH > 0  ? false : true;
    self.enableEdit = true;
    [self addSubview:self.textView];
    
    self.limitLabel = [[UILabel alloc] init];
    self.limitFont = [UIFont systemFontOfSize:13.0];
    self.limitTextColor = [UIColor lightGrayColor];
    self.limitLabel.numberOfLines = 0;
    self.limitLabel.textAlignment = NSTextAlignmentRight;
    self.limitLabel.adjustsFontSizeToFitWidth = true;
    self.limitTextType = DEFAULT;
    [self addSubview:self.limitLabel];
}
-(void)addViews{
    if (self.placeholder && !_placeHolderLabel){
        //一定要保证textView渲染完再加载placeHolderLabel
        _placeHolderLabel = [[UILabel alloc] init];
        _placeHolderLabel.text = self.placeholder;
        _placeHolderLabel.numberOfLines = 0;
        _placeHolderLabel.textColor = self.placeholderColor ? self.placeholderColor : [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1.0];
        [_placeHolderLabel sizeToFit];
        _placeHolderLabel.font = self.placeholderFont ? self.placeholderFont : self.textView.font;
        [self.textView addSubview:_placeHolderLabel];
        [self.textView setValue:_placeHolderLabel forKey:@"_placeholderLabel"];
    }
    if (!self.limitLength || self.limitLabelHidden){
        self.textView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.limitLabel.hidden = true;
    }
    if (_limitLength){
        self.limitLength = _limitLength;//主要是再做一次布局
    }
}
-(NSString *)text{
    return self.textView.text;
}
-(void)setText:(NSString *)text{
    //不将赋值放到主队列的最后，会导致textView有初始化内容时placeholderLabel还是会显示出来
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = text;
        if (((NSInteger)text.length + text.length)>= self.limitLength){
            if (self.limitTextType == DEFAULT){
                self.limitLabel.text = [NSString stringWithFormat:@"%d/%ld",0,self->_limitLength];
            } else {
                self.limitLabel.text = @"还可以输入0个字";
            }
        } else {
            if (self.limitTextType == DEFAULT){
                self.limitLabel.text = [NSString stringWithFormat:@"%ld/%ld",self.limitLength - ((NSInteger)text.length + text.length),self->_limitLength];
            } else {
                self.limitLabel.text = [NSString stringWithFormat:@"还可以输入%ld个字",self.limitLength - ((NSInteger)text.length + text.length)];
            }
        }
    });
}
-(void)setAttributedText:(NSAttributedString *)attributedText{
    _attributedText = attributedText;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.attributedText = attributedText;
    });
}
-(void)setFont:(UIFont *)font{
    self.textView.font = font;
}
-(void)setColor:(UIColor *)color{
    self.textView.textColor = color;
}
-(void)setPlaceholder:(NSString *)placeholder{
    _placeholder = placeholder;
    [self setNeedsLayout];
}
-(void)setLimitFont:(UIFont *)limitFont{
    self.limitLabel.font = limitFont ? limitFont : self.textView.font;
}
-(void)setLimitTextColor:(UIColor *)limitTextColor{
    self.limitLabel.textColor = limitTextColor;
}
-(void)setLimitLength:(NSInteger)limitLength{
    _limitLength = limitLength;
    if (_limitTextType == DEFAULT){
        self.limitLabel.text = [NSString stringWithFormat:@"%ld/%ld",limitLength,limitLength];
    } else {
        self.limitLabel.text = [NSString stringWithFormat:@"还可以输入%ld个字",limitLength];
    }
    CGSize labelSize = [self.limitLabel sizeThatFits:CGSizeMake(200, 30)];
    self.limitLabel.frame = CGRectMake(self.frame.size.width - 10 - labelSize.width, self.frame.size.height - labelSize.height, labelSize.width, labelSize.height);
    //重新设置frame某一个空间的frame都会调用layoutSubviews方法
    self.textView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - self.limitLabel.frame.size.height);
}
-(void)setLimitTextType:(limitTextType)limitTextType{
    _limitTextType = limitTextType;
    [self setLimitLength:_limitLength];
}
-(void)setLimitLabelHidden:(BOOL)limitLabelHidden{
    _limitLabelHidden = limitLabelHidden;
    [self setNeedsLayout];
}
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewBeginEditing:)]){
        [self.delegate textViewBeginEditing:self];
    }
    return self.enableEdit;
}
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]){
        [self endEditing:true];
        return false;
    }
    if (textView.text.length >= self.limitLength && self.limitLength && self.textView == textView && ![text isEqualToString:@""]){
        return false;
    }
    if ([text isEqualToString:@""]){
        if (self.limitTextType == DEFAULT){
             self.limitLabel.text = [NSString stringWithFormat:@"%ld/%ld",self.limitLength - ((NSInteger)textView.text.length - 1 != 0 && (NSInteger)textView.text.length - 1 > 0 ? (NSInteger)textView.text.length - 1 : 0),_limitLength];
        } else {
            self.limitLabel.text = [NSString stringWithFormat:@"还可以输入%ld个字",self.limitLength - ((NSInteger)textView.text.length - 1 != 0 && (NSInteger)textView.text.length - 1 > 0 ? (NSInteger)textView.text.length - 1 : 0)];
        }
    } else {
        if (((NSInteger)textView.text.length + text.length)>= self.limitLength){
            if (self.limitTextType == DEFAULT){
                self.limitLabel.text = [NSString stringWithFormat:@"%d/%ld",0,_limitLength];
            } else {
                self.limitLabel.text = @"还可以输入0个字";
            }
        } else {
            if (self.limitTextType == DEFAULT){
                 self.limitLabel.text = [NSString stringWithFormat:@"%ld/%ld",self.limitLength - ((NSInteger)textView.text.length + text.length),_limitLength];
            } else {
                 self.limitLabel.text = [NSString stringWithFormat:@"还可以输入%ld个字",self.limitLength - ((NSInteger)textView.text.length + text.length)];
            }
        }
    }
    return true;
}
-(void)textViewDidChange:(UITextView *)textView{
    if (self.delegate && [self.delegate respondsToSelector:@selector(textView:textDidChange:adjustHeight:)]){
        NSInteger height = ceilf([self wwSizeThatFits:CGSizeMake(self.bounds.size.width, MAXFLOAT)].height);
        if (height > self.maxTextH && self.maxTextH){
            self.textView.scrollEnabled = true;
            height = self.maxTextH;
        }
        [self.delegate textView:self textDidChange:textView.text adjustHeight:height];
    }
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.userDraging = true;
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    self.userDraging = false;
}
//设置边框颜色
- (void)setBorderWidth:(float)borderWidth withColor:(UIColor *)color{
    self.layer.borderWidth=borderWidth;
    self.layer.borderColor=color.CGColor;
}
//设置边框圆角
- (void)setCornerRadius:(float)radius{
    self.layer.cornerRadius=radius;
    self.layer.masksToBounds=YES;
}
-(void)scrollRangeToVisible:(NSRange)range{
    [self.textView scrollRangeToVisible:range];
}
-(void)setEditable:(BOOL)editable{
    _editable = editable;
    self.textView.editable = editable;
}
-(void)setSelectable:(BOOL)selectable{
    _selectable = selectable;
    self.textView.selectable = selectable;
}
-(void)setScrollEnabled:(BOOL)scrollEnabled{
    _scrollEnabled = scrollEnabled;
    self.textView.scrollEnabled = scrollEnabled;
}
-(CGSize)wwSizeThatFits:(CGSize)size{
    return [self.textView sizeThatFits:size];
}
-(void)wwLayout{
    [self setNeedsLayout];
}
@end
