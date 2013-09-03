//
//  UtilUI.m
//  Anjuke
//
//  Created by zhengpeng on 12-11-12.
//  Copyright 2011年 anjuke. All rights reserved.
//

#import "UIUtil.h"


@implementation UIUtil
//button
+ (UIButton *)drawButtonInView:(UIView *)mainView Frame:(CGRect)frame IconName:(NSString *)name Target:(id)target Action:(SEL)action {
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	btn.frame = frame;
    [btn setBackgroundImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
	[btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	[mainView addSubview:btn];
	return btn;
}

+ (UIButton *)drawButtonInView:(UIView *)mainView Frame:(CGRect)frame IconName:(NSString *)name Insets:(UIEdgeInsets)capInsets Target:(id)target Action:(SEL)action {
    UIButton *btn = [self drawButtonInView:mainView Frame:frame IconName:name Target:target Action:action];
    
    UIImage *img = [UIImage imageNamed:name];
    if ([img respondsToSelector:@selector(resizableImageWithCapInsets:)])
    {
        img = [img resizableImageWithCapInsets:capInsets];
    }else{
        img = [img stretchableImageWithLeftCapWidth:capInsets.left topCapHeight:capInsets.top];
    }
    
    [btn setBackgroundImage:img forState:UIControlStateNormal];
	return btn;
}

+ (UIButton *)drawButtonInView:(UIView *)mainView Frame:(CGRect)frame IconName:(NSString *)name Target:(id)target Action:(SEL)action Tag:(NSInteger)tag{
	UIButton *btn = [self drawButtonInView:mainView Frame:frame IconName:name Target:target Action:action];
	btn.tag = tag;
	return btn;
}

+ (UIButton *)drawButtonInView:(UIView *)mainView Frame:(CGRect)frame IconName:(NSString *)name Insets:(UIEdgeInsets)capInsets Target:(id)target Action:(SEL)action Tag:(NSInteger)tag{
	UIButton *btn = [self drawButtonInView:mainView Frame:frame IconName:name Insets:capInsets Target:target Action:action];
	btn.tag = tag;
	return btn;
}
//image
+ (UIImageView *)drawCustomImgViewInView:(UIView *)mainView Frame:(CGRect)frame ImgName:(NSString *)name {
	UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:name]];
	iv.frame = frame;
	[mainView addSubview:iv];
    return iv;
}

+ (UIImageView *)drawCustomImgViewInView:(UIView *)mainView Frame:(CGRect)frame ImgName:(NSString *)name Tag:(NSInteger)tag{
    UIImageView *iv = [self drawCustomImgViewInView:mainView Frame:frame ImgName:name];
    iv.tag = tag;
    return iv;
}

+ (UIImageView *)drawCustomImgViewInView:(UIView *)mainView Frame:(CGRect)frame ImgName:(NSString *)name Insets:(UIEdgeInsets)capInsets{
    UIImageView *iv = [self drawCustomImgViewInView:mainView Frame:frame ImgName:name];
    
    UIImage *img = [UIImage imageNamed:name];
    if ([img respondsToSelector:@selector(resizableImageWithCapInsets:)])
    {
        img = [img resizableImageWithCapInsets:capInsets];
    }else{
        img = [img stretchableImageWithLeftCapWidth:capInsets.left topCapHeight:capInsets.top];
    }
    
    iv.image = img;
    return iv;
}

+ (UIImageView *)drawCustomImgViewInView:(UIView *)mainView Frame:(CGRect)frame ImgName:(NSString *)name Insets:(UIEdgeInsets)capInsets Tag:(NSInteger)tag{
    UIImageView *iv = [self drawCustomImgViewInView:mainView Frame:frame ImgName:name Insets:capInsets];
    iv.tag = tag;
    return iv;
}
//label
+ (UILabel *)drawLabelInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter{
	UILabel *lb = [[UILabel alloc] initWithFrame:frame];
	lb.backgroundColor = [UIColor clearColor];
	lb.font = font;
	lb.text = text;
    if (isCenter) {
        lb.textAlignment = UITextAlignmentCenter;
    }
	[mainView addSubview:lb];
	return lb;
}

+ (UILabel *)drawLabelInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter Tag:(NSInteger)tag{
	UILabel *lb = [self drawLabelInView:mainView Frame:frame Font:font Text:text IsCenter:isCenter];
	lb.tag = tag;
	return lb;
}

+ (UILabel *)drawLabelInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter Color:(UIColor *)color {
	UILabel *lb = [self drawLabelInView:mainView Frame:frame Font:font Text:text IsCenter:isCenter];
	lb.textColor = color;
	return lb;
}

+ (UILabel *)drawLabelMutiLineInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter{
	CGSize lblSize = [text sizeWithFont:font constrainedToSize:CGSizeMake(frame.size.width, 10000) lineBreakMode:SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")  ? NSLineBreakByWordWrapping : UILineBreakModeWordWrap];
	UILabel *lb = [self drawLabelInView:mainView Frame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, /*lblSize.height > frame.size.height ? frame.size.height : lblSize.height*/lblSize.height) Font:font Text:text IsCenter:isCenter];
	lb.numberOfLines = 0;
	return lb;
}

+ (UILabel *)drawLabelMutiLineInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text  IsCenter:(BOOL)isCenter Tag:(NSInteger)tag{
    UILabel *lb = [self drawLabelMutiLineInView:mainView Frame:frame Font:font Text:text  IsCenter:isCenter Tag:tag];
	lb.tag = tag;
	return lb;
}

+ (UILabel *)drawLabelMutiLineInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter Color:(UIColor *)color{
    UILabel *lb = [self drawLabelMutiLineInView:mainView Frame:frame Font:font Text:text IsCenter:isCenter];
	lb.textColor = color;
	return lb;
}

//textview
+ (UITextView *)drawTextViewInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text{
    UITextView *tv = [[UITextView alloc] initWithFrame:frame];
    tv.text = text;
    tv.backgroundColor = [UIColor clearColor];
    tv.editable = NO;
    tv.font = font;
    [mainView addSubview:tv];
    CGRect frame2 = tv.frame;
    frame2.size.height = tv.contentSize.height;
    tv.frame = frame2;
    
    return tv;
}

@end


