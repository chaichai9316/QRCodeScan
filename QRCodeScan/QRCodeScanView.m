//
//  QRCodeScanView.m
//  QRCode
//
//  Created by cc on 2019/5/10.
//  Copyright © 2019 cc. All rights reserved.
//

#import "QRCodeScanView.h"
#import <AVFoundation/AVFoundation.h>

@interface QRCodeScanView()
<
AVCaptureMetadataOutputObjectsDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate
>

@property (nonatomic,strong) AVCaptureSession *m_Session;
@property (nonatomic,strong) AVCaptureDevice *m_device;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *m_PreviewLayer;
@property (nonatomic,strong) AVCaptureMetadataOutput *m_MetaOutput;
@property (nonatomic,strong) AVCaptureVideoDataOutput *m_VideoOutput;
@property (nonatomic,strong) CAShapeLayer *m_OverBgLayer;
@property (nonatomic,strong) UIImageView *m_ScanBox;
@property (nonatomic,strong) UIImageView *m_ScanLine;
@property (nonatomic,strong) UIButton *m_lightBtn;
@property (nonatomic,strong) NSBundle *m_resBundle;
@property (nonatomic,readwrite) BOOL loaded;
@property (nonatomic) BOOL isOpeningLight;
@property (nonatomic) CGFloat m_zoomScale;
@end

@implementation QRCodeScanView

-(void)dealloc{
    [self.m_Session stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSString *myBundlePath =
        [[NSBundle mainBundle] pathForResource:@"QRCodeScanRes" ofType:@"bundle"];
        self.m_resBundle = [NSBundle bundleWithPath:myBundlePath];
        [self loadCamera];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backFromSetting:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

-(UIImage *)getImageWithName:(NSString *)fileName {
    NSString *path = [self.m_resBundle pathForResource:fileName ofType:nil];
    return [UIImage imageWithContentsOfFile:path];
}

-(void)backFromSetting:(id)noti {
    if (!self.loaded) {
        [self loadCamera];
    }
    [self runScanAnimation];
}
-(void)enterBackground:(id)noti{
    self.isOpeningLight = NO;
}
-(void)loadCamera {
    AVCaptureDevice *device =
    [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *input =
    [AVCaptureDeviceInput deviceInputWithDevice:device
                                          error:&error];
    if (error){
        [self showPermissionAlert];
        return;
    }
    if ([device lockForConfiguration:nil])
    {
        //自动白平衡
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
        {
            [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        //自动对焦
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        //自动曝光
        if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        {
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        [device unlockForConfiguration];
    }
    self.m_device = device;
    
    self.m_MetaOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.m_MetaOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    self.m_VideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.m_VideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    self.m_Session = [[AVCaptureSession alloc] init];
    [self.m_Session setSessionPreset:AVCaptureSessionPresetHigh];
    if([self.m_Session canAddInput:input]){
        [self.m_Session addInput:input];
    }
    
    if ([self.m_Session canAddOutput:self.m_VideoOutput]) {
        [self.m_Session addOutput:self.m_VideoOutput];
    }
    
    if([self.m_Session canAddOutput:self.m_MetaOutput]){
        [self.m_Session addOutput:self.m_MetaOutput];
        [self.m_MetaOutput setMetadataObjectTypes:
         @[AVMetadataObjectTypeQRCode,
           AVMetadataObjectTypeCode39Code,
           AVMetadataObjectTypeCode128Code,
           AVMetadataObjectTypeCode39Mod43Code,
           AVMetadataObjectTypeEAN13Code,
           AVMetadataObjectTypeEAN8Code,
           AVMetadataObjectTypeCode93Code]];
    }
    
    self.m_PreviewLayer =
    [AVCaptureVideoPreviewLayer layerWithSession:self.m_Session];
    self.m_PreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.m_PreviewLayer.frame = self.layer.bounds;
    [self.layer addSublayer:self.m_PreviewLayer];
    
    [self asynLaunch];
    
    UIPinchGestureRecognizer *ges =
    [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(pinchAction:)];
    [self addGestureRecognizer:ges];
    
    self.loaded = YES;
}
-(CGFloat)maxZoomFactor {
    static CGFloat s = 0.0;
    if (s < 1.0) {
        if (self.m_device) {
            s = _m_device.activeFormat.videoMaxZoomFactor;
        }
        if (s > 6.0) {
            s = 6.0;
        }
    }
    return s;
}
-(void)pinchAction:(UIPinchGestureRecognizer *)ges{

    if (ges.state == UIGestureRecognizerStateBegan) {
        self.m_zoomScale = self.m_device.videoZoomFactor;
    }else if (ges.state == UIGestureRecognizerStateChanged){
        CGFloat s = self.m_zoomScale * ges.scale;
        if (s >= 1.0 && s <= [self maxZoomFactor]) {
            NSError *err = nil;
            if ([self.m_device lockForConfiguration:&err] && err == nil) {
                self.m_device.videoZoomFactor = s;
                [self.m_device unlockForConfiguration];
            }
        }
    }
}
-(void)asynLaunch {
    UIActivityIndicatorView *act =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:act];
    act.hidesWhenStopped = YES;
    act.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    [act startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^
    {
        [self.m_Session startRunning];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [act stopAnimating];
            [self loadOverlayLayer];
        });
    });
}

-(void)loadOverlayLayer{
    self.m_OverBgLayer = [CAShapeLayer layer];
    self.m_OverBgLayer.frame = self.layer.bounds;
    
    CGFloat w = self.bounds.size.width * 0.6;
    CGRect r = CGRectZero;
    r.size = CGSizeMake(w, w);
    CGRect scanRect =
    CGRectOffset(r,
                 (self.bounds.size.width - w) / 2.0,
                 (self.bounds.size.height - w) / 2.0);
    self.m_ScanBox = [[UIImageView alloc] initWithFrame:scanRect];
    self.m_ScanBox.image =
    [self getImageWithName:@"scan_box.png"];
    [self addSubview:self.m_ScanBox];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.m_ScanBox.frame];
    [path appendPath:[UIBezierPath bezierPathWithRect:self.bounds]];
    
    [self.m_OverBgLayer setFillRule:kCAFillRuleEvenOdd];
    [self.m_OverBgLayer setPath:path.CGPath];
    [self.m_OverBgLayer setFillColor:[UIColor colorWithWhite:0 alpha:0.6].CGColor];
    
    [self.layer addSublayer:self.m_OverBgLayer];
    
    self.m_MetaOutput.rectOfInterest =
    [self.m_PreviewLayer metadataOutputRectOfInterestForRect:self.m_ScanBox.frame];
    
    self.m_ScanLine =
    [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.m_ScanBox.bounds.size.width, 2)];
    self.m_ScanLine.image = [self getImageWithName:@"scan_line.png"];
    [self.m_ScanBox addSubview:self.m_ScanLine];
    
    [self runScanAnimation];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [btn setBackgroundImage:[self getImageWithName:@"scan_light.png"]
                   forState:UIControlStateNormal];
    btn.tintColor = [UIColor greenColor];
    [self addSubview:btn];
    [btn addTarget:self
            action:@selector(openLight:)
  forControlEvents:UIControlEventTouchUpInside];
    CGFloat y = scanRect.origin.y + scanRect.size.height + 30;
    btn.center = CGPointMake(self.bounds.size.width / 2.0, y);
    self.m_lightBtn = btn;
    btn.hidden = YES;
}
-(void)runScanAnimation{
    if(!self.m_ScanLine){
        return;
    }
    [self.m_ScanLine.layer removeAllAnimations];
    
    CGPoint starPoint = CGPointMake(self.m_ScanBox.bounds.size.width / 2.0  , 1);
    CGPoint endPoint = CGPointMake(self.m_ScanBox.bounds.size.width / 2.0, self.m_ScanBox.bounds.size.height - 1);
    CABasicAnimation *ani =
    [CABasicAnimation animationWithKeyPath:@"position"];
    ani.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    ani.fromValue = [NSValue valueWithCGPoint:starPoint];
    ani.toValue = [NSValue valueWithCGPoint:endPoint];
    ani.duration = 2.5f;
    ani.repeatCount = CGFLOAT_MAX;
    ani.autoreverses = YES;
    [self.m_ScanLine.layer addAnimation:ani forKey:nil];
}
-(void)openLight:(UIButton*)sender {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device =
        [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch]){
            [device lockForConfiguration:nil];
            if (device.torchMode == AVCaptureTorchModeOff){
                [device setTorchMode:AVCaptureTorchModeOn];
                self.isOpeningLight = YES;
            }else{
                [device setTorchMode:AVCaptureTorchModeOff];
                self.isOpeningLight = NO;
            }
            [device unlockForConfiguration];
        }
    }
}

