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
#import "CHPreviewItem.h"
#import "CHWebViewPage.h"
#import "CHAboutView.h"
#import "CHPasteboard.h"
#import "CHDevice.h"
#import "CHToast.h"
#import "CHLogic.h"
#import "CHToken.h"

#define kCHUIMainWndSizeKey     "ui.mainwnd.size"
#define kCHUIMainWndWidth       640
#define kCHUIMainWndHeight      480

typedef NS_ENUM(NSInteger, CHRouterShowMode) {
    CHRouterShowModePush    = 0,
    CHRouterShowModePresent = 1,
    CHRouterShowModeDetail  = 2,
};

#define kMenuLogoutTag      10000
#define kMenuOpenWindowTag  20000
#define kMenuCloseWindowTag 20001

@interface CHRouter () <NSWindowDelegate, NSSharingServicePickerDelegate, NSMenuDelegate, NSMenuItemValidation, QLPreviewPanelDataSource>

@property (nonatomic, readonly, strong) NSStatusItem *statusIcon;
@property (nonatomic, nullable, strong) void (^shareHandler)(BOOL completed, NSError *error);
@property (nonatomic, nullable, weak) NSPanel *aboutPanel;
@property (nonatomic, nullable, strong) id<QLPreviewItem> previewItem;

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
        _previewItem = nil;
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
    [self saveMainWindowFrame];
}

- (BOOL)canSendMail {
    return YES;
}

- (BOOL)handleReopen:(id)sender hasVisibleWindows:(BOOL)flag {
    [self actionShow:self];
    return YES;
}

- (BOOL)handleURL:(NSURL *)url {
    NSString *target = url.absoluteString;
    NSDictionary *params = nil;
    if ([url.scheme isEqualToString:@"chanify"]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:target];
        NSString *path = [NSString stringWithFormat:@"/%@%@", url.host, url.path];
        if ([path isEqualToString:@"/page/channel"]) {
            NSString *cid = [components queryValueForName:@"cid"];
            if (cid.length <= 0) {
                return NO;
            }
            target = path;
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
    if ([[params valueForKey:@"noauth"] boolValue] || CHLogic.shared.me != nil) {
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
    [self showAlertWithTitle:nil message:title action:action handler:handler];
}

- (void)showAlertWithTitle:(nullable NSString *)title message:(NSString *)message action:(nullable NSString *)action  handler:(void (^ __nullable)(void))handler {
    NSAlert *alert = [NSAlert new];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = message;
    if (title.length > 0) {
        alert.informativeText = title;
    }
    if (action.length <= 0) {
        action = @"OK".localized;
    }
    if (handler != nil) {
        [alert addButtonWithTitle:@"Cancel".localized];
    }
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

- (void)showPreviewPanel:(CHPreviewItem *)item {
    [self showPreviewItemPanel:item];
}

- (void)showIndicator:(BOOL)show {
    
}

- (void)makeToast:(NSString *)message {
    [self makeToast:message color:nil];
}

- (void)makeToast:(NSString *)message color:(nullable CHColor *)color {
    if (message.length > 0) {
        dispatch_main_async(^{
            NSWindow *window = CHRouter.shared.window;
            if (window.sheets.count > 0) {
                window = window.sheets.lastObject;
            }
            [CHToast showMessage:message color:color inView:window.contentView];
        });
    }
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

#pragma mark - NSMenuDelegate
- (void)menuWillOpen:(NSMenu *)menu {
    for (NSMenuItem *item in menu.itemArray) {
        item.enabled = [self validateMenuItem:item];
    }
}

#pragma mark - NSMenuItemValidation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    switch (menuItem.tag) {
        case kMenuLogoutTag:
            return (CHLogic.shared.me != nil);
        case kMenuOpenWindowTag:
            return (NSApp.keyWindow == nil);
        case kMenuCloseWindowTag:
            return (NSApp.keyWindow != nil);
    }
    return YES;
}

#pragma mark - QLPreviewPanelDataSource
- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return (self.previewItem == nil ? 0 : 1);
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    return self.previewItem;
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
    [CHRouter.shared routeTo:@"/action/logout"];
}

- (void)actionToggleWindow:(id)sender {
    if (NSApp.keyWindow == nil) {
        [self actionShow:sender];
    } else {
        [self.window orderOut:nil];
    }
}

- (void)actionOpenHelp:(id)sender {
    [CHRouter.shared routeTo:@kUsageManualURL];
}

#pragma mark - QLPreviewPanelController
- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    panel.dataSource = nil;
}

