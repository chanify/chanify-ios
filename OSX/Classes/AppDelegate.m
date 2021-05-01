//
//  AppDelegate.m
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "CHDevice.h"

@interface AppDelegate () <NSWindowDelegate>

@property (nonatomic, readonly, strong) NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    CHLogI("User-angent: %s", CHDevice.shared.userAgent.cstr);
    
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    _window = window;
    window.movableByWindowBackground = YES;
    window.titlebarAppearsTransparent = YES;
    window.delegate = self;
    window.styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable;
    window.contentViewController = [ViewController new];
    [window setFrame:NSMakeRect(0, 0, 480, 320) display:YES animate:YES];
    [window center];
    [window makeKeyAndOrderFront:NSApp];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - NSWindowDelegate
- (BOOL)windowShouldClose:(id)sender {
    dispatch_main_async(^{
        [NSApp terminate:nil];
    });
    return YES;
}


@end
