//
//  YMSBFMSyntheticGeneratorConstant.m
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticGeneratorConstant.h"
#import "YMSBFMSyntheticValueUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticGeneratorConstant () {
    YMSBFMSyntheticGeneratorType _type;
}

@property (nonatomic, strong, nullable) NSNumber *value;

@end

@implementation YMSBFMSyntheticGeneratorConstant

- (nullable instancetype)initWithValue:(NSNumber *)value {
    self = [super init];
    if (self) {
        _value = value;
        _type = YMSBFMSyntheticGenerator_CONSTANT;
    }
    return self;
}

- (nullable NSNumber *)genValue:(NSError * _Nullable __autoreleasing *)error {
    if (!_value) {
        if (error != NULL) {
            *error = [YMSBFMSyntheticValueUtils errorForErrorType:YMSBFMSyntheticValueErrorInvalidValue];
        }
    }
    
    return _value;
}

- (BOOL)hasNext {
    return YES;
}

@end

NS_ASSUME_NONNULL_END
