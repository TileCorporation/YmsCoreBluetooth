//
//  YMSBFMSyntheticValueUtils.h
//  Deanna
//
//  Created by Paul Wong on 1/30/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kYMSBFMSyntheticValueErrorDomain;
extern NSString *const kYMSBFMSyntheticValueInvalidValueDescription;
extern NSString *const kYMSBFMSyntheticValueInvalidValueFailureReason;
extern NSString *const kYMSBFMSyntheticValueInvalidValueRecoverySuggestion;
extern NSString *const kYMSBFMSyntheticValueInvalidRangeDescription;
extern NSString *const kYMSBFMSyntheticValueInvalidRangeFailureReason;
extern NSString *const kYMSBFMSyntheticValueInvalidRangeRecoverySuggestion;
extern NSString *const kYMSBFMSyntheticValueInvalidStepDescription;
extern NSString *const kYMSBFMSyntheticValueInvalidStepFailureReason;
extern NSString *const kYMSBFMSyntheticValueInvalidStepRecoverySuggestion;

typedef NS_ENUM(NSInteger, YMSBFMSyntheticValueErrorType) {
    YMSBFMSyntheticValueErrorInvalidValue,
    YMSBFMSyntheticValueErrorInvalidRange,
    YMSBFMSyntheticValueErrorInvalidStep
};

@interface YMSBFMSyntheticValueUtils : NSObject

+ (NSError *)errorForErrorType:(YMSBFMSyntheticValueErrorType)errorType;

@end

NS_ASSUME_NONNULL_END
