//
//  YMSBFMSyntheticGeneratorLoop.m
//  Deanna
//
//  Created by Paul Wong on 1/30/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticGeneratorLoop.h"
#import "YMSBFMSyntheticValueUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticGeneratorLoop () {
    YMSBFMSyntheticGeneratorType _type;
}

@property (nonatomic) NSInteger start;
@property (nonatomic) NSInteger stop;
@property (nonatomic) NSInteger step;
@property (nonatomic) BOOL repeat;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) NSInteger currentValue;
@property (nonatomic) BOOL isFirst;

@end

@implementation YMSBFMSyntheticGeneratorLoop

- (nullable instancetype)initWithRange:(NSArray<NSNumber *> *)range step:(NSNumber *)step repeat:(BOOL)repeat {
    self = [super init];
    if (self) {
        _start = range.firstObject.integerValue;
        _stop = range.lastObject.integerValue;
        _step = step.integerValue;
        _repeat = repeat;
        _currentIndex = 0;
        _currentValue = _start;
        _isFirst = YES;
        _type = YMSBFMSyntheticGenerator_RANDOM;
    }
    return self;
}

- (nullable NSNumber *)genValue:(NSError * _Nullable __autoreleasing *)error {
    // TODO: Handle bounds checking error
//    if (!_start || !_stop) {
//        *error = [YMSBFMSyntheticValueUtils errorForErrorType:YMSBFMSyntheticValueErrorInvalidRange];
//    }
    
    NSNumber *result = nil;

    if (_currentIndex != 0) {
        NSInteger newValue = _currentValue + _step;
        if (_repeat) {
            if (newValue > _stop) {
                // start over
                _currentIndex = 0;
                _currentValue = _start;
            } else {
                _currentValue = newValue;
                _currentIndex++;
            }
        } else {
            if (_currentValue > _stop) {
                *error = [YMSBFMSyntheticValueUtils errorForErrorType:YMSBFMSyntheticValueErrorInvalidLoopRepeat];
            } else {
                if (newValue <= _stop) {
                    _currentValue = newValue;
                    _currentIndex++;
                }
            }
        }
    } else {
        _currentIndex++;
    }
    
    result = @(_currentValue);
    
    return result;
}

- (BOOL)hasNext {
    BOOL result = YES;
    
    NSInteger newValue = _currentValue + _step;
    if (!_repeat) {
        if (newValue > _stop) {
            if (_isFirst) {
                result = YES;
                _isFirst = NO;
            } else {
                result = NO;
            }
        }
    }
    
    return result;
}

@end

NS_ASSUME_NONNULL_END
