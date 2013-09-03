//
//  UtilUI.h
//  Anjuke
//
//  Created by zhengpeng on 12-11-12.
//  Copyright 2011年 anjuke. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 通用UI处理类
 */
@interface UIUtil : NSObject {
    
}
//button
+ (UIButton *)drawButtonInView:(UIView *)mainView Frame:(CGRect)frame IconName:(NSString *)name Target:(id)target Action:(SEL)action;
+ (UIButton *)drawButtonInView:(UIView *)mainView Frame:(CGRect)frame IconName:(NSString *)name Insets:(UIEdgeInsets)capInsets Target:(id)target Action:(SEL)action;
+ (UIButton *)drawButtonInView:(UIView *)mainView Frame:(CGRect)frame IconName:(NSString *)name Target:(id)target Action:(SEL)action Tag:(NSInteger)tag;
+ (UIButton *)drawButtonInView:(UIView *)mainView Frame:(CGRect)frame IconName:(NSString *)name Insets:(UIEdgeInsets)capInsets Target:(id)target Action:(SEL)action Tag:(NSInteger)tag;
//image
+ (UIImageView *)drawCustomImgViewInView:(UIView *)mainView Frame:(CGRect)frame ImgName:(NSString *)name;
+ (UIImageView *)drawCustomImgViewInView:(UIView *)mainView Frame:(CGRect)frame ImgName:(NSString *)name Tag:(NSInteger)tag;
+ (UIImageView *)drawCustomImgViewInView:(UIView *)mainView Frame:(CGRect)frame ImgName:(NSString *)name Insets:(UIEdgeInsets)capInsets;
+ (UIImageView *)drawCustomImgViewInView:(UIView *)mainView Frame:(CGRect)frame ImgName:(NSString *)name Insets:(UIEdgeInsets)capInsets Tag:(NSInteger)tag;
//label
+ (UILabel *)drawLabelInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter;
+ (UILabel *)drawLabelInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter Tag:(NSInteger)tag;
+ (UILabel *)drawLabelInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter Color:(UIColor *)color;
+ (UILabel *)drawLabelMutiLineInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter;
+ (UILabel *)drawLabelMutiLineInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter Tag:(NSInteger)tag;
+ (UILabel *)drawLabelMutiLineInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text IsCenter:(BOOL)isCenter Color:(UIColor *)color;
//textview
+ (UITextView *)drawTextViewInView:(UIView *)mainView Frame:(CGRect)frame Font:(UIFont *)font Text:(NSString *)text;
@end


