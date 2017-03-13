//
//  YMSBFMModelConfiguration.h
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMModelConfiguration : NSObject

@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSDictionary<NSString *, id> *> *peripherals;

- (nullable instancetype)initWithConfigurationFile:(nullable NSString *)filename;
- (nullable instancetype)initWithConfigurationURL:(nullable NSURL *)url;

- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)servicesForPeripheralIdentifier:(NSString *)identifier;
- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)characteristicForService:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)service withCharacteristicUUID:(NSString *)uuid;

@end

NS_ASSUME_NONNULL_END
