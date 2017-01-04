// 
// Copyright 2013-2015 Yummy Melon Software LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Author: Charles Y. Choi <charles.choi@yummymelon.com>
//

@import Foundation;
@import CoreBluetooth;
#include "YMSCBUtils.h"

NS_ASSUME_NONNULL_BEGIN

@class YMSCBPeripheral;
@class YMSCBCentralManager;
@class YMSCBService;
@class YMSCBCharacteristic;
@class YMSCBDescriptor;

typedef void (^YMSCBPeripheralConnectCallbackBlockType)(YMSCBPeripheral *, NSError * _Nullable);
typedef void (^YMSCBPeripheralDiscoverServicesBlockType)(NSArray *, NSError * _Nullable);

@protocol YMSCBPeripheralInterface

@property(assign, nonatomic, nullable) id<CBPeripheralDelegate> delegate;

@property(retain, readonly, nullable) NSString *name;

@property(retain, readonly, nullable) NSNumber *RSSI;

@property(readonly) CBPeripheralState state;

@property(retain, readonly, nullable) NSArray<CBService *> *services;

- (void)readRSSI;

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;

- (void)discoverIncludedServices:(nullable NSArray<CBUUID *> *)includedServiceUUIDs forService:(CBService *)service;

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service;

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic;

- (NSUInteger)maximumWriteValueLengthForType:(CBCharacteristicWriteType)type NS_AVAILABLE(NA, 9_0);

- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;

- (void)discoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic;

- (void)readValueForDescriptor:(CBDescriptor *)descriptor;

- (void)writeValue:(NSData *)data forDescriptor:(CBDescriptor *)descriptor;

@end

@protocol YMSCBPeripheralDelegate

@optional

- (void)peripheralDidUpdateName:(YMSCBPeripheral *)peripheral;

- (void)peripheral:(YMSCBPeripheral *)peripheral didModifyServices:(NSArray<YMSCBService *> *)invalidatedServices;

- (void)peripheral:(YMSCBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didDiscoverIncludedServicesForService:(YMSCBService *)service error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didDiscoverCharacteristicsForService:(YMSCBService *)service error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didUpdateValueForCharacteristic:(YMSCBCharacteristic *)characteristic error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didWriteValueForCharacteristic:(YMSCBCharacteristic *)characteristic error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(YMSCBCharacteristic *)characteristic error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(YMSCBCharacteristic *)characteristic error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didUpdateValueForDescriptor:(YMSCBDescriptor *)descriptor error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)peripheral didWriteValueForDescriptor:(YMSCBDescriptor *)descriptor error:(nullable NSError *)error;

@end




/**
 Base class for defining a Bluetooth LE peripheral.
 
 YMSCBPeripheral holds an instance of CBPeripheral (cbPeripheral) and implements
 the CBPeripheralDelegate messages sent by cbPeripheral.
 
 The BLE services discovered by cbPeripheral are encapulated in instances of YMSCBService and
 contained in the dictionary serviceDict.
 
 */
@interface YMSCBPeripheral : NSObject <CBPeripheralDelegate>

/** @name Properties */
/// 128 bit address base
@property (nonatomic, assign) yms_u128_t base;

/**
 Convenience accessor for cbPeripheral.name.
 */
@property (nonatomic, readonly, nullable) NSString *name;

/**
 Pointer to delegate.
 
 The delegate object will be forwarded CBPeripheralDelegate messages sent by cbPeripheral.
 
 */
@property (nonatomic, assign, nullable) id<CBPeripheralDelegate> delegate;

/**
 Flag to indicate if the watchdog timer has expired and forced a disconnect.
 */
@property (nonatomic, assign) BOOL watchdogRaised;

/** 
 Dictionary of (`key`, `value`) pairs of (NSString, YMSCBService) instances.
 
 The NSString `key` is typically a "human-readable" string to easily reference a YMSCBService.
 */
@property (nonatomic, strong) NSDictionary *serviceDict;

/// The CBPeripheral instance.
@property (nonatomic, strong, nullable) CBPeripheral *cbPeripheral;

/**
 A Boolean value indicating whether the peripheral is currently connected to the central manager. (read-only)
 
 This value is populated with cbPeripheral.isConnected.
 */
@property (readonly) BOOL isConnected;

/**
 Time period between RSSI pings. (Default: 2 seconds)

 This is a convenience property to hold a ping period for RSSI updates. No policy or mechanism for invoking readRSSI is provided for by YMSCBPeripheral or YMSCoreBluetooth.
 */
@property (nonatomic, assign) NSTimeInterval rssiPingPeriod;

/**
 Pointer to an instance of YMSCBCentralManager.
 */
@property (nonatomic, weak, nullable) YMSCBCentralManager *central;