#pragma mark - Private Methods
- (void)initRouters:(JLRoutes *)routes {
    [routes addRoute:@"/page/main" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        NSWindow *window = CHRouter.shared.window;
        if (![window.contentViewController isKindOfClass:CHMainViewController.class]) {
            window.styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable|NSWindowStyleMaskFullSizeContentView;
            window.minSize = CGSizeMake(kCHUIMainWndWidth, kCHUIMainWndHeight);
            window.contentViewController = [CHMainViewController new];
            showWindowWithFrame(window, [self loadMainWindowFrame]);
        }
        return YES;
    }];
    [routes addRoute:@"/page/login" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        NSWindow *window = CHRouter.shared.window;
        if (![window.contentViewController isKindOfClass:CHLoginViewController.class]) {
            window.styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable;
            window.contentViewController = [CHLoginViewController new];
            showWindowWithFrame(window, NSMakeRect(0, 0, 300, 400));
        }
        showDetailPage(CHChannelViewPage.class, parameters, YES);
        return YES;
    }];
    [routes addRoute:@"/page/:_name(/:_subname)" handler:^BOOL(NSDictionary<NSString *, id> *parameters) {
        BOOL res = NO;
        NSString *name = [parameters valueForKey:@"_name"];
        NSString *subname = [parameters valueForKey:@"_subname"];
        if (subname.length > 0) {
            name = [name stringByAppendingString:subname.code];
        }
        if (name.length > 0) {
            Class clz = NSClassFromString([NSString stringWithFormat:@"CH%@ViewPage", name.code]);
            if (clz == nil) {
                clz = NSClassFromString([NSString stringWithFormat:@"CH%@ViewController", name.code]);
            }
            if ([clz isSubclassOfClass:CHPageView.class]) {
                res = showViewPage(clz, parameters);
            }
        }
        return res;
    }];
    [routes addRoute:@"/action/logout" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        [CHRouter.shared showAlertWithTitle:@"Logout or not?".localized action:@"OK".localized handler:^{
            [CHRouter.shared showIndicator:YES];
            [CHLogic.shared logoutWithCompletion:^(CHLCode result) {
                [CHRouter.shared showIndicator:NO];
                if (result == CHLCodeOK) {
                    [CHRouter.shared routeTo:@"/page/main"];
                } else {
                    [CHRouter.shared makeToast:@"Logout failed".localized];
                }
            }];
        }];
        return YES;
    }];
    [routes addRoute:@"/action/openweb" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        BOOL res = NO;
        NSURL *url = parseURL([parameters valueForKey:@"url"]);
        if (url != nil) {
            res = showViewPage(CHWebViewPage.class, [parameters dictionaryWithValue:url forKey:@"url"]);
        }
        return res;
    }];
    [routes addRoute:@"/action/openurl" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        BOOL res = NO;
        NSURL *url = parseURL([parameters valueForKey:@"url"]);
        if (url != nil) {
            [NSWorkspace.sharedWorkspace openURL:url];
            res = YES;
        }
        return res;
    }];
    [routes addRoute:@"/action/previewfile" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        BOOL res = NO;
        NSURL *url = parseURL([parameters valueForKey:@"url"]);
        if (url != nil) {
            [CHRouter.shared showPreviewItemPanel:url];
            res = YES;
        }
        return res;
    }];
    [routes addRoute:@"/action/sendemail" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        BOOL res = NO;
        NSString *email = [parameters valueForKey:@"email"];
        if (email.length > 0) {
            NSString *title = @"Feedback".localized;
            NSString *subject = [[NSString stringWithFormat:@"[%@] %@", CHDevice.shared.app, title] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
            NSString *url = [NSString stringWithFormat:@"mailto:%@?subject=%@", email, subject];
            res = [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:url]];
        }
        return res;
    }];
    // chanify router
    JLRoutes *chanify = [JLRoutes routesForScheme:@"chanify"];
    [chanify addRoute:@"/action/token/default" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        [CHPasteboard.shared copyWithName:@"Token".localized value:[CHToken.defaultToken formatString:nil direct:YES]];
        return YES;
    }];
    [chanify addRoute:@"/action/pasteboard" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        NSString *text = [NSString stringWithFormat:@"%@", [parameters valueForKey:@"text"]];
        [CHPasteboard.shared copyWithName:@"Custom Value".localized value:text];
        return YES;
    }];
    [chanify addRoute:@"/action/show-alert(/:message)" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        NSString *title = [parameters valueForKey:@"title"];
        NSString *message = [parameters valueForKey:@"message"];
        if (message.length > 0) {
            [CHRouter.shared showAlertWithTitle:title message:message action:nil handler:nil];
        }
        return YES;
    }];
    [chanify addRoute:@"/action/show-toast(/:message)" handler:^BOOL(NSDictionary<NSString *,id> *parameters) {
        NSString *message = [parameters valueForKey:@"message"];
        if (message.length > 0) {
            [CHRouter.shared makeToast:message];
        }
        return YES;
    }];
    chanify.unmatchedURLHandler = ^(JLRoutes * _Nonnull routes, NSURL * _Nullable URL, NSDictionary<NSString *,id> * _Nullable parameters) {
        [CHRouter.shared makeToast:@"Can't open url".localized];
    };
    // unmatched router
    routes.unmatchedURLHandler = ^(JLRoutes *routes, NSURL *url, NSDictionary<NSString *, id> *parameters) {
        if (url != nil) {
            [NSWorkspace.sharedWorkspace openURL:url];
        }
    };
}

