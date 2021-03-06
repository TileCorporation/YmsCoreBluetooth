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
@class YMSCBService;
@class YMSCBCharacteristic;
@class YMSCBDescriptor;

@protocol YMSCBServiceInterface;
@protocol YMSCBDescriptorInterface;
@protocol YMSCBPeripheralInterface;

@protocol YMSCBCharacteristicInterface

@property(assign, readonly, nonatomic) id<YMSCBServiceInterface>service;
@property(readonly, nonatomic) CBUUID *UUID;

@property(readonly, nonatomic) CBCharacteristicProperties properties;
@property(retain, readonly, nullable) NSData *value;
@property(retain, readonly, nullable) NSArray<id<YMSCBDescriptorInterface>> *descriptors;
@property(readonly) BOOL isBroadcasted;
@property(readonly) BOOL isNotifying;

@end


// TODO: define generics
typedef void (^YMSCBDiscoverDescriptorsCallbackBlockType)(NSArray * _Nullable, NSError * _Nullable);

typedef void (^YMSCBReadCallbackBlockType)(NSData * _Nullable, NSError * _Nullable);
typedef void (^YMSCBWriteCallbackBlockType)(NSError * _Nullable);

/**
 Base class for defining a Bluetooth LE characteristic.
 
 YMSCBCharacteristic holds an instance of CBCharacteristic (cbCharacteristic).
 
 This class is typically instantiated by a subclass of YMSCBService. The property
 cbCharacteristic is set in [YMSCBService syncCharacteristics:]
 
 
 */
@interface YMSCBCharacteristic : NSObject

/** @name Properties */
/// Human-friendly name for this BLE characteristic.
@property (atomic, strong) NSString *name;

/// Characterisic CBUUID.
@property (atomic, strong) CBUUID *UUID;

/// Pointer to actual CBCharacterisic.
@property (atomic, strong, nullable) id<YMSCBCharacteristicInterface> characteristicInterface;

/// Pointer to parent peripheral.
@property (nonatomic, weak) YMSCBPeripheral *parent;

// TODO: define generics
/// Holds instances of YMSCBDescriptor
@property (nonatomic, strong) NSArray<YMSCBDescriptor *> *descriptors;

/// Notification state callback
@property (atomic, copy, nullable) YMSCBWriteCallbackBlockType notificationStateCallback;

/// Notification callback
@property (atomic, copy, nullable) YMSCBReadCallbackBlockType notificationCallback;

/// Callback for descriptors that are discovered.
@property (atomic, copy, nullable) YMSCBDiscoverDescriptorsCallbackBlockType discoverDescriptorsCallback;

/// When YES, logging is enabled
@property (atomic, assign) BOOL logEnabled;

/**
* FIFO queue for reads.
 
 Each element is a block of type YMSCBReadCallbackBlockType.
 */
// TODO: define generics
@property (atomic, strong) NSMutableArray *readCallbacks;

/**
 FIFO queue for writes.
 
 Each element is a block of type YMSCBWriteCallbackBlockType.
 */
// TODO: define generics
@property (atomic, strong) NSMutableArray *writeCallbacks;

@property (nonatomic, strong, nullable) id<YMSCBLogging> logger;


/** @name Callback Handler Methods */
/**
 Handler method to process notificationStateCallback.
 
 @param error Error object, if failed.
 */
- (void)executeNotificationStateCallback:(NSError *)error;

/**
 Handler method to process first callback in readCallbacks.

 @param data Value returned from read request.
 @param error Error object, if failed.
 */
- (void)executeReadCallback:(NSData *)data error:(NSError *)error;

/**
 Handler method to process first callback in writeCallbacks.
 
 @param error Error object, if failed.
 */
- (void)executeWriteCallback:(nullable NSError *)error;

/** @name Initializing a YMSCBCharacteristic */
/**
 Constructor.
 
 https://github.com/kickingvegas/YmsCoreBluetooth/issues

 @param oName characteristic name
 @param pObj parent peripheral
 @param oUUID characteristic CBUUID
 */
- (instancetype)initWithName:(NSString *)oName parent:(YMSCBPeripheral *)pObj uuid:(CBUUID *)oUUID;


/** @name Changing the notification state */
/**
 Set notification value of cbCharacteristic.
 
 When notifyValue is YES, then cbCharacterisic is set to notify upon any changes to its value.
 When notifyValue is NO, then no notifications are sent.
 
 @param notifyValue Set notification enable.
 @param notifyStateCallback Callback to execute upon change in notification state.
 @param notificationCallback Callback to execute upon receiving notification.
 */
- (void)setNotifyValue:(BOOL)notifyValue
  withStateChangeBlock:(void (^)(NSError * _Nullable error))notifyStateCallback
 withNotificationBlock:(nullable void (^)(NSData *data, NSError * _Nullable error))notificationCallback;

/** @name Issuing a Write Request */
/**
 
 Issue write with value data and execute callback block writeCallback upon response.
 
 The callback block writeCallback has one argument: `error`:
 
 * `error` is populated with the returned `error` object from the delegate method 
 peripheral:didWriteValueForCharacteristic:error: implemented in YMSCBPeripheral.
 
 @param data The value to be written
 @param writeCallback Callback block to execute upon response.
 
 */
- (void)writeValue:(NSData *)data withBlock:(nullable void (^)(NSError *error))writeCallback;

/**
 Issue write with byte val and execute callback block writeCallback upon response.
 
 The callback block writeCallback has one argument: `error`:
 
 * `error` is populated with the returned `error` object from the delegate method 
 peripheral:didWriteValueForCharacteristic:error: implemented in YMSCBPeripheral.
 
 @param val Byte value to be written
 @param writeCallback Callback block to execute upon response.
 
 */
- (void)writeByte:(int8_t)val withBlock:(void (^)(NSError *error))writeCallback;


/** @name Issuing a Read Request */
/**
 Issue read and execute callback block readCallback upon response.
 
 The callback block readCallback has two arguments: `data` and `error`:
 
 * `data` is populated with the `value` property of [YMSCBCharacteristic cbCharacteristic].
 * `error` is populated with the returned `error` object from the delegate method peripheral:didUpdateValueForCharacteristic:error: implemented in YMSCBPeripheral.
 
 
 @param readCallback Callback block to execute upon response.
 */
- (void)readValueWithBlock:(void (^)(NSData *data, NSError *error))readCallback;

/** @name Discover Descriptors */
/**
 Discover descriptors for this characteristic.
 
 @param callback Callback block to execute upon response for discovered descriptors.
 */
- (void)discoverDescriptorsWithBlock:(void (^)(NSArray *ydescriptors, NSError *error))callback;

/**
 Handler method for discovered descriptors.
 
 @param ydescriptors Array of YMSCBDescriptor instances.
 @param error Error object, if failure.
 */
- (void)handleDiscoveredDescriptorsResponse:(NSArray *)ydescriptors withError:(NSError *)error;


- (void)syncDescriptors;

- (void)reset;

NS_ASSUME_NONNULL_END
@end
