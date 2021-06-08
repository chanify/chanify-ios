//
//  CHLineView.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "CHLineView.h"

@interface CHLineView () {
@private
    NSInteger   storeTag;
}

@end

@implementation CHLineView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self->storeTag = -1;
    }
    return self;
}

- (NSInteger)tag {
    return self->storeTag;
}

- (void)setTag:(NSInteger)tag {
    self->storeTag = tag;
}


@end
