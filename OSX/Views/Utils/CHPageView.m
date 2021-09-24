//
//  CHPageView.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHPageView.h"
#import "CHTheme.h"

@implementation CHPageView

- (instancetype)initWithParameters:(NSDictionary *)params {
    return [self init];
}

- (instancetype)init {
    if (self = [super init]) {
        @weakify(self);
        dispatch_main_async(^{
            @strongify(self);
            [self viewDidLoad];
        });
    }
    return self;
}

- (BOOL)isEqualToViewController:(__kindof CHPageView *)rhs {
    return NO;
}

- (NSString *)title {
    return @"";
}

- (void)viewDidLoad {
}

- (void)viewDidAppear {
}

- (void)viewDidDisappear {
}

- (void)closeAnimated:(BOOL)animated completion: (void (^ __nullable)(void))completion {
}


@end