/**
 Watchdog timer for connection.
 */
@property (nonatomic, strong, nullable) NSTimer *watchdogTimer;

/**
 Watchdog timer interval in seconds. Default is 5 seconds.
 */
@property (nonatomic, assign) NSTimeInterval watchdogTimerInterval;

/// Holds callback for connection established.
@property (nonatomic, copy, nullable) YMSCBPeripheralConnectCallbackBlockType connectCallback;

/// Holds callback for services discovered.
@property (nonatomic, copy, nullable) YMSCBPeripheralDiscoverServicesBlockType discoverServicesCallback;


/**
 Helper flag to determine ViewCell updates.
 
 */
@property (nonatomic, assign) BOOL isRenderedInViewCell;
           


/** @name Initializing a YMSCBPeripheral */
/**
 Constructor.
 
 This method must be called via super in any subclass implementation.
 
 The implementation of this method in a subclass will populate serviceDict with (`key`, `value`) pairs of
 (NSString, YMSCBService) instances, where `key` is typically a "human-readable" string to easily 
 reference a YMSCBService.
 

 @param peripheral Pointer to CBPeripheral
 @param owner Pointer to YMSCBCentralManager
 @param hi Top 64 bits of 128-bit base address value
 @param lo Bottom 64 bits of 128-bit base address value
 @return instance of this class
 */
- (nullable instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                                    central:(YMSCBCentralManager *)owner
                                     baseHi:(int64_t)hi
                                     baseLo:(int64_t)lo;


/** @name Get all CBService CBUUIDs for this peripheral  */
/**
 Generate array of CBUUID for all CoreBluetooth services associated with this peripheral.
 
 The output of this method is to be passed to the method discoverServices: in CBPeripheral:
 
 @return array of CBUUID services
 */
- (NSArray *)services;


/**
 Return array of CBUUIDs for YMSCBService instances in serviceDict whose key is included in keys.
 
 @param keys array of NSString keys, where each key must exist in serviceDict
 
 @return array of CBUUIDs
 */
- (NSArray *)servicesSubset:(NSArray *)keys;


/** @name Find a YMSCBService */
/**
 Find YMSCBService given its corresponding CBService.
 
 @param service CBService to search for in serviceDict.
 @return YMSCBService instance which holds *service*.
 */
- (nullable YMSCBService *)findService:(CBService *)service;

/**
 Connect peripheral
 */
- (void)connect;

/**
 Disconnect peripheral
 */
- (void)disconnect;

/**
 Invokes [CBPeripheral readRSSI] method to retrieve current RSSI value for cbPeripheral.
 */
- (void)readRSSI;

/**
 Initialize or reset watchdog timer.
 */
- (void)resetWatchdog;

/**
 Invalidate watchdog timer.
 */
- (void)invalidateWatchdog;

/**
 Disconnect if watchdog times out.
 */
- (void)watchdogDisconnect;

/**
 Establishes connection to peripheral with callback block.
 
 @param options A dictionary to customize the behavior of the connection. See "Peripheral Connection Options" for CBCentralManager.
 @param connectCallback Callback block to handle peripheral connection.
 */
- (void)connectWithOptions:(nullable NSDictionary *)options withBlock:(nullable void (^)(YMSCBPeripheral *yp, NSError * _Nullable error))connectCallback;

/**
 Cancels an active or pending local connection to a peripheral.
 */
- (void)cancelConnection;

/**
 Executes connect callback.
 
 @param error Error object.
 */
- (void)handleConnectionResponse:(nullable NSError *)error;

/**
 Default connection handler routine that is invoked only if connectCallback is nil.
 
 This method is only invoked if a connection request to an instance of this peripheral is done without
 a callback block defined.

 */
- (void)defaultConnectionHandler;


/**
 Discover services using block.
 @param serviceUUIDs An array of CBUUID objects that you are interested in. Here, each CBUUID object represents a UUID that identifies the type of service you want to discover.
 @param callback A 
 */
- (void)discoverServices:(nullable NSArray *)serviceUUIDs withBlock:(nullable void (^)(NSArray * _Nullable services, NSError * _Nullable error))callback;


/**
 Add dictionary style subscripting to YMSCBPeripheral instance to access objects in serviceDict with key.
 
 @param key The key for which to return the corresponding value in serviceDict.
 @return object in serviceDict.
 */
- (nullable id)objectForKeyedSubscript:(id)key;

- (void)replaceCBPeripheral:(CBPeripheral *)peripheral;

- (void)reset;

/**
 Synchronize list of CBService objects with their YMSCBService container.
 
 @param services Array of CBService objects, typical CBPeripheral.services
 */
- (void)syncServices:(NSArray *)services;

@end

NS_ASSUME_NONNULL_END
