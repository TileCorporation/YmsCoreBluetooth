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
#import "YMSCBUtils.h"

NS_ASSUME_NONNULL_BEGIN

@class YMSCBPeripheral;
@class YMSCBCentralManager;
@class YMSCBService;
@class YMSCBCharacteristic;
@class YMSCBDescriptor;
@protocol YMSCBCentralManagerInterface;
@protocol YMSCBPeripheralInterface;
@protocol YMSCBPeripheralInterfaceDelegate;
@protocol YMSCBPeripheralDelegate;
@protocol YMSCBServiceInterface;
@protocol YMSCBCharacteristicInterface;
@protocol YMSCBDescriptorInterface;

typedef void (^YMSCBPeripheralConnectCallbackBlockType)(YMSCBPeripheral *, NSError * _Nullable);
typedef void (^YMSCBPeripheralDiscoverServicesBlockType)(NSArray *, NSError * _Nullable);

// ------------------------------------------------------------------------

@protocol YMSCBPeripheralInterface <NSObject>

@property(assign, nonatomic, nullable) id<YMSCBPeripheralInterfaceDelegate> delegate;

@property(retain, readonly, nullable) NSString *name;

@property(readonly, nonatomic) NSUUID *identifier;

@property(readonly) CBPeripheralState state;

#if TARGET_OS_IPHONE
#else
@property(readonly) NSNumber *RSSI;
#endif

@property(retain, readonly, nullable) NSArray<id<YMSCBServiceInterface>> *services;

- (void)readRSSI;

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;

- (void)discoverIncludedServices:(nullable NSArray<CBUUID *> *)includedServiceUUIDs forService:(id<YMSCBServiceInterface>)yService;

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(id<YMSCBServiceInterface>)yService;

- (void)readValueForCharacteristic:(id<YMSCBCharacteristicInterface>)yCharacteristic;

- (void)writeValue:(NSData *)data forCharacteristic:(id<YMSCBCharacteristicInterface>)yCharacteristic type:(CBCharacteristicWriteType)type;

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(id<YMSCBCharacteristicInterface>)yCharacteristic;

- (void)discoverDescriptorsForCharacteristic:(id<YMSCBCharacteristicInterface>)yCharacteristic;

- (void)readValueForDescriptor:(id<YMSCBDescriptorInterface>)yDescriptor;

- (void)writeValue:(NSData *)data forDescriptor:(id<YMSCBDescriptorInterface>)yDescriptor;

@end

// ------------------------------------------------------------------------

@protocol YMSCBPeripheralInterfaceDelegate <CBPeripheralDelegate>

@optional

- (void)peripheralDidUpdateName:(id<YMSCBPeripheralInterface>)peripheralInterface;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didModifyServices:(NSArray<id<YMSCBServiceInterface>> *)invalidatedServices;

#if TARGET_OS_IPHONE
- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error;
#else
- (void)peripheralDidUpdateRSSI:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error;
#endif

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverServices:(nullable NSError *)error;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverIncludedServicesForService:(id<YMSCBServiceInterface>)serviceInterface error:(nullable NSError *)error;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverCharacteristicsForService:(id<YMSCBServiceInterface>)serviceInterface error:(nullable NSError *)error;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didWriteValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateNotificationStateForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverDescriptorsForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateValueForDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface error:(nullable NSError *)error;

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didWriteValueForDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface error:(nullable NSError *)error;

@end


// ------------------------------------------------------------------------

@protocol YMSCBPeripheralDelegate <NSObject>

@optional

- (void)peripheralDidUpdateName:(YMSCBPeripheral *)yPeripheral;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didModifyServices:(NSArray<YMSCBService *> *)invalidatedServices;

#if TARGET_OS_IPHONE
- (void)peripheral:(YMSCBPeripheral *)yPeripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error;
#else
- (void)peripheralDidUpdateRSSI:(YMSCBPeripheral *)yPeripheral error:(nullable NSError *)error;
#endif


- (void)peripheral:(YMSCBPeripheral *)yPeripheral didDiscoverServices:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didDiscoverIncludedServicesForService:(YMSCBService *)yService error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didDiscoverCharacteristicsForService:(YMSCBService *)yService error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didUpdateValueForCharacteristic:(YMSCBCharacteristic *)yCharacteristic error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didWriteValueForCharacteristic:(YMSCBCharacteristic *)yCharacteristic error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didUpdateNotificationStateForCharacteristic:(YMSCBCharacteristic *)yCharacteristic error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didDiscoverDescriptorsForCharacteristic:(YMSCBCharacteristic *)yCharacteristic error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didUpdateValueForDescriptor:(YMSCBDescriptor *)yDescriptor error:(nullable NSError *)error;