- (void)saveMainWindowFrame {
    NSWindow *window = CHRouter.shared.window;
    if ([window.contentViewController isKindOfClass:CHMainViewController.class]) {
        NSRect frame = window.frame;
        frame.size.width = MAX(kCHUIMainWndWidth, frame.size.width);
        frame.size.height = MAX(kCHUIMainWndHeight, frame.size.height);
        [NSUserDefaults.standardUserDefaults setValue:NSStringFromRect(frame) forKey:@kCHUIMainWndSizeKey];
    }
}

- (NSRect)loadMainWindowFrame {
    NSRect frame = NSZeroRect;
    id value = [NSUserDefaults.standardUserDefaults valueForKey:@kCHUIMainWndSizeKey];
    if ([value isKindOfClass:NSString.class]) {
        frame = NSRectFromString(value);
    }
    if (frame.size.width == 0) {
        frame.size.width = 800;
    }
    if (frame.size.height == 0) {
        frame.size.height = 600;
    }
    frame.size.width = MAX(kCHUIMainWndWidth, frame.size.width);
    frame.size.height = MAX(kCHUIMainWndHeight, frame.size.height);
    return frame;
}

- (void)loadMainMenu {
    NSStatusItem *statusIcon = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    _statusIcon = statusIcon;
    statusIcon.button.image = [NSImage imageNamed:@"StatusIcon"];
    statusIcon.button.imagePosition = NSImageLeft;
    statusIcon.button.target = self;
    statusIcon.button.action = @selector(actionShow:);

    // Main menu
    NSMenu *mainMenu = [NSMenu new];
    NSMenuItem *appMenu = [[NSMenuItem alloc] initWithTitle:@"Chanify" action:nil keyEquivalent:@""];
    [mainMenu addItem:appMenu];
    NSMenu *menu = [NSMenu new];
    appMenu.submenu = menu;
    [menu addItem:CreateMenuItem(@"About Chanify", self, @selector(actionAbout:), @"i")];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItem:CreateMenuItemWithTag(@"Logout", self, @selector(actionLogout:), @"o", kMenuLogoutTag)];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItem:CreateMenuItem(@"Quit Chanify", NSApp, @selector(terminate:), @"q")];

    // File menu
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File".localized];
    fileMenu.autoenablesItems = NO;
    fileMenu.delegate = self;
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] initWithTitle:@"File".localized action:nil keyEquivalent:@""];
    [mainMenu addItem:fileMenuItem];
    fileMenuItem.submenu = fileMenu;
    [fileMenu addItem:CreateMenuItemWithTag(@"Open Window", self, @selector(actionToggleWindow:), @"", kMenuOpenWindowTag)];
    [fileMenu addItem:NSMenuItem.separatorItem];
    [fileMenu addItem:CreateMenuItemWithTag(@"Close Window", self, @selector(actionToggleWindow:), @"", kMenuCloseWindowTag)];

    // Edit menu
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit".localized];
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit".localized action:nil keyEquivalent:@""];
    [mainMenu addItem:editMenuItem];
    editMenuItem.submenu = editMenu;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
