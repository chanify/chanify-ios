//
//  CHSoundCell.h
//  iOS
//
//  Created by WizJin on 2022/3/12.
//

#import "CHTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHSoundCell : CHTableViewCell

@property (nonatomic, nullable, strong) NSString *filePath;

- (void)setCheck:(BOOL)isCheck;


@end

NS_ASSUME_NONNULL_END
