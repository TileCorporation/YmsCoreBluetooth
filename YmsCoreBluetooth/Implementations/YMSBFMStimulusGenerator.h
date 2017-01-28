//
//  YMSBFMStimulusGenerator.h
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
@class CBUUID;
@class YMSBFMPeripheral;
@class YMSBFMModelConfiguration;
@class YMSBFMPeripheralConfiguration;
@protocol YMSCBCentralManagerInterface;
@protocol YMSCBPeripheralInterface;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMStimulusGenerator : NSObject

@property (nonatomic, strong) NSDictionary<NSString *, YMSBFMPeripheral *> *peripherals;
@property (nonatomic, strong) YMSBFMModelConfiguration *modelConfiguration;
@property (nonatomic, strong) YMSBFMPeripheralConfiguration *peripheralConfiguration;

- (instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central;

- (void)genPeripherals;

- (void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options;
- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didConnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface;
- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didDisconnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error;
@end

NS_ASSUME_NONNULL_END
