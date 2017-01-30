//
//  YMSBFMSyntheticDelivererRandom.h
//  Deanna
//
//  Created by Paul Wong on 1/30/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticDeliverer.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticDelivererRandom : YMSBFMSyntheticDeliverer

- (nullable instancetype)initWithLower:(NSNumber *)lower upper:(NSNumber *)upper;

@end

NS_ASSUME_NONNULL_END
