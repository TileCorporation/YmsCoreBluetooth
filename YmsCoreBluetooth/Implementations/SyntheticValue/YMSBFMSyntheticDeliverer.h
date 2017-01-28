//
//  YMSBFMSyntheticDeliverer.h
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSUInteger, YMSBFMSyntheticDelivererType) {
    YMSBFMSyntheticDeliverer_ONESHOT,
    YMSBFMSyntheticDeliverer_PERIODIC,
    YMSBFMSyntheticDeliverer_RANDOM
};

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticDeliverer : NSObject

@property (nonatomic, readonly) YMSBFMSyntheticDelivererType type;

- (NSUInteger)genTime;

@end

NS_ASSUME_NONNULL_END
