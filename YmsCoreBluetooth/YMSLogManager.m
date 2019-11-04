//
//  YMSLogger.m
//  Deanna
//
//  Created by Rafael Martins on 4/14/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSLogManager.h"

NS_ASSUME_NONNULL_BEGIN
@implementation YMSLogManager

+ (instancetype)sharedManager {
    static id sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [YMSLogManager new];
    });
    
    return sharedManager;
}

- (void)log:(NSString *)message {
    [self.logger log:message];
}

-(void)log:(NSString *)message peripheral:(CBPeripheral *)peripheral {
    [self.logger log:message peripheral:peripheral];
}

-(void)testLog:(NSString *)message peripheral:(CBPeripheral *)peripheral {
   [self.logger testLog:message peripheral:peripheral];
}
@end
NS_ASSUME_NONNULL_END
