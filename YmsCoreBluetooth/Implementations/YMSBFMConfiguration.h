//
//  YMSBFMConfiguration.h
//  Deanna
//
//  Created by Charles Choi on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMConfiguration : NSObject

@property (nonatomic, readonly) NSArray<NSDictionary<id, id> *> *peripherals;


- (nullable instancetype)initWithConfigurationFile:(nullable NSString *)filename;

- (NSArray<NSDictionary<id, id> *> *)servicesForPeripheral:(NSString *)className;

- (NSArray<NSDictionary<id, id> *> *)characteristicsForService:(NSString *)className;



@end

NS_ASSUME_NONNULL_END
