//
//  CHNodeCellView.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHNodeCellView.h"
#import <Masonry/Masonry.h>
#import "CHIconView.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHNodeCellView ()

@property (nonatomic, readonly, strong) CHIconView *iconView;
@property (nonatomic, readonly, strong) CHLabel *nameLabel;
@property (nonatomic, readonly, strong) CHLabel *endpointLabel;
@property (nonatomic, readonly, strong) CHImageView *statusIcon;

@end

@implementation CHNodeCellView

- (void)loadView {
    self.view = [CHView new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CHTheme *theme = CHTheme.shared;
    
    self.view.backgroundColor = theme.cellBackgroundColor;
    
    CHIconView *iconView = [CHIconView new];
    [self.view addSubview:(_iconView = iconView)];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(self.view).offset(8);
        make.bottom.equalTo(self.view).offset(-8);
        make.width.equalTo(iconView.mas_height);
    }];
    
    CHImageView *statusIcon = [CHImageView new];
    [self.view addSubview:(_statusIcon = statusIcon)];
    [statusIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(30);
        make.centerY.equalTo(self.view);
        make.right.equalTo(self.view).offset(-16);
    }];
    statusIcon.contentMode = UIViewContentModeScaleAspectFit;
    
    CHLabel *nameLabel = [CHLabel new];
    [self.view addSubview:(_nameLabel = nameLabel)];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconView.mas_right).offset(10);
        make.top.equalTo(iconView);
        make.right.lessThanOrEqualTo(statusIcon.mas_left).offset(-16);
    }];
    nameLabel.font = theme.textFont;
    nameLabel.textColor = theme.labelColor;
    nameLabel.numberOfLines = 1;
    
    CHLabel *endpointLabel = [CHLabel new];
    [self.view addSubview:(_endpointLabel = endpointLabel)];
    [endpointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(nameLabel);
        make.right.equalTo(nameLabel);
        make.bottom.equalTo(iconView);
    }];
    endpointLabel.font = theme.detailFont;
    endpointLabel.textColor = theme.minorLabelColor;
    endpointLabel.numberOfLines = 1;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    CHTheme *theme = CHTheme.shared;
    if (selected) {
        self.view.backgroundColor = theme.selectedCellBackgroundColor;
    } else {
        self.view.backgroundColor = theme.cellBackgroundColor;
    }
}

- (void)setModel:(CHNodeModel *)model {
    _model = model;

    self.nameLabel.text = model.name;
    self.endpointLabel.text = model.endpoint;
    self.iconView.image = model.icon;
    self.statusIcon.hidden = !model.isStoreDevice;
    if ([CHLogic.shared nodeIsConnected:model.nid]) {
        self.statusIcon.image = [CHImage systemImageNamed:@"checkmark.icloud.fill"];
        self.statusIcon.tintColor = CHTheme.shared.secureColor;
    } else {
        self.statusIcon.image = [CHImage systemImageNamed:@"xmark.icloud.fill"];
        self.statusIcon.tintColor = CHTheme.shared.alertColor;
    }
}


@end
