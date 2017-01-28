//
//  YMSBFMSyntheticGeneratorConstant.m
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticGeneratorConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticGeneratorConstant () {
    YMSBFMSyntheticGeneratorType _type;
}

@property (nonatomic) NSInteger value;

@end

@implementation YMSBFMSyntheticGeneratorConstant

- (nullable instancetype)initWithValue:(NSInteger)value {
    self = [super init];
    if (self) {
        _value = value;
        _type = YMSBFMSyntheticGenerator_CONSTANT;
    }
    return self;
}

- (NSInteger)genValue {
    return _value;
}

@end

NS_ASSUME_NONNULL_END
