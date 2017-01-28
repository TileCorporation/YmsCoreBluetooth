//
//  YMSBFMSyntheticValue.m
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticValue.h"
#import "YMSBFMSyntheticGeneratorConstant.h"
#import "YMSBFMSyntheticDelivererConstant.h"

NS_ASSUME_NONNULL_BEGIN

@implementation YMSBFMSyntheticValue

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)json {
    self = [super init];
    if (self) {
        NSDictionary *delivererJson = json[@"delivery"];
        
        if ([delivererJson[@"type"] isEqualToString:@"CONSTANT"]) {
            _delivery = [[YMSBFMSyntheticDelivererConstant alloc] initWithDeliveryTime:[delivererJson[@"delivery_time"] integerValue]];
        }
        
        NSDictionary *generatorJson = json[@"generator"];
        
        if ([generatorJson[@"type"] isEqualToString:@"CONSTANT"]) {
            _generator = [[YMSBFMSyntheticGeneratorConstant alloc] initWithValue:[generatorJson[@"value"] integerValue]];
        }
    }
    return self;
}

- (void)genValueAndTime:(void (^)(NSInteger, NSInteger))result {
    result([_generator genValue], [_delivery genTime]);
}

@end

NS_ASSUME_NONNULL_END
