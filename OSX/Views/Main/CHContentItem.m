//
//  CHContentItem.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHContentItem.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHContentItem ()

@property (nonatomic, readonly, strong) CHImageView *iconView;
@property (nonatomic, readonly, strong) CHLabel *titleView;
@property (nonatomic, readonly, strong) Class clz;
@property (nonatomic, nullable, strong) CHSideBarView *sideBarView;
@property (nonatomic, nullable, strong) CHContentView *contentView;

@end

@implementation CHContentItem

+ (instancetype)itemWithTitle:(NSString *)title image:(NSString *)icon clz:(Class)clz {
    return [[CHContentItem alloc] initWithTitle:title image:icon clz:clz];
}

- (instancetype)initWithTitle:(NSString *)title image:(NSString *)icon clz:(Class)clz {
    if (self = [super initWithFrame:NSZeroRect]) {
        CHTheme *theme = CHTheme.shared;
        
        _clz = clz;
        _selected = NO;
        _sideBarView = nil;

        CHLabel *titleView = [CHLabel new];
        [self addSubview:(_titleView = titleView)];
        [titleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self);
            make.left.right.equalTo(self);
            make.height.mas_equalTo(10);
        }];
        titleView.alignment = NSTextAlignmentCenter;
        titleView.font = [CHFont systemFontOfSize:8 weight:NSFontWeightRegular];
        titleView.textColor = theme.minorLabelColor;
        titleView.text = title.localized;

        CHImageView *iconView = [[CHImageView alloc] initWithImage:[CHImage imageNamed:icon]];
        [self addSubview:(_iconView = iconView)];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.bottom.equalTo(titleView.mas_top);
        }];
        iconView.tintColor = theme.minorLabelColor;
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    if (_selected != selected) {
        _selected = selected;
        CHTheme *theme = CHTheme.shared;
        if (selected) {
            self.titleView.textColor = theme.tintColor;
            self.iconView.tintColor = theme.tintColor;
        } else {
            self.titleView.textColor = theme.minorLabelColor;
            self.iconView.tintColor = theme.minorLabelColor;
        }
    }
}

- (nullable CHSideBarView *)sidebarView {
    if (_sideBarView != nil) {
        return _sideBarView;
    }
    if ([self.clz isSubclassOfClass:CHSideBarView.class]) {
        return (_sideBarView = [self.clz new]);
    }
    return nil;
}

- (nullable CHContentView *)contentView {
    if (_contentView == nil) {
        _contentView = [CHContentView new];
    }
    return _contentView;
}


@end
