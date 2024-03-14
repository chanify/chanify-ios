//
//  CHNodeNewViewPage.m
//  OSX
//
//  Created by WizJin on 2021/9/26.
//

#import "CHNodeNewViewPage.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CIDetector.h>
#import <CoreImage/CIFeature.h>
#import <Masonry/Masonry.h>
#import "CHRouter.h"
#import "CHTheme.h"

@interface CHNodeNewViewPage () <NSTextFieldDelegate, NSDraggingDestination>

@property (nonatomic, readonly, strong) NSTextField *inputText;
@property (nonatomic, readonly, strong) NSButton *doneButton;

@end

@implementation CHNodeNewViewPage

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];

    CHTheme *theme = CHTheme.shared;
    
    self.title = @"Add node".localized;
    
    NSTextField *inputText = [NSTextField new];
    [self addSubview:(_inputText = inputText)];
    [inputText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(38);
        make.right.equalTo(self).offset(-38);
        make.top.equalTo(self).offset(20);
        make.height.mas_equalTo(26);
    }];
    inputText.cell.scrollable = YES;
    inputText.cell.usesSingleLineMode = YES;
    inputText.cell.focusRingType = NSFocusRingTypeNone;
    inputText.textColor = theme.labelColor;
    inputText.font = theme.textFont;
    inputText.maximumNumberOfLines = 1;
    inputText.drawsBackground = NO;
    inputText.bezeled = NO;
    inputText.bordered = NO;
    inputText.highlighted = NO;
    inputText.editable = YES;
    inputText.stringValue = @"";
    inputText.placeholderString = @"Endpoint".localized;
    inputText.delegate = self;
    
    CHView *line = [CHView new];
    line.backgroundColor = theme.labelColor;
    [self addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(30);
        make.right.equalTo(self).offset(-30);
        make.top.equalTo(inputText.mas_bottom);
        make.height.mas_equalTo(1);
    }];
    
    NSButton *doneButton = [NSButton buttonWithTitle:@"Done".localized target:self action:@selector(actionDone:)];
    [self addSubview:(_doneButton = doneButton)];
    [doneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-30);
        make.bottom.equalTo(self).offset(-20);
        make.width.mas_equalTo(100);
    }];
    doneButton.enabled = NO;
    
    NSButton *cancelButton = [NSButton buttonWithTitle:@"Cancel".localized target:self action:@selector(actionCancel:)];
    [self addSubview:cancelButton];
    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(doneButton.mas_left).offset(-10);
        make.bottom.width.equalTo(doneButton);
    }];
}

- (NSSize)calcContentSize {
    return NSMakeSize(400, 120);
}

#pragma mark - NSTextFieldDelegate
- (void)controlTextDidChange:(NSNotification *)obj {
    [self updateButtonStatus];
}

#pragma mark - NSDraggingDestination
- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    NSImage *image = [NSImage imageWithData:[NSData dataFromNoCacheURL:[NSURL URLFromPasteboard:sender.draggingPasteboard]]];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData:image.TIFFRepresentation];
    NSArray<CIFeature *> *features = [detector featuresInImage:[[CIImage alloc] initWithBitmapImageRep:bitmapRep]];
    for (CIFeature *feature in features) {
        if ([feature isKindOfClass:CIQRCodeFeature.class]) {
            NSString *code = [(CIQRCodeFeature *)feature messageString];
            if (code.length > 0) {
                NSURL *url = [NSURL URLWithString:code];
                if (url != nil) {
                    self.inputText.stringValue = url.absoluteString;
                    [self updateButtonStatus];
                    [self tryAddNode:url];
                }
            }
            return;
        }
    }
}

#pragma mark - Action Methods
- (void)actionDone:(id)sender {
    NSURL *url = [NSURL URLWithString:self.inputText.stringValue];
    if (url != nil) {
        [self tryAddNode:url];
    }
}

- (void)actionCancel:(id)sender {
    [self closeAnimated:YES completion:nil];
}

#pragma mark - Private Methods
- (void)tryAddNode:(NSURL *)url {
    if ([url.scheme isEqualToString:@"chanify"] && [url.host isEqualToString:@"node"]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
        NSString *endpoint = [components queryValueForName:@"endpoint"];
        if (endpoint.length > 0) {
            url = [NSURL URLWithString:endpoint];
        }
    }
    if (url != nil) {
        [self closeAnimated:YES completion:^{
            [CHRouter.shared routeTo:@"page/node" withParams:@{ @"endpoint": url.absoluteString, @"show": @"present" }];
        }];
    }
}

- (void)updateButtonStatus {
    self.doneButton.enabled = (self.inputText.stringValue.length > 0);
}


@end
