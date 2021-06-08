//
//  CHMessageCellItem.h
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHTapGestureRecognizer : NSClickGestureRecognizer
- (void)requireGestureRecognizerToFail:(NSGestureRecognizer *)otherGestureRecognizer;
@end

@interface CHLongPressGestureRecognizer : NSClickGestureRecognizer
@end


NS_ASSUME_NONNULL_END