- (void)peripheral:(YMSCBPeripheral *)yPeripheral didWriteValueForDescriptor:(YMSCBDescriptor *)yDescriptor error:(nullable NSError *)error;

@end

// ------------------------------------------------------------------------


/**
 Base class for defining a Bluetooth LE peripheral.
 
 YMSCBPeripheral holds an instance of CBPeripheral (cbPeripheral) and implements
 the CBPeripheralDelegate messages sent by cbPeripheral.
 
 The BLE services discovered by cbPeripheral are encapulated in instances of YMSCBService and
 contained in the dictionary serviceDict.
 
 */
// TODO: need to change to YMSCBPeripheralInterfaceDelegate
@interface YMSCBPeripheral : NSObject <YMSCBPeripheralInterfaceDelegate>

/** @name Properties */

/**
 Pointer to delegate.
 
 The delegate object will be forwarded CBPeripheralDelegate messages sent by cbPeripheral.
 
 */
@property(assign, nonatomic, nullable) id<YMSCBPeripheralDelegate> delegate;

/**
 Convenience accessor for cbPeripheral.name.
 */
@property(retain, readonly, nullable) NSString *name;

@property(readonly, nonatomic, nullable) NSUUID *identifier;

@property(readonly) CBPeripheralState state;

@property(retain, readonly, nullable) NSArray<YMSCBService *> *services;

/// Object which conforms to YMSCBPeripheralInterface
@property (nonatomic, strong, nullable) id<YMSCBPeripheralInterface> peripheralInterface;

/**
 Pointer to an instance of YMSCBCentralManager.
 */
@property (nonatomic, weak, nullable) YMSCBCentralManager *central;



/// 128 bit address base
@property (nonatomic, assign) yms_u128_t base;

/**
 Flag to indicate if the watchdog timer has expired and forced a disconnect.
 */
@property (nonatomic, assign) BOOL watchdogRaised;

/** 
 Dictionary of (`key`, `value`) pairs of (NSString, YMSCBService) instances.
 
 The NSString `key` is typically a "human-readable" string to easily reference a YMSCBService.
 */
//@property (nonatomic, strong, readonly) NSDictionary<NSString *, YMSCBService*> *serviceDict;


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
 Watchdog timer for connection.
 */
@property (nonatomic, strong, nullable) NSTimer *watchdogTimer;

/**
 Watchdog timer interval in seconds. Default is 5 seconds.
 */
@property (nonatomic, assign) NSTimeInterval watchdogTimerInterval;

/// Holds callback for connection established.
@property (atomic, copy, nullable) YMSCBPeripheralConnectCallbackBlockType connectCallback;

/// Holds callback for services discovered.
@property (nonatomic, copy, nullable) YMSCBPeripheralDiscoverServicesBlockType discoverServicesCallback;


@property (nonatomic, strong, nullable) id<YMSCBLogging> logger;


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
- (nullable instancetype)initWithPeripheral:(id<YMSCBPeripheralInterface>) yPeripheral
                                    central:(YMSCBCentralManager *)owner
                                     baseHi:(int64_t)hi
                                     baseLo:(int64_t)lo;



/** @name Get all CBService CBUUIDs for this peripheral  */
/**
 Generate array of CBUUID for all CoreBluetooth services associated with this peripheral.
 
 The output of this method is to be passed to the method discoverServices: in CBPeripheral:
 
 @return array of CBUUID services
 */

- (NSArray<CBUUID *> *)serviceUUIDs;


/**
 Return array of CBUUIDs for YMSCBService instances in serviceDict whose key is included in keys.
 
 - parameter keys: array of NSString keys, where each key must exist in serviceDict
 
 - returns: array of CBUUIDs
 */
- (NSArray<CBUUID *> *)servicesSubset:(NSArray<NSString *> *)keys;


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
- (void)connectWithOptions:(nullable NSDictionary *)options withBlock:(void (^)(YMSCBPeripheral * _Nullable yp, NSError * _Nullable error))connectCallback;

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
- (nullable YMSCBService *)objectForKeyedSubscript:(NSString *)key;

- (void)setObject:(YMSCBService *)obj forKeyedSubscript:(NSString *)key;

- (nullable YMSCBService *)serviceForUUID:(CBUUID *)uuid;

//- (void)replaceCBPeripheral:(CBPeripheral *)peripheral;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
