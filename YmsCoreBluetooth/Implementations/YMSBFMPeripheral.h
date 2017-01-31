//
//  YMSBFMPeripheral.h
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBPeripheral.h"
@class YMSBFMConfiguration;
@class YMSBFMSyntheticValue;
@class YMSBFMStimulusGenerator;
@protocol YMSCBCentralManagerInterfaceDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMPeripheral : NSObject<YMSCBPeripheralInterface>

@property(assign, nonatomic, nullable) id<YMSCBPeripheralInterfaceDelegate> delegate;

@property(retain, readonly, nullable) NSString *name;

@property(readonly, nonatomic) NSUUID *identifier;

@property(readonly) CBPeripheralState state;

@property(readonly) NSNumber *RSSI;

@property(retain, readonly, nullable) NSArray<id<YMSCBServiceInterface>> *services;

@property(nonatomic, weak, nullable) id<YMSCBCentralManagerInterface> central;

@property(nonatomic, strong) YMSBFMSyntheticValue *syntheticRSSI;

- (nullable instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central stimulusGenerator:(YMSBFMStimulusGenerator *)stimulusGenerator identifier:(NSString *)identifier name:(NSString *)name;
- (void)setConnectionState:(CBPeripheralState)state;
- (void)addService:(id<YMSCBServiceInterface>)service;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverServices:(nullable NSError *)error;
- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
