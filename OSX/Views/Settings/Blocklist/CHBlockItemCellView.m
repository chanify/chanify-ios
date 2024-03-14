//
//  CHBlockItemCellView.m
//  OSX
//
//  Created by WizJin on 2021/10/4.
//

#import "CHBlockItemCellView.h"
#import <Masonry/Masonry.h>
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"
#import "CHCodeFormatter.h"
#import "CHIconView.h"
#import "CHBadgeView.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHBlockItemCellView ()

@property (nonatomic, readonly, strong) CHLabel *tokenLabel;
@property (nonatomic, readonly, strong) CHIconView *channelIconView;
@property (nonatomic, readonly, strong) CHLabel *channelTitleLabel;
@property (nonatomic, readonly, strong) CHIconView *nodeIconView;
@property (nonatomic, readonly, strong) CHLabel *nodeTitleLabel;
@property (nonatomic, readonly, strong) CHLabel *expriedDateLabel;
@property (nonatomic, readonly, strong) CHLongPressGestureRecognizer *longPressRecognizer;

@end

@implementation CHBlockItemCellView

- (void)loadView {
    self.view = [CHView new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CHTheme *theme = CHTheme.shared;
    
    self.view.backgroundColor = theme.cellBackgroundColor;
    
    CHLabel *tokenLabel = [CHLabel new];
    [self.view addSubview:(_tokenLabel = tokenLabel)];
    [tokenLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(self.view).offset(10);
    }];
    tokenLabel.font = [CHFont fontWithName:@kCHCodeFontName size:16];
    tokenLabel.textColor = theme.labelColor;
    tokenLabel.numberOfLines = 1;
    
    CHIconView *channelIconView = [CHIconView new];
    [self.view addSubview:(_channelIconView = channelIconView)];
    [channelIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tokenLabel);
        make.top.equalTo(tokenLabel.mas_bottom).offset(6);
        make.size.mas_equalTo(CGSizeMake(18, 18));
    }];
    
    CHLabel *channelTitleLabel = [CHLabel new];
    [self.view addSubview:(_channelTitleLabel = channelTitleLabel)];
    [channelTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(channelIconView.mas_right).offset(4);
        make.centerY.equalTo(channelIconView);
    }];
    channelTitleLabel.font = theme.detailFont;
    channelTitleLabel.textColor = theme.minorLabelColor;
    channelTitleLabel.numberOfLines = 1;
    
    CHIconView *nodeIconView = [CHIconView new];
    [self.view addSubview:(_nodeIconView = nodeIconView)];
    [nodeIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(channelIconView);
        make.top.equalTo(channelIconView.mas_bottom).offset(4);
        make.size.equalTo(channelIconView);
        make.bottom.equalTo(self.view).offset(-8);
    }];
    
    CHLabel *nodeTitleLabel = [CHLabel new];
    [self.view addSubview:(_nodeTitleLabel = nodeTitleLabel)];
    [nodeTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(channelTitleLabel);
        make.centerY.equalTo(nodeIconView);
    }];
    nodeTitleLabel.font = theme.detailFont;
    nodeTitleLabel.textColor = theme.minorLabelColor;
    nodeTitleLabel.numberOfLines = 1;
    
    CHLabel *expriedDateLabel = [CHLabel new];
    [self.view addSubview:(_expriedDateLabel = expriedDateLabel)];
    [expriedDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(nodeTitleLabel.mas_right).offset(4);
        make.right.equalTo(tokenLabel);
        make.bottom.equalTo(nodeTitleLabel);
    }];
    expriedDateLabel.font = theme.smallFont;
    expriedDateLabel.textColor = theme.lightLabelColor;
    expriedDateLabel.numberOfLines = 1;
    
    CHLongPressGestureRecognizer *longPressRecognizer = [[CHLongPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionLongPress:)];
    [self.view addGestureRecognizer:(_longPressRecognizer = longPressRecognizer)];
}

- (void)dealloc {
    if (self.longPressRecognizer != nil) {
        [self.view removeGestureRecognizer:self.longPressRecognizer];
        _longPressRecognizer = nil;
    }
}

- (void)setModel:(CHBlockedModel *)model {
    _model = model;
    self.tokenLabel.text = [CHCodeFormatter.shared formatCode:self.model.raw length:32];
    CHChannelModel *chan = [CHLogic.shared.userDataSource channelWithCID:self.model.channel.base64Code];
    if (chan == nil) {
        self.channelIconView.alpha = 0;
        self.channelTitleLabel.text = @"";
    } else {
        self.channelIconView.alpha = 1;
        self.channelIconView.image = chan.icon;
        self.channelTitleLabel.text = chan.title;
    }
    CHNodeModel *node = [CHLogic.shared.userDataSource nodeWithNID:self.model.nid];
    if (node == nil) {
        self.nodeIconView.alpha = 0;
        self.nodeTitleLabel.text = @"";
    } else {
        self.nodeIconView.alpha = 1;
        self.nodeIconView.image = node.icon;
        self.nodeTitleLabel.text = node.name;
    }
    NSDate *expired = self.model.expired;
    if (expired == nil) {
        self.expriedDateLabel.text = @"";
    } else {
        if ([NSDate.now compare:expired] == NSOrderedDescending) {
            self.expriedDateLabel.textColor = CHTheme.shared.alertColor;
            self.expriedDateLabel.text = @"Expired".localized;
        } else {
            self.expriedDateLabel.textColor = CHTheme.shared.lightLabelColor;
            self.expriedDateLabel.text = [NSString stringWithFormat:@"Expires at %@".localized, expired.fullDayFormat];
        }
    }
}

#pragma mark - Action Methods
- (void)actionLongPress:(CHLongPressGestureRecognizer *)recognizer {
    CHMenuController *menu = CHMenuController.sharedMenuController;
    menu.menuItems = @[
        [[CHMenuItem alloc] initWithTitle:@"Delete".localized action:@selector(actionDelete:)],
    ];
    [menu showMenuFromView:self.view target:self point:[recognizer locationInView:self.view]];
}

- (void)actionDelete:(id)sender {
    @weakify(self);
    [CHRouter.shared showAlertWithTitle:@"Delete this token or not?".localized action:@"Delete".localized handler:^{
        @strongify(self);
        [CHLogic.shared removeBlockedTokens:@[self.model.raw]];
    }];
}


@end
