//
//  ViewController.m
//  QRCode
//
//  Created by cc on 2019/5/10.
//  Copyright © 2019 cc. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeScanView.h"
#import "NSString+QRCode.h"

@interface ViewController ()<QRCodeScanViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *QRImage;
@property (weak, nonatomic) IBOutlet UITextView *msgView;
@property (strong, nonatomic) QRCodeScanView *m_qrView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITapGestureRecognizer *ges =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(hideBoard:)];
    [self.view addGestureRecognizer:ges];
}
-(void)hideBoard:(id)ges{
    [self.msgView resignFirstResponder];
}
- (IBAction)click:(id)sender {
    QRCodeScanView *v =
    [[QRCodeScanView alloc] initWithFrame:self.view.bounds];
    v.delegate = self;
    [self.view addSubview:v];
    self.m_qrView = v;
}
//拒绝访问相机
-(void)cameraPrivacyDenied{
    [self.m_qrView removeFromSuperview];
    self.m_qrView = nil;
}
//获得扫描结果
-(void)scanResultDidReceived:(NSString *)msg{
    
    [[[UIAlertView alloc] initWithTitle:nil
                                message:msg
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil, nil] show];
    [self.m_qrView removeFromSuperview];
    self.m_qrView = nil;
}
- (IBAction)makeQRCode:(UIButton *)sender {
    NSString *msg = self.msgView.text;
    UIImage *logo = nil;
    if (sender.tag == 0) {
        logo = [UIImage imageNamed:@"logo"];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *img = nil;
        if (logo) {
            img = [msg generateQRCodeWithLogo:logo];
        }else{
            img = [msg generateQRCode];
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.QRImage.image = img;
        });
    });
}

@end
