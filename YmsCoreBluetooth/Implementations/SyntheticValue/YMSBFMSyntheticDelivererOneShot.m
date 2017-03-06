//
//  YMSBFMSyntheticDelivererOneShot.m
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticDelivererOneShot.h"
#import "YMSBFMSyntheticValueUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticDelivererOneShot () {
    YMSBFMSyntheticDelivererType _type;
}
@property (nonatomic) NSTimeInterval deliveryTime;
@property (nonatomic) BOOL didDeliver;
@end

@implementation YMSBFMSyntheticDelivererOneShot

- (nullable instancetype)initWithDeliveryTime:(NSTimeInterval)deliveryTime {
    self = [super init];
    if (self) {
        _deliveryTime = deliveryTime;
        _type = YMSBFMSyntheticDeliverer_ONESHOT;

    }
    return self;
}

- (NSTimeInterval)genTime:(NSError * _Nullable __autoreleasing *)error {
    if (_didDeliver) {
        *error = [YMSBFMSyntheticValueUtils errorForErrorType:YMSBFMSyntheticValueErrorInvalidValue];
    } else {
        _didDeliver = YES;
    }
    
    return _deliveryTime;
}

- (BOOL)hasNext {
    BOOL result = YES;
    
    if (_didDeliver) {
        result = NO;
    }
    
    return result;
}

@end

NS_ASSUME_NONNULL_END
