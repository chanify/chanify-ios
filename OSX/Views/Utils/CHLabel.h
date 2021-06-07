//
//  CHLabel.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHLabel : NSTextField

@property (nonatomic, nullable, strong) NSString *text;

- (void)setTextAlignment:(NSTextAlignment)textAlignment;
- (void)setNumberOfLines:(NSInteger)numberOfLines;
- (void)setAttributedText:(NSAttributedString *)attributedText;


@end

NS_ASSUME_NONNULL_END