#pragma mark -
#pragma mark  AVCaptureMetadataOutputObjects Delegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //扫完完成
    if (metadataObjects.count > 0)
    {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects.firstObject;
        NSString *result = obj.stringValue;
        [self.m_Session stopRunning];
        if (self.delegate && [self.delegate respondsToSelector:@selector(scanResultDidReceived:)]) {
            [self.delegate scanResultDidReceived:result];
        }
    }
}
#pragma mark -
#pragma mark  AVCaptureVideoDataOutputSampleBufferDelegate Delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (self.isOpeningLight) {
        return;
    }
    
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *dict =
    [metadata objectForKey:(__bridge NSString*)kCGImagePropertyExifDictionary];
    float brightnessValue =
    [[dict objectForKey:(__bridge NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    if (brightnessValue < - 1) {
        self.m_lightBtn.hidden = NO;
    } else {
        self.m_lightBtn.hidden = YES;
    }
}

#pragma mark - 没有摄像头权限
-(void)showPermissionAlert {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"没有打开相机权限"
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action)
                      {
                          if (self.delegate && [self.delegate respondsToSelector:@selector(cameraPrivacyDenied)]) {
                              [self.delegate cameraPrivacyDenied];
                          }
                      }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"打开"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action)
                      {
                          NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                          [[UIApplication sharedApplication] openURL:url
                                                             options:@{}
                                                   completionHandler:^(BOOL success)
                           {
                               
                           }];
                      }]];
    UIViewController* rooter =
    [UIApplication sharedApplication].delegate.window.rootViewController;
    while (rooter.presentedViewController) {
        rooter = rooter.presentedViewController;
    }
    [rooter presentViewController:alert
                         animated:YES
                       completion:nil];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
