//
//  UIImage+QRCode.h
//  QRCode
//
//  Created by cc on 2019/5/10.
//  Copyright © 2019 cc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (QRCode)
/**识别图片二维码*/
-(NSString*)scanQRCodeString;

@end

