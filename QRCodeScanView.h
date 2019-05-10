//
//  QRCodeScanView.h
//  QRCode
//
//  Created by cc on 2019/5/10.
//  Copyright © 2019 cc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QRCodeScanViewDelegate <NSObject>

@optional
//拒绝访问相机
-(void)cameraPrivacyDenied;
//获得扫描结果
-(void)scanResultDidReceived:(NSString *)msg;

@end

@interface QRCodeScanView : UIView

@property(nonatomic,assign) id<QRCodeScanViewDelegate> delegate;

@end
