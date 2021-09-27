//
//  CHRouter+OSX.m
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import "CHRouter+OSX.h"
#import <JLRoutes/JLRoutes.h>
#import <Masonry/Masonry.h>
#import "CHMainViewController.h"
#import "CHLoginViewController.h"
#import "CHChannelViewPage.h"
#import "CHPopoverWindow.h"
#import "CHAboutView.h"
#import "CHToast.h"
#import "CHLogic.h"

typedef NS_ENUM(NSInteger, CHRouterShowMode) {
    CHRouterShowModePush    = 0,
    CHRouterShowModePresent = 1,
    CHRouterShowModeDetail  = 2,
};

#define kMenuLogoutTag  10000

@interface CHRouter () <NSWindowDelegate, NSSharingServicePickerDelegate, NSMenuItemValidation>

@property (nonatomic, readonly, strong) NSStatusItem *statusIcon;
@property (nonatomic, nullable, strong) void (^shareHandler)(BOOL completed, NSError *error);
@property (nonatomic, nullable, weak) NSPanel *aboutPanel;

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
        _shareHandler = nil;
        [self initRouters:JLRoutes.globalRoutes];
        [self loadMainMenu];
    }
    return self;
}

- (void)launch {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:0 backing:NSBackingStoreBuffered defer:NO];
    _window = window;
    window.movableByWindowBackground = YES;
    window.titlebarAppearsTransparent = YES;
    window.delegate = self;
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

- (BOOL)handleURL:(NSURL *)url {
    NSString *target = url.absoluteString;
    NSDictionary *params = nil;
    if ([url.scheme isEqualToString:@"chanify"]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:target];
        if ([url.path isEqualToString:@"/page/channel"]) {
            NSString *cid = [components queryValueForName:@"cid"];
            if (cid.length <= 0) {
                return NO;
            }
            target = url.path;
            params = @{ @"show": @"detail", @"singleton": @YES, @"cid": cid };
        }
    }
    return [self routeTo:target withParams:params];
}

- (BOOL)routeTo:(NSString *)url {
    return [self routeTo:url withParams:nil];
}

- (BOOL)routeTo:(NSString *)url withParams:(nullable NSDictionary<NSString *, id> *)params {
    BOOL res = NO;
    if (CHLogic.shared.me != nil) {
        res = [JLRoutes routeURL:[NSURL URLWithString:url] withParameters:params];
    } else {
        res = [JLRoutes routeURL:[NSURL URLWithString:@"/page/login"]];
    }
    return res;
}

- (void)popToRootViewControllerAnimated:(BOOL)animated {
    NSWindow *window = CHRouter.shared.window;
    if (window.sheets.count > 0) {
        window = window.sheets.lastObject;
        if ([window isKindOfClass:CHPopoverWindow.class]) {
            [window close];
        }
    } else {
        if ([window.contentViewController isKindOfClass:CHMainViewController.class]) {
            [(CHMainViewController *)window.contentViewController restDetailViewController];
        }
    }
}

- (void)showShareItem:(NSArray *)items sender:(id)sender handler:(void (^ __nullable)(BOOL completed, NSError *error))handler {
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:items];
    sharingServicePicker.delegate = self;
    _shareHandler = handler;
    NSView *view = nil;
    if ([sender isKindOfClass:NSView.class]) {
        view = sender;
    } else {
        view = self.window.contentView;
    }
    [sharingServicePicker showRelativeToRect:[view bounds] ofView:view preferredEdge:NSMinXEdge];
}

- (void)showAlertWithTitle:(NSString *)title action:(NSString *)action handler:(void (^ __nullable)(void))handler {
    NSAlert *alert = [NSAlert new];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = title;
    if (action.length <= 0) {
        action = @"OK".localized;
    }
    [alert addButtonWithTitle:@"Cancel".localized];
    [[alert addButtonWithTitle:action] setTag:NSModalResponseOK];

    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK && handler != nil) {
            dispatch_main_async(handler);
        }
    }];
}

- (void)setBadgeText:(NSString *)badgeText {
    NSApp.dockTile.badgeLabel = badgeText;
    self.statusIcon.button.title = badgeText;
}

