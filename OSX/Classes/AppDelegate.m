//
//  AppDelegate.m
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "AppDelegate.h"
#import "CHMianViewController.h"
#import "CHLogic+OSX.h"

@interface AppDelegate () <NSWindowDelegate>

@property (nonatomic, readonly, strong) NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [CHLogic.shared launch];
    [CHLogic.shared active];

    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    _window = window;
    window.movableByWindowBackground = YES;
    window.titlebarAppearsTransparent = YES;
    window.delegate = self;
    window.styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable;
    window.contentViewController = [CHMianViewController new];
    [window setFrame:NSMakeRect(0, 0, 480, 320) display:YES animate:YES];
    [window center];
    [window makeKeyAndOrderFront:NSApp];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [CHLogic.shared deactive];
    [CHLogic.shared close];
}

- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [CHLogic.shared updatePushToken:deviceToken];
}

- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
}

- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *, id> *)userInfo {
    [CHLogic.shared receiveRemoteNotification:userInfo];
}

#pragma mark - NSWindowDelegate
- (BOOL)windowShouldClose:(id)sender {
    dispatch_main_async(^{
        [NSApp terminate:nil];
    });
    return YES;
}


@end
