//
//  NSString+QRCode.h
//  QRCode
//
//  Created by cc on 2019/5/10.
//  Copyright © 2019 cc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (QRCode)
/* 默认大小为300*300 */
-(UIImage*)generateQRCode;
/* size: 大小*/
-(UIImage*)generateQRCodeWithSize:(CGFloat)size;


/*logo: 图标 默认大小300*300
 */
-(UIImage*)generateQRCodeWithLogo:(UIImage*)logo;
/*size: 大小 logo: 图标*/
-(UIImage*)generateQRCodeWithSize:(CGFloat)size
                             logo:(UIImage*)logo;


/*size:大小 color:颜色 bgColor:背景颜色 logo:图标*/
-(UIImage*)generateQRCodeWithSize:(CGFloat)size
                            color:(UIColor*)color
                          bgColor:(UIColor*)bgColor
                             logo:(UIImage*)logo;



/**
 size:大小 color:颜色 bgColor:背景颜色 logo:图标 radius:圆角半径
 borderLineWidth:logo描边宽度 borderLineColor:logo描边颜色
 boderWidth:logo背景边缘宽度 borderColor:logo背景边缘颜色
 */
-(UIImage*)generateQRCodeWithSize:(CGFloat)size
                            color:(UIColor*)color
                          bgColor:(UIColor*)bgColor
                             logo:(UIImage*)logo
                           radius:(CGFloat)radius
                  borderLineWidth:(CGFloat)borderLineWidth
                  borderLineColor:(UIColor*)borderLineColor
                       boderWidth:(CGFloat)boderWidth
                      borderColor:(UIColor*)borderColor;

@end
