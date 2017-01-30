//
//  YMSBFMSyntheticValueUtils.m
//  Deanna
//
//  Created by Paul Wong on 1/30/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticValueUtils.h"

NSString *const kYMSBFMSyntheticValueErrorDomain = @"com.yummymelon.bfm.syntheticvalueerror";
NSString *const kYMSBFMSyntheticValueInvalidValueDescription = @"Invalid value.";
NSString *const kYMSBFMSyntheticValueInvalidValueFailureReason = @"Invalid value was generated.";
NSString *const kYMSBFMSyntheticValueInvalidValueRecoverySuggestion = @"Check model.json configuration.";
NSString *const kYMSBFMSyntheticValueInvalidRangeDescription = @"Invalid range.";
NSString *const kYMSBFMSyntheticValueInvalidRangeFailureReason = @"Invalid range was generated.";
NSString *const kYMSBFMSyntheticValueInvalidRangeRecoverySuggestion = @"Check model.json configuration.";
NSString *const kYMSBFMSyntheticValueInvalidStepDescription = @"Invalid step.";
NSString *const kYMSBFMSyntheticValueInvalidStepFailureReason = @"Invalid step was generated.";
NSString *const kYMSBFMSyntheticValueInvalidStepRecoverySuggestion = @"Check model.json configuration.";
NSString *const kYMSBFMSyntheticValueInvalidLoopRepeatDescription = @"Invalid loop repeat.";
NSString *const kYMSBFMSyntheticValueInvalidLoopRepeatFailureReason = @"repeat was set to false. There are no more values to iterate through.";
NSString *const kYMSBFMSyntheticValueInvalidLoopRepeatRecoverySuggestion = @"Check the number of iterations or set repeat to true.";

NS_ASSUME_NONNULL_BEGIN

@implementation YMSBFMSyntheticValueUtils

+ (NSError *)errorForErrorType:(YMSBFMSyntheticValueErrorType)errorType {
    NSError *error = nil;
    NSDictionary<NSString *, NSString *> *userInfo;
    
    switch (errorType) {
        case YMSBFMSyntheticValueErrorInvalidValue:
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidValueDescription, nil),
                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidValueFailureReason, nil),
                         NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidValueRecoverySuggestion, nil)
                         };
            error = [NSError errorWithDomain:kYMSBFMSyntheticValueErrorDomain code:errorType userInfo:userInfo];
            break;
        case YMSBFMSyntheticValueErrorInvalidRange:
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidRangeDescription, nil),
                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidRangeFailureReason, nil),
                         NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidRangeRecoverySuggestion, nil)
                         };
            error = [NSError errorWithDomain:kYMSBFMSyntheticValueErrorDomain code:errorType userInfo:userInfo];
            break;
        case YMSBFMSyntheticValueErrorInvalidStep:
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidStepDescription, nil),
                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidStepFailureReason, nil),
                         NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidStepRecoverySuggestion, nil)
                         };
            error = [NSError errorWithDomain:kYMSBFMSyntheticValueErrorDomain code:errorType userInfo:userInfo];
            break;
        case YMSBFMSyntheticValueErrorInvalidLoopRepeat:
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidLoopRepeatDescription, nil),
                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidLoopRepeatFailureReason, nil),
                         NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(kYMSBFMSyntheticValueInvalidLoopRepeatRecoverySuggestion, nil)
                         };
            error = [NSError errorWithDomain:kYMSBFMSyntheticValueErrorDomain code:errorType userInfo:userInfo];
            break;
        default:
            break;
    }
    
    return error;
}

@end

NS_ASSUME_NONNULL_END
