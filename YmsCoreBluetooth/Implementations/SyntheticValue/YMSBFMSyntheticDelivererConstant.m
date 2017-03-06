//
//  YMSBFMSyntheticDelivererConstant.m
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticDelivererConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticDelivererConstant ()

@property (nonatomic) NSTimeInterval deliveryTime;

@end

@implementation YMSBFMSyntheticDelivererConstant

- (nullable instancetype)initWithDeliveryTime:(NSTimeInterval)deliveryTime {
    self = [super init];
    if (self) {
        _deliveryTime = deliveryTime;
    }
    return self;
}

- (NSTimeInterval)genTime:(NSError * _Nullable __autoreleasing *)error {
    return _deliveryTime;
}

- (BOOL)hasNext {
    return YES;
}

@end

NS_ASSUME_NONNULL_END
