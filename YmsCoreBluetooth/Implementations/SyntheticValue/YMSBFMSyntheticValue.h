//
//  YMSBFMSyntheticValue.h
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
@class YMSBFMSyntheticGenerator;
@class YMSBFMSyntheticDeliverer;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticValue : NSObject

@property (nonatomic, strong) YMSBFMSyntheticGenerator *generator;
@property (nonatomic, strong) YMSBFMSyntheticDeliverer *delivery;

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)json;
- (void)genValueAndTime:(void (^)(NSInteger value, NSInteger time))result;

@end

NS_ASSUME_NONNULL_END
