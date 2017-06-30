//
//  YMSBFMCharacteristic.h
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;
#import "YMSCBCharacteristic.h"
@class YMSBFMSyntheticValue;
@class YMSBFMStimulusGenerator;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMCharacteristic : NSObject<YMSCBCharacteristicInterface>

@property(assign, readonly, nonatomic) id<YMSCBServiceInterface>service;
@property(readonly, nonatomic) CBUUID *UUID;

@property(readonly, nonatomic) CBCharacteristicProperties properties;
@property(retain, readonly, nullable) NSData *value;
@property(retain, readonly, nullable) NSArray<id<YMSCBDescriptorInterface>> *descriptors;
@property(readonly) BOOL isBroadcasted;
@property(readonly) BOOL isNotifying;

@property(nonatomic, strong) YMSBFMSyntheticValue *syntheticValue;

// TODO: remove this property and just pass it in the didUpdateValue method
@property(nonatomic, strong) NSNumber *behavioralValue;

- (nullable instancetype)initWithCBUUID:(CBUUID *)uuid serviceInterface:(id<YMSCBServiceInterface>)serviceInterface stimulusGenerator:(YMSBFMStimulusGenerator *)stimulusGenerator;
- (void)setIsNotifying:(BOOL)isNotifying;
- (void)writeValue:(NSData *)value;

- (void)didUpdateValueWithPeripheral:(id<YMSCBPeripheralInterface>)peripheral error:(NSError *)error;
- (void)didWriteValueWithPeripheral:(id<YMSCBPeripheralInterface>)peripheral error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
