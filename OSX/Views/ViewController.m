//
//  ViewController.m
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "ViewController.h"

@implementation ViewController

- (void)loadView {
    self.view = [NSView new];
    self.view.layer.backgroundColor = NSColor.blueColor.CGColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
