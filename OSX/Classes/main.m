//
//  main.m
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    AppDelegate *appDelegate = [AppDelegate new];
    NSApplication.sharedApplication.delegate = appDelegate;
    return NSApplicationMain(argc, argv);
}