- (void)pushViewController:(CHPageView *)page animated:(BOOL)animated {
    NSWindow *window = self.window;
    NSWindow *sheet = window.attachedSheet;
    if (sheet != nil) {
        if ([sheet isKindOfClass:CHPopoverWindow.class]) {
            [(CHPopoverWindow *)sheet pushPage:page animate:animated];
        }
    } else {
        if ([window.contentViewController isKindOfClass:CHMainViewController.class]) {
            [(CHMainViewController *)window.contentViewController pushPage:page animate:animated reset:NO];
        }
    }
}

- (void)showIndicator:(BOOL)show {
    
}

- (void)makeToast:(NSString *)message {
    dispatch_main_async(^{
        NSWindow *window = CHRouter.shared.window;
        if (window.sheets.count > 0) {
            window = window.sheets.lastObject;
        }
        [CHToast showMessage:message inView:window.contentView];
    });
}

#pragma mark - NSWindowDelegate
- (BOOL)windowShouldClose:(NSWindow *)window {
    [self.aboutPanel close];
    [window orderOut:self];
    return NO;
}

#pragma mark - NSSharingServicePickerDelegate
- (void)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker didChooseSharingService:(nullable NSSharingService *)service {
    if (_shareHandler != nil) {
        _shareHandler(YES, nil);
        _shareHandler = nil;
    }
}

#pragma mark - NSMenuItemValidation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.tag == kMenuLogoutTag) {
        return (CHLogic.shared.me != nil);
    }
    return YES;
}

#pragma mark - Action Methods
- (void)actionShow:(id)sender {
    if (NSApp.keyWindow == nil) {
        [self.window makeKeyAndOrderFront:NSApp];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)actionAbout:(id)sender {
    if (self.aboutPanel == nil) {
        NSPanel *aboutPanel = [NSPanel new];
        aboutPanel.movableByWindowBackground = YES;
        aboutPanel.titlebarAppearsTransparent = YES;
        aboutPanel.contentView = [CHAboutView new];
        _aboutPanel = aboutPanel;
    }
    NSRect frame = NSMakeRect(0, 0, 480, 220);
    NSRect wndFrame = self.window.frame;
    frame.origin.x = wndFrame.origin.x + (wndFrame.size.width - frame.size.width)/2.0;
    frame.origin.y = wndFrame.origin.y + (wndFrame.size.height - frame.size.height)/2.0;
    [self.aboutPanel setFrame:frame display:YES animate:NO];
    [self.aboutPanel orderFrontRegardless];
}

- (void)actionPreferences:(id)sender {
}

- (void)actionLogout:(id)sender {
    [CHLogic.shared logoutWithCompletion:^(CHLCode result) {
        if (result == CHLCodeOK) {
            [CHRouter.shared routeTo:@"/page/main"];
        }
    }];
}

#pragma mark - Private Methods
- (void)initRouters:(JLRoutes *)routes {
    [routes addRoute:@"/page/main" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        NSWindow *window = CHRouter.shared.window;
        if (![window.contentViewController isKindOfClass:CHMainViewController.class]) {
            window.styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable|NSWindowStyleMaskFullSizeContentView;
            window.minSize = CGSizeMake(640, 480);
            window.contentViewController = [CHMainViewController new];
            showWindowWithSize(window, NSMakeSize(800, 600));
        }
        return YES;
    }];
    [routes addRoute:@"/page/login" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        NSWindow *window = CHRouter.shared.window;
        if (![window.contentViewController isKindOfClass:CHLoginViewController.class]) {
            window.styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable;
            window.contentViewController = [CHLoginViewController new];
            showWindowWithSize(window, NSMakeSize(300, 400));
        }
        showDetailPage(CHChannelViewPage.class, parameters, YES);
        return YES;
    }];
    [routes addRoute:@"/page/:name(/:subname)" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        BOOL res = NO;
        NSString *name = [parameters valueForKey:@"name"];
        NSString *subname = [parameters valueForKey:@"subname"];
        if (subname.length > 0) {
            name = [name stringByAppendingString:subname.code];
        }
        if (name.length > 0) {
            Class clz = NSClassFromString([NSString stringWithFormat:@"CH%@ViewPage", name.code]);
            if ([clz isSubclassOfClass:CHPageView.class]) {
                res = showShowPage(clz, parameters);
            }
        }
        return res;
    }];
    // unmatched router
    routes.unmatchedURLHandler = ^(JLRoutes *routes, NSURL *url, NSDictionary<NSString *, id> *parameters) {
        if (url != nil) {
            [NSWorkspace.sharedWorkspace openURL:url];
        }
    };
}

