//
//  CHAboutView.m
//  OSX
//
//  Created by WizJin on 2021/9/1.
//

#import "CHAboutView.h"
#import <Masonry/Masonry.h>
#import "CHCodeFormatter.h"
#import "CHDevice.h"
#import "CHTheme.h"

@implementation CHAboutView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        
        CHTheme *theme = CHTheme.shared;
        CHDevice *device = CHDevice.shared;
        
        CHImageView *iconView = [[CHImageView alloc] initWithImage:NSApp.applicationIconImage];
        [self addSubview:iconView];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(26);
            make.centerY.equalTo(self).offset(-20);
            make.size.mas_equalTo(NSMakeSize(100, 100));
        }];
        
        CHLabel *nameLabel = [CHLabel new];
        [self addSubview:nameLabel];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(10);
            make.left.equalTo(iconView.mas_right).offset(20);
        }];
        nameLabel.font = [CHFont systemFontOfSize:20 weight:NSFontWeightBold];
        nameLabel.textColor = theme.labelColor;
        nameLabel.text = device.app;

        CHLabel *versionLabel = [CHLabel new];
        [self addSubview:versionLabel];
        [versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(nameLabel.mas_bottom).offset(4);
            make.left.equalTo(nameLabel);
        }];
        versionLabel.font = [CHFont systemFontOfSize:12 weight:NSFontWeightLight];
        versionLabel.textColor = theme.minorLabelColor;
        versionLabel.text = [NSString stringWithFormat:@"%@ %@ (%d)", @"Version".localized, device.version, device.build];
        
        CHLabel *deviceLabel = [CHLabel new];
        [self addSubview:deviceLabel];
        [deviceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(versionLabel.mas_bottom).offset(4);
            make.left.equalTo(nameLabel);
        }];
        deviceLabel.font = versionLabel.font;
        deviceLabel.textColor = versionLabel.textColor;
        NSString *deviceCode = [CHCodeFormatter.shared formatCode:device.uuid.hex length:kCHCodeFormatterLength];
        deviceLabel.text = [NSString stringWithFormat:@"%@ %@", @"Device".localized, deviceCode];
        
        NSButton *acknowledgementsButton = [NSButton buttonWithTitle:@"Acknowledgements".localized target:self action:@selector(actionAcknowledgements:)];
        [self addSubview:acknowledgementsButton];
        [acknowledgementsButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self).offset(-20);
            make.left.equalTo(nameLabel);
            make.size.mas_equalTo(NSMakeSize(152, 20));
        }];
        
        NSButton *privacyPolicyButton = [NSButton buttonWithTitle:@"Privacy Policy".localized target:self action:@selector(actionPrivacyPolicy:)];
        [self addSubview:privacyPolicyButton];
        [privacyPolicyButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(acknowledgementsButton);
            make.right.equalTo(self).offset(-16);
            make.size.equalTo(acknowledgementsButton);
        }];

        CHLabel *copyrightLabel = [CHLabel new];
        [self addSubview:copyrightLabel];
        [copyrightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(acknowledgementsButton.mas_top).offset(-10);
            make.left.equalTo(nameLabel);
        }];
        copyrightLabel.font = [CHFont systemFontOfSize:9 weight:NSFontWeightLight];
        copyrightLabel.textColor = theme.minorLabelColor;
        copyrightLabel.text = device.copyright;
    }
    return self;
}

#pragma mark - Action Methods
- (void)actionAcknowledgements:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSBundle.mainBundle URLForResource:@"Acknowledgements" withExtension:@"markdown"]];
}

- (void)actionPrivacyPolicy:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@kCHPrivacyURL]];
}


@end
