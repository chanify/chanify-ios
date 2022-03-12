//
//  CHLoginView.m
//  OSX
//
//  Created by WizJin on 2021/8/31.
//

#import "CHLoginView.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>
#import "CHIndicatorView.h"
#import "CHTheme.h"

@interface CHLoginView () <NSDraggingDestination>

@property (nonatomic, readonly, assign) BOOL loading;
@property (nonatomic, readonly, strong) CHLabel *statusLabel;
@property (nonatomic, readonly, strong) CHLabel *noteLabel;
@property (nonatomic, readonly, strong) CHIndicatorView *indicatorView;

@end

@implementation CHLoginView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
        
        _loading = NO;
        
        CHTheme *theme = CHTheme.shared;
        
        CHLabel *titleLabel = [CHLabel new];
        [self addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.equalTo(self);
        }];
        titleLabel.font = [CHFont systemFontOfSize:18 weight:NSFontWeightBold];
        titleLabel.textColor = theme.labelColor;
        titleLabel.text = @"Login".localized;
        
        CHLabel *statusLabel = [CHLabel new];
        [self addSubview:(_statusLabel = statusLabel)];
        [statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self).offset(-20);
        }];
        statusLabel.font = theme.textFont;
        statusLabel.textColor = theme.labelColor;
        statusLabel.text = @"Drop QR code here to login.".localized;
        
        CHLabel *noteLabel = [CHLabel new];
        [self addSubview:(_noteLabel = noteLabel)];
        [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.bottom.equalTo(self).offset(-20);
        }];
        noteLabel.font = theme.detailFont;
        noteLabel.textColor = theme.minorLabelColor;
        noteLabel.text = @"Get QR code from Chanify app on your iPhone.".localized;
        
        CHIndicatorView *indicatorView = [CHIndicatorView new];
        [self addSubview:(_indicatorView = indicatorView)];
        [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(statusLabel);
        }];
        indicatorView.tintColor = theme.labelColor;
        indicatorView.lineWidth = 2;
        indicatorView.radius = 36;
        indicatorView.speed = 1.8;
        indicatorView.gap = 0.8;
    }
    return self;
}

- (void)setStatusText:(NSString *)text {
    self.statusLabel.text = text;
}

- (void)setShowIndicator:(BOOL)bSHow {
    if (self.loading != bSHow) {
        _loading = bSHow;
        self.statusLabel.hidden = bSHow;
        self.noteLabel.hidden = bSHow;
        if (bSHow) {
            [self.indicatorView startAnimating];
        } else {
            [self.indicatorView stopAnimating:nil];
        }
    }
}

#pragma mark - NSDraggingDestination
- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    [self updateDraggingStatus:sender];
    if (!self.loading && [self hasDraggingImage:sender]) {
        NSImage *image = [NSImage imageWithData:[NSData dataFromNoCacheURL:[NSURL URLFromPasteboard:sender.draggingPasteboard]]];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData:image.TIFFRepresentation];
        NSArray<CIFeature *> *features = [detector featuresInImage:[[CIImage alloc] initWithBitmapImageRep:bitmapRep]];
        for (CIFeature *feature in features) {
            if ([feature isKindOfClass:CIQRCodeFeature.class]) {
                NSString *code = [(CIQRCodeFeature *)feature messageString];
                if (code.length > 0) {
                    NSURL *url = [NSURL URLWithString:code];
                    if (url != nil && self.delegate != nil) {
                        [self.delegate loginWithQrCode:url];
                    }
                }
                return;
            }
        }
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    [self updateDraggingStatus:sender];
    return NSDragOperationEvery;
}

- (void)draggingExited:(nullable id <NSDraggingInfo>)sender {
    [self updateDraggingStatus:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    [self updateDraggingStatus:sender];
    return NSDragOperationEvery;
}

#pragma mark - Private Methods
- (BOOL)hasDraggingImage:(id<NSDraggingInfo>)sender {
    BOOL res = NO;
    if (self.window == sender.draggingDestinationWindow) {
        NSPoint pt = [self convertPoint:sender.draggingLocation fromView:nil];
        if (NSPointInRect(pt, self.bounds)) {
            res = YES;
        }
    }
    return res;
}

- (void)updateDraggingStatus:(nullable id <NSDraggingInfo>)sender {
    if (!self.loading) {
        if (sender != nil && [self hasDraggingImage:sender]) {
            self.statusLabel.text = @"Release QR code to login.".localized;
        } else {
            self.statusLabel.text = @"Drop QR code here to login.".localized;
        }
    }
}


@end
