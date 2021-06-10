//
//  CHScrollView.m
//  OSX
//
//  Created by WizJin on 2021/6/10.
//

#import "CHScrollView.h"

@implementation CHScrollView

- (void)scrollWheel:(NSEvent *)theEvent {
    [super scrollWheel:theEvent];
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.delegate scrollViewDidScroll:self];
    }
}


@end
