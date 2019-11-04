//
//  YMSLogger.h
//  Deanna
//
//  Created by Rafael Martins on 4/14/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN
@protocol YMSLogger<NSObject>
- (void)log:(NSString *)message;
- (void)log:(NSString *)message peripheral:(CBPeripheral *)peripheral;
- (void)testLog:(NSString *)message peripheral:(CBPeripheral *)peripheral;
@end

@interface YMSLogManager : NSObject

@property NSObject<YMSLogger> *logger;

+ (instancetype)sharedManager;
- (void)log:(NSString *)message;
- (void)log:(NSString *)message peripheral:(CBPeripheral *)peripheral;
- (void)testLog:(NSString *)message peripheral:(CBPeripheral *)peripheral;
@end
NS_ASSUME_NONNULL_END
