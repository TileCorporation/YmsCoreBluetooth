//
//  YMSBFMModelConfiguration.h
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMModelConfiguration : NSObject

@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSDictionary<NSString *, id> *> *peripherals;

- (nullable instancetype)initWithConfigurationFile:(nullable NSString *)filename;

@end

NS_ASSUME_NONNULL_END
