//
//  CHRouter+OSX.m
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import "CHRouter+OSX.h"
#import <JLRoutes/JLRoutes.h>
#import "CHMainViewController.h"
#import "CHChannelView.h"
#import "CHLogic+OSX.h"

@interface CHRouter () <NSWindowDelegate>

@property (nonatomic, readonly, strong) NSStatusItem *statusIcon;

@end

@implementation CHRouter

+ (instancetype)shared {
    static CHRouter *router;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        router = [CHRouter new];
    });
    return router;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initRouters:JLRoutes.globalRoutes];
        [self loadMainMenu];
    }
    return self;
}

- (void)launch {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    _window = window;
    window.movableByWindowBackground = YES;
    window.titlebarAppearsTransparent = YES;
    window.delegate = self;
    window.styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable;
    window.hasShadow = YES;

    [CHLogic.shared launch];
    [CHLogic.shared active];
    
    [self routeTo:@"/page/main"];
    
    [window center];
    [window makeKeyAndOrderFront:NSApp];
}

- (void)close {
    [NSStatusBar.systemStatusBar removeStatusItem:self.statusIcon];
    [CHLogic.shared deactive];
    [CHLogic.shared close];
}

- (void)handleReopen:(id)sender {
    [self actionShow:self];
}

- (BOOL)routeTo:(NSString *)url {
    return [self routeTo:url withParams:nil];
}

- (BOOL)routeTo:(NSString *)url withParams:(nullable NSDictionary<NSString *, id> *)params {
    return [JLRoutes routeURL:[NSURL URLWithString:url] withParameters:params];
}

#pragma mark - NSWindowDelegate
- (BOOL)windowShouldClose:(NSWindow *)window {
    [window orderOut:self];
    return NO;
}

#pragma mark - Action Methods
- (void)actionShow:(id)sender {
    if (NSApp.keyWindow == nil) {
        [self.window makeKeyAndOrderFront:NSApp];
    }
}

- (void)actionAbout:(id)sender {

}

- (void)actionPreferences:(id)sender {
    
}

#pragma mark - Private Methods
- (void)initRouters:(JLRoutes *)routes {
    [routes addRoute:@"/page/main" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        NSWindow *window = CHRouter.shared.window;
        if (![window.contentViewController isKindOfClass:CHMainViewController.class]) {
            window.minSize = CGSizeMake(640, 480);
            window.contentViewController = [CHMainViewController new];
            [window setFrame:NSMakeRect(0, 0, 800, 600) display:YES animate:YES];
        }
        return YES;
    }];
    [routes addRoute:@"/page/channel" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        NSWindow *window = CHRouter.shared.window;
        if ([window.contentViewController isKindOfClass:CHMainViewController.class]) {
            NSString *cid = [parameters valueForKey:@"cid"];
            CHMainViewController *vc = (CHMainViewController *)window.contentViewController;
            NSView *contentView = vc.topContentView;
            if (!([contentView isKindOfClass:CHChannelView.class] && [cid isEqualTo:[(CHChannelView *)vc.topContentView cid]])) {
                [vc pushContentView:[[CHChannelView alloc] initWithCID:cid]];
            }
        }
        return YES;
    }];
}

- (void)loadMainMenu {
    NSStatusItem *statusIcon = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    _statusIcon = statusIcon;
    NSImage *icon = [NSImage imageNamed:@"StatusIcon"];
    icon.template = YES;
    statusIcon.button.image = icon;
    statusIcon.button.target = self;
    statusIcon.button.action = @selector(actionShow:);

    NSMenu *mainMenu = [NSMenu new];
    NSMenuItem *appMenu = [[NSMenuItem alloc] initWithTitle:@"Chanify" action:nil keyEquivalent:@""];
    [mainMenu addItem:appMenu];
    NSMenu *menu = [NSMenu new];
    appMenu.submenu = menu;
    [menu addItem:CreateMenuItem(@"About Chanify", self, @selector(actionAbout:), @"i")];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItem:CreateMenuItem(@"Preferences", self, @selector(actionPreferences:), @",")];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItem:CreateMenuItem(@"Quit Chanify", NSApp, @selector(terminate:), @"q")];
    NSApp.mainMenu = mainMenu;
}

static inline NSMenuItem *CreateMenuItem(NSString *title, id target, SEL action, NSString *key) {
    NSMenuItem *menu = [[NSMenuItem alloc] initWithTitle:title.localized action:action keyEquivalent:key];
    [menu setTarget:target];
    return menu;
}


@end