#pragma clang diagnostic pop
    [editMenu addItem:NSMenuItem.separatorItem];
    [editMenu addItemWithTitle:@"Cut".localized action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy".localized action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste".localized action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItem:NSMenuItem.separatorItem];
    [editMenu addItemWithTitle:@"Select All".localized action:@selector(selectAll:) keyEquivalent:@"a"];
    
    // Window menu
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window".localized];
    NSApp.windowsMenu = windowMenu;
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] initWithTitle:@"Window".localized action:nil keyEquivalent:@""];
    [mainMenu addItem:windowMenuItem];
    windowMenuItem.submenu = windowMenu;
    [windowMenu addItem:NSMenuItem.separatorItem];
    NSMenuItem *windowItem = CreateMenuItem(@"Chanify", self, @selector(actionToggleWindow:), @"");
    windowItem.state = NSControlStateValueOn;
    [windowMenu addItem:windowItem];

    // Help menu
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help".localized];
    NSApp.helpMenu = helpMenu;
    NSMenuItem *helpMenuItem = [[NSMenuItem alloc] initWithTitle:@"Help".localized action:nil keyEquivalent:@""];
    [mainMenu addItem:helpMenuItem];
    [helpMenu addItem:CreateMenuItem(@"Usage Manual", self, @selector(actionOpenHelp:), @"")];
    helpMenuItem.submenu = helpMenu;
    
    NSApp.mainMenu = mainMenu;
}

- (void)showPreviewItemPanel:(nullable id<QLPreviewItem>)item {
    _previewItem = item;
    if (item != nil) {
        QLPreviewPanel *panel = QLPreviewPanel.sharedPreviewPanel;
        if (QLPreviewPanel.sharedPreviewPanelExists && panel.isVisible) {
            [panel orderOut:nil];
        } else {
            [panel makeKeyAndOrderFront:nil];
            [panel reloadData];
        }
    }
}

static inline NSMenuItem *CreateMenuItem(NSString *title, id target, SEL action, NSString *key) {
    NSMenuItem *menu = [[NSMenuItem alloc] initWithTitle:title.localized action:action keyEquivalent:key];
    [menu setTarget:target];
    return menu;
}

static inline NSMenuItem *CreateMenuItemWithTag(NSString *title, id target, SEL action, NSString *key, NSInteger tag) {
    NSMenuItem *menu = CreateMenuItem(title, target, action, key);
    [menu setTag:tag];
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

static inline BOOL showViewPage(Class clz, NSDictionary<NSString *, id> *parameters) {
    CHRouterShowMode mode = parseShowMode([parameters valueForKey:@"show"]);
    if (mode == CHRouterShowModePresent) {
        dispatch_main_async(^{
            CHPopoverWindow *window = [CHPopoverWindow windowWithPage:loadPage(clz, parameters)];
            [CHRouter.shared.window beginSheet:window completionHandler:^(NSModalResponse returnCode) {
                [NSApp endSheet:window];
            }];
        });
        return YES;
    }
    return showDetailPage(clz, parameters, mode == CHRouterShowModePush);
}

static inline void showWindowWithFrame(NSWindow *window, NSRect wndFrame) {
    for (NSWindow *sheet in window.sheets) {
        [window endSheet:sheet];
    }
    NSRect frame = window.screen.frame;
    if (NSIsEmptyRect(frame)) {
        frame = NSScreen.mainScreen.frame;
    }
    if (wndFrame.origin.x == 0) {
        wndFrame.origin.x = (frame.size.width - wndFrame.size.width)/2.0;
    }
    if (wndFrame.origin.y == 0) {
        wndFrame.origin.y = (frame.size.height - wndFrame.size.height)/2.0;
    }
    [window setFrame:wndFrame display:YES animate:YES];
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

static inline NSURL *parseURL(id u) {
    NSURL *url = nil;
    if (u != nil) {
        if ([u isKindOfClass:NSURL.class]) {
            url = u;
        } else if ([u isKindOfClass:NSString.class] && [u length] > 0) {
            url = [NSURL URLWithString:u];
        }
    }
    return url;
}


@end
