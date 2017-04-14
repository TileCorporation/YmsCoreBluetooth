//
//  YMSLogger.m
//  Deanna
//
//  Created by Rafael Martins on 4/14/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSLogManager.h"

@implementation YMSLogManager
+ (instancetype)sharedLogger {
    static id sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLogger = [[YMSLogManager alloc] init];
    });
    
    return sharedLogger;
}
@end