- (void)loadMainMenu {
    NSStatusItem *statusIcon = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    _statusIcon = statusIcon;
    statusIcon.button.image = [NSImage imageNamed:@"StatusIcon"];
    statusIcon.button.imagePosition = NSImageLeft;
    statusIcon.button.target = self;
    statusIcon.button.action = @selector(actionShow:);

    NSMenu *mainMenu = [NSMenu new];
    NSMenuItem *appMenu = [[NSMenuItem alloc] initWithTitle:@"Chanify" action:nil keyEquivalent:@""];
    [mainMenu addItem:appMenu];
    NSMenu *menu = [NSMenu new];
    appMenu.submenu = menu;
    [menu addItem:CreateMenuItem(@"About Chanify", self, @selector(actionAbout:), @"i")];
    [menu addItem:NSMenuItem.separatorItem];
//    [menu addItem:CreateMenuItem(@"Preferences", self, @selector(actionPreferences:), @",")];
//    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *logoutItem = CreateMenuItem(@"Logout", self, @selector(actionLogout:), @"o");
    logoutItem.tag = kMenuLogoutTag;
    [menu addItem:logoutItem];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItem:CreateMenuItem(@"Quit Chanify", NSApp, @selector(terminate:), @"q")];
    NSApp.mainMenu = mainMenu;
}

static inline NSMenuItem *CreateMenuItem(NSString *title, id target, SEL action, NSString *key) {
    NSMenuItem *menu = [[NSMenuItem alloc] initWithTitle:title.localized action:action keyEquivalent:key];
    [menu setTarget:target];
    return menu;
}

static inline CHPageView *loadPage(Class clz, NSDictionary<NSString *, id> *parameters) {
    id page = [clz alloc];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"initWithParameters:");
    if ([page respondsToSelector:selector]) {
        page = [page performSelector:selector withObject:parameters];
    } else {
        page = [page init];
    }
#pragma clang diagnostic pop
    return page;
}

static inline BOOL showDetailPage(Class clz, NSDictionary<NSString *, id> *parameters, BOOL isPushed) {
    NSWindow *window = CHRouter.shared.window;
    if ([window.contentViewController isKindOfClass:CHMainViewController.class]) {
        CHMainViewController *vc = (CHMainViewController *)window.contentViewController;
        CHPageView *contentView = vc.topContentView;
        if (![contentView isKindOfClass:clz] || ![contentView isEqualWithParameters:parameters]) {
            [vc pushPage:loadPage(clz, parameters) animate:YES reset:!isPushed];
        }
    }
    return YES;
}

static inline BOOL showShowPage(Class clz, NSDictionary<NSString *, id> *parameters) {
    CHRouterShowMode mode = parseShowMode([parameters valueForKey:@"show"]);
    if (mode == CHRouterShowModePresent) {
        dispatch_main_async(^{
            CHPopoverWindow *window = [CHPopoverWindow windowWithPage:loadPage(clz, parameters)];
            [CHRouter.shared.window beginSheet:window completionHandler:^(NSModalResponse returnCode) {
            }];
        });
        return YES;
    }
    return showDetailPage(clz, parameters, mode == CHRouterShowModePush);
}

static inline void showWindowWithSize(NSWindow *window, NSSize size) {
    for (NSWindow *sheet in window.sheets) {
        [window endSheet:sheet];
    }
    NSRect frame = window.screen.frame;
    if (NSIsEmptyRect(frame)) {
        frame = NSScreen.mainScreen.frame;
    }
    [window setFrame:NSMakeRect((frame.size.width - size.width)/2.0, (frame.size.height - size.height)/2.0, size.width, size.height) display:YES animate:YES];
}

static inline CHRouterShowMode parseShowMode(NSString *show) {
    CHRouterShowMode mode = CHRouterShowModePush;
    if (show.length > 0) {
        if ([show isEqualToString:@"present"]) {
            mode = CHRouterShowModePresent;
        } else if ([show isEqualToString:@"detail"]) {
            mode = CHRouterShowModeDetail;
        }
    }
    return mode;
}


@end
