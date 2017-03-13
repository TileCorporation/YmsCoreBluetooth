//
//  YMSBFMConfiguration.h
//  Deanna
//
//  Created by Charles Choi on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMPeripheralConfiguration : NSObject

@property (nonatomic, readonly) NSArray<NSDictionary<id, id> *> *peripherals;

- (nullable instancetype)initWithConfigurationFile:(nullable NSString *)filename;
- (nullable instancetype)initWithConfigurationURL:(nullable NSURL *)url;

- (nullable NSDictionary<NSString *, id> *)peripheralWithName:(NSString *)className;

- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)servicesForPeripheral:(NSString *)className;

- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)characteristicsForServiceUUID:(NSString *)serviceUUID peripheral:(NSString *)peripheralClassName;

@end

NS_ASSUME_NONNULL_END
