//
//  CHTheme.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHTheme.h"
#import "CHRouter.h"

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
        _tintColor = [UIColor colorNamed:@"AccentColor"];
        _lightTintColor = [self.tintColor colorWithAlphaComponent:0.6];
        _labelColor = UIColor.labelColor;
        _minorLabelColor = UIColor.secondaryLabelColor;
        _lightLabelColor = UIColor.tertiaryLabelColor;
        _warnColor = UIColor.systemYellowColor;
        _alertColor = UIColor.systemRedColor;
        _secureColor = UIColor.systemGreenColor;
        _backgroundColor = UIColor.systemBackgroundColor;
        _cellBackgroundColor = UIBackgroundConfiguration.listGroupedCellConfiguration.backgroundColor;
        _bubbleBackgroundColor = [UIColor colorNamed:@"BubbleColor"];
        _groupedBackgroundColor = UIColor.systemGroupedBackgroundColor;
        
        _clearImage = [UIImage new];
        _backImage = [UIImage systemImageNamed:@"chevron.backward"];
        
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

        UISwitch.appearance.onTintColor = self.tintColor;
        UIProgressView.appearance.tintColor = self.tintColor;
        
        self.userInterfaceStyle = [NSUserDefaults.standardUserDefaults integerForKey:@kCHUIStyleKey];
    }
    return self;
}

- (UIUserInterfaceStyle)userInterfaceStyle API_AVAILABLE(ios(13.0)) {
    return CHRouter.shared.window.overrideUserInterfaceStyle;
}

- (void)setUserInterfaceStyle:(UIUserInterfaceStyle)userInterfaceStyle API_AVAILABLE(ios(13.0)) {
    if (userInterfaceStyle != self.userInterfaceStyle) {
        CHRouter.shared.window.overrideUserInterfaceStyle = userInterfaceStyle;
        [NSUserDefaults.standardUserDefaults setInteger:userInterfaceStyle forKey:@kCHUIStyleKey];
    }
}


@end
