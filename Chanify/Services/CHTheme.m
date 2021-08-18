//
//  CHTheme.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHTheme.h"
#if TARGET_OS_OSX
#   import "CHRouter+OSX.h"
#else
#   import "CHRouter+iOS.h"
#endif

#define kCHUIStyleKey   "uistyle"

@implementation CHTheme

+ (instancetype)shared {
    static CHTheme *theme;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theme = [CHTheme new];
    });
    return theme;
}

- (instancetype)init {
    if (self = [super init]) {
        _tintColor = [CHColor colorNamed:@"AccentColor"];
        _lightTintColor = [self.tintColor colorWithAlphaComponent:0.6];
        _labelColor = CHColor.labelColor;
        _minorLabelColor = CHColor.secondaryLabelColor;
        _lightLabelColor = CHColor.tertiaryLabelColor;
        _warnColor = CHColor.systemYellowColor;
        _alertColor = CHColor.systemRedColor;
        _secureColor = CHColor.systemGreenColor;
        _backgroundColor = CHColor.systemBackgroundColor;
        _groupedBackgroundColor = CHColor.systemGroupedBackgroundColor;
        _bubbleBackgroundColor = [CHColor colorNamed:@"BubbleColor"];

        _clearImage = [CHImage new];
        _backImage = [CHImage systemImageNamed:@"chevron.backward"];

#if TARGET_OS_OSX
        _cellBackgroundColor = [CHColor colorNamed:@"CellColor"];
        _selectedCellBackgroundColor = [CHColor colorNamed:@"SelectedCellColor"];
        _textFont = [CHFont systemFontOfSize:15 weight:NSFontWeightLight];
        _mediumFont = [CHFont systemFontOfSize:12 weight:NSFontWeightLight];
        _smallFont = [CHFont systemFontOfSize:8 weight:NSFontWeightLight];
        _detailFont = [CHFont systemFontOfSize:10 weight:NSFontWeightLight];
        _messageTextFont = [CHFont systemFontOfSize:15 weight:NSFontWeightLight];
        _messageTitleFont = [CHFont systemFontOfSize:15];
        _messageMediumFont = [CHFont systemFontOfSize:12 weight:NSFontWeightLight];
        _messageSmallFont = [CHFont systemFontOfSize:10 weight:NSFontWeightLight];
        _messageSmallDigitalFont = [CHFont monospacedSystemFontOfSize:8 weight:NSFontWeightLight];

        [NSApp addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:nil];
#else
        _cellBackgroundColor = UIBackgroundConfiguration.listGroupedCellConfiguration.backgroundColor;
        _textFont = [CHFont systemFontOfSize:16];
        _mediumFont = [CHFont systemFontOfSize:14];
        _smallFont =  [CHFont systemFontOfSize:10];
        _detailFont = [CHFont systemFontOfSize:12];
        _messageTextFont = [CHFont systemFontOfSize:16];
        _messageTitleFont = [CHFont boldSystemFontOfSize:16];
        _messageMediumFont = [CHFont systemFontOfSize:14];
        _messageSmallFont = [CHFont systemFontOfSize:12];
        _messageSmallDigitalFont = [CHFont monospacedSystemFontOfSize:8 weight:UIFontWeightRegular];

        // Appearance
        UINavigationBar *navigationBar = UINavigationBar.appearance;
        navigationBar.shadowImage = self.clearImage;
        navigationBar.tintColor = self.labelColor;
        navigationBar.barTintColor = self.backgroundColor;
        navigationBar.backgroundColor = self.backgroundColor;
        navigationBar.backIndicatorImage = self.backImage;
        navigationBar.backIndicatorTransitionMaskImage = self.backImage;

        UITabBar *tabBar = UITabBar.appearance;
        tabBar.tintColor = self.tintColor;
        tabBar.barTintColor = self.backgroundColor;
        tabBar.backgroundColor = self.backgroundColor;
        tabBar.backgroundImage = self.clearImage;
        tabBar.shadowImage = self.clearImage;

        UITabBarItem *tabBarItem = UITabBarItem.appearance;
        [tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: self.tintColor } forState:UIControlStateSelected];
        [tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: self.minorLabelColor } forState:UIControlStateNormal];
        [tabBarItem setBadgeTextAttributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:10] } forState:UIControlStateNormal];

        UISwitch.appearance.onTintColor = self.tintColor;
        UIProgressView.appearance.tintColor = self.tintColor;
        
        self.userInterfaceStyle = [NSUserDefaults.standardUserDefaults integerForKey:@kCHUIStyleKey];
#endif
    }
    return self;
}

#if TARGET_OS_OSX

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"effectiveAppearance"]) {
        [NSAppearance setCurrentAppearance:NSApp.effectiveAppearance];
    }
}

#else

- (UIUserInterfaceStyle)userInterfaceStyle API_AVAILABLE(ios(13.0)) {
    return CHRouter.shared.window.overrideUserInterfaceStyle;
}

- (void)setUserInterfaceStyle:(UIUserInterfaceStyle)userInterfaceStyle API_AVAILABLE(ios(13.0)) {
    if (userInterfaceStyle != self.userInterfaceStyle) {
        CHRouter.shared.window.overrideUserInterfaceStyle = userInterfaceStyle;
        [NSUserDefaults.standardUserDefaults setInteger:userInterfaceStyle forKey:@kCHUIStyleKey];
    }
}

#endif

@end
