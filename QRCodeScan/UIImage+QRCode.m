//
//  UIImage+QRCode.m
//  QRCode
//
//  Created by cc on 2019/5/10.
//  Copyright © 2019 cc. All rights reserved.
//

#import "UIImage+QRCode.h"

@implementation UIImage (QRCode)

-(NSString*)scanQRCodeString
{
    CIImage *ciImage = [CIImage imageWithData:UIImagePNGRepresentation(self)];
    CIContext *context =
    [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO),
                                    kCIContextPriorityRequestLow : @(NO)}];
    CIDetector *detector =
    [CIDetector detectorOfType:CIDetectorTypeQRCode
                       context:context
                       options:@{
                                 CIDetectorAccuracy: CIDetectorAccuracyHigh
                                 }];
    NSArray *features = [detector featuresInImage:ciImage];
    CIQRCodeFeature *feature = [features firstObject];
    NSString *res = feature.messageString;
    if (res.length > 0) {
        return res;
    }
    return nil;
}

@end
