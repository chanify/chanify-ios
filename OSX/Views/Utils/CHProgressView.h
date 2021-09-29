//
//  CHProgressView.h
//  OSX
//
//  Created by WizJin on 2021/9/30.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHProgressView : NSView

@property (nonatomic, strong) NSColor *trackTintColor;
@property (nonatomic, assign) CGFloat progress;

- (instancetype)initWithProgressViewStyle:(NSProgressIndicatorStyle)style;


@end

NS_ASSUME_NONNULL_END
