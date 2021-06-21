//
//  CHPanelCellConfiguration.h
//  iOS
//
//  Created by WizJin on 2021/6/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHPanelCellConfiguration : NSObject<UIContentConfiguration>

@property (nonatomic, readonly, strong) NSString *code;

+ (instancetype)cellConfiguration:(NSString *)code;


@end

NS_ASSUME_NONNULL_END
