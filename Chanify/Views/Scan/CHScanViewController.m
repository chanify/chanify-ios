//
//  CHScanViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <PhotosUI/PHPicker.h>
#import <Masonry/Masonry.h>
#import "CHTheme.h"
#import "CHRouter.h"

@interface CHScanViewController () <AVCaptureMetadataOutputObjectsDelegate, PHPickerViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, readonly, assign) BOOL isClosed;
@property (nonatomic, readonly, strong) AVCaptureSession *captureSession;
@property (nonatomic, readonly, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, readonly, strong) UIButton *photoButton;
@property (nonatomic, readonly, strong) dispatch_queue_t workrtQueue;
@property (nonatomic, nullable, strong) UINavigationBar *lastNavBar;
@property (nonatomic, nullable, strong) UIColor *navBGColor;
@property (nonatomic, nullable, strong) UIImage *navBGImage;
@property (nonatomic, nullable, strong) UIImage *navBackImage;
@property (nonatomic, nullable, strong) UIImage *navBackMaskImage;
@property (nonatomic, assign) BOOL navTranslucent;

@end

@implementation CHScanViewController

- (instancetype)init {
    if (self = [super init]) {
        _isClosed = NO;
        _captureSession = nil;
        _videoPreviewLayer = nil;
        _workrtQueue = dispatch_queue_create_for(self, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    if (self.captureSession) {
        [self.captureSession stopRunning];
        _captureSession = nil;
    }
    if (self.videoPreviewLayer) {
        [self.videoPreviewLayer removeFromSuperlayer];
        _videoPreviewLayer = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CHTheme *theme = CHTheme.shared;

    // Init capture
    NSError *error = nil;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (input != nil) {
        AVCaptureSession *captureSession = [AVCaptureSession new];
        _captureSession = captureSession;
        [captureSession addInput:input];
        AVCaptureMetadataOutput *captureMetadataOutput = [AVCaptureMetadataOutput new];
        [captureSession addOutput:captureMetadataOutput];
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:self.workrtQueue];
        [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];

        UIView *viewPreview = self.view;
        AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        [viewPreview.layer addSublayer:(_videoPreviewLayer = videoPreviewLayer)];
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [videoPreviewLayer setFrame:viewPreview.layer.bounds];
    }

    UIButton *photoButton = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"photo"] target:self action:@selector(actionSelectPhoto:)];
    [self.view addSubview:(_photoButton = photoButton)];
    photoButton.backgroundColor = [theme.labelColor colorWithAlphaComponent:0.8];
    photoButton.tintColor = theme.backgroundColor;
    CGFloat radius = 28;
    photoButton.layer.cornerRadius = radius;
    [photoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-64);
        make.right.equalTo(self.view).offset(-24);
        make.size.mas_equalTo(CGSizeMake(radius * 2, radius * 2));
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.lastNavBar == nil) {
        UINavigationBar *navigationBar = self.navigationController.navigationBar;

        self.lastNavBar = navigationBar;
        
        _navBGColor = navigationBar.backgroundColor;
        _navBGImage = [navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        _navTranslucent = navigationBar.translucent;
        _navBackImage = navigationBar.backIndicatorImage;
        _navBackMaskImage = navigationBar.backIndicatorTransitionMaskImage;

        [navigationBar setBackgroundImage:CHTheme.shared.clearImage forBarMetrics:UIBarMetricsDefault];
        navigationBar.backgroundColor = UIColor.clearColor;
        navigationBar.translucent = YES;
        
        UIImage *backImage = [UIImage systemImageNamed:@"chevron.backward.circle.fill"];
        navigationBar.backIndicatorImage = backImage;
        navigationBar.backIndicatorTransitionMaskImage = backImage;
    }
    [self startScan];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopScan];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.lastNavBar != nil) {
        UINavigationBar *navigationBar = self.lastNavBar;
        
        navigationBar.backIndicatorImage = self.navBackImage;
        navigationBar.backIndicatorTransitionMaskImage = self.navBackMaskImage;

        [navigationBar setBackgroundImage:self.navBGImage forBarMetrics:UIBarMetricsDefault];
        navigationBar.backgroundColor = self.navBGColor;
        navigationBar.translucent = self.navTranslucent;

        self.lastNavBar = nil;
    }
}

- (UIBarButtonItem *)closeButtonItem {
    UIBarButtonItem *item = [super closeButtonItem];
    item.image = [UIImage systemImageNamed:@"xmark.circle.fill"];
    return item;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *qrCode = [metadataObj stringValue];
            if ([qrCode length] > 0) {
                @weakify(self);
                dispatch_main_async(^{
                    @strongify(self);
                    [self findQRCode:qrCode];
                });
            }
        }
    }
}

#pragma mark - PHPickerViewControllerDelegate
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    @weakify(self);
    [picker dismissViewControllerAnimated:YES completion:^{
        if (results.count > 0) {
            NSItemProvider *itemProvider = results.firstObject.itemProvider;
            if ([itemProvider canLoadObjectOfClass:UIImage.class]) {
                [itemProvider loadObjectOfClass:UIImage.class completionHandler:^(__kindof id<NSItemProviderReading> _Nullable object, NSError * _Nullable error) {
                    if ([object isKindOfClass:UIImage.class]) {
                        dispatch_main_async(^{
                            @strongify(self);
                            [self scanImage:(UIImage *)object];
                        });
                    }
                }];
            }
        }
    }];
}

#pragma mark - Private Methods
- (void)actionSelectPhoto:(id)sender {
    PHPickerConfiguration *configuration = [PHPickerConfiguration new];
    configuration.filter = PHPickerFilter.imagesFilter;
    configuration.selectionLimit = 1;
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    pickerViewController.delegate = self;
    [CHRouter.shared presentSystemViewController:pickerViewController animated:YES];
}

- (void)startScan {
    if (self.captureSession != nil && !self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)stopScan {
    if (self.captureSession != nil && self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

- (void)findQRCode:(NSString *)code {
    if (!self.isClosed) {
        _isClosed = YES;
        @weakify(self);
        [self closeAnimated:YES completion:^{
            dispatch_main_async(^{
                @strongify(self);
                NSURL *url = [NSURL URLWithString:code];
                id<CHScanViewControllerDelegate> delegate = self.delegate;
                if (delegate != nil) {
                    [delegate scanFindURL:url];
                } else {
                    [CHRouter.shared handleURL:url];
                }
            });
        }];
    }
}

- (void)scanImage:(UIImage *)image {
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    NSArray<CIFeature *> *features = [detector featuresInImage:[[CIImage alloc] initWithImage:image]];
    for (CIFeature *feature in features) {
        if ([feature isKindOfClass:CIQRCodeFeature.class]) {
            NSString *code = [(CIQRCodeFeature *)feature messageString];
            if (code.length > 0) {
                [self findQRCode:code];
            }
            return;
        }
    }
    [CHRouter.shared makeToast:@"No QR code".localized];
}


@end
