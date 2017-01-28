//
//  YMSBFMSyntheticDelivererOneShot.m
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticDelivererOneShot.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticDelivererOneShot () {
    YMSBFMSyntheticDelivererType _type;
}

@end

@implementation YMSBFMSyntheticDelivererOneShot

- (nullable instancetype)init {
    self = [super init];
    if (self) {
        _type = YMSBFMSyntheticDeliverer_ONESHOT;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
