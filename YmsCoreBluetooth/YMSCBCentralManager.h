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

// iOS7
#define kYMSCBVersionNumber 1090
#define kYMSCBVersion "1.090"
extern NSString *const YMSCBVersion;

@class YMSCBPeripheral;
@class YMSCBCentralManager;
@protocol YMSCBCentralManagerInterface;
@protocol YMSCBCentralManagerInterfaceDelegate;
@protocol YMSCBCentralManagerDelegate;
@protocol YMSCBPeripheralInterface;
@protocol YMSCBPeripheralDelegate;

typedef void (^YMSCBDiscoverCallbackBlockType)(YMSCBPeripheral *yPeripheral, NSDictionary *advertisingData, NSNumber *RSSI);
typedef BOOL (^YMSCBFilterCallbackBlockType)(NSString *name, NSDictionary *advertisingData, NSNumber *RSSI);
typedef void (^YMSCBRetrieveCallbackBlockType)(YMSCBPeripheral *yPeripheral);

// ------------------------------------------------------------------------


/**
 Interface to shadow properties and methods on CBCentralManager
 */
@protocol YMSCBCentralManagerInterface

@property(assign, nonatomic, nullable) id<YMSCBCentralManagerInterfaceDelegate> delegate;

@property(readonly) CBCentralManagerState state;


- (nullable instancetype)initWithDelegate:(nullable id<YMSCBCentralManagerInterfaceDelegate>)delegate
                                    queue:(nullable dispatch_queue_t)queue;

- (nullable instancetype)initWithDelegate:(nullable id<YMSCBCentralManagerInterfaceDelegate>)delegate
                                    queue:(nullable dispatch_queue_t)queue
                                  options:(nullable NSDictionary<NSString *, id> *)options;

- (nullable NSArray<id<YMSCBPeripheralInterface>> *)retrievePeripheralsWithIdentifiers:(nullable NSArray<NSUUID *> *)identifiers;

- (nullable NSArray<id<YMSCBPeripheralInterface>> *)retrieveConnectedPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;

- (void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options;

- (void)stopScan;

- (void)connectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface options:(nullable NSDictionary<NSString *, id> *)options;

- (void)cancelPeripheralConnection:(id<YMSCBPeripheralInterface>)peripheralInterface;

@end

// ------------------------------------------------------------------------

@protocol YMSCBCentralManagerInterfaceDelegate <NSObject>

@required
- (void)centralManagerDidUpdateState:(id<YMSCBCentralManagerInterface>)centralInterface;

@optional
- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface willRestoreState:(NSDictionary<NSString *, id> *)dict;
- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didDiscoverPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI;
- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didConnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface;
- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didFailToConnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error;
- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didDisconnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error;
@end

// ------------------------------------------------------------------------

@protocol YMSCBCentralManagerDelegate <NSObject>

@required
- (void)centralManagerDidUpdateState:(YMSCBCentralManager *)yCentral;

@optional
- (void)centralManager:(YMSCBCentralManager *)yCentral willRestoreState:(NSDictionary<NSString *, id> *)dict;
- (void)centralManager:(YMSCBCentralManager *)yCentral didDiscoverPeripheral:(YMSCBPeripheral *)yPeripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI;
- (void)centralManager:(YMSCBCentralManager *)yCentral didConnectPeripheral:(YMSCBPeripheral *)yPeripheral;
- (void)centralManager:(YMSCBCentralManager *)yCentral didFailToConnectPeripheral:(YMSCBPeripheral *)yPeripheral error:(nullable NSError *)error;
- (void)centralManager:(YMSCBCentralManager *)yCentral didDisconnectPeripheral:(YMSCBPeripheral *)yPeripheral error:(nullable NSError *)error;
@end

// ------------------------------------------------------------------------

/**
 Base class for defining a Bluetooth LE central.
 
 YMSCBCentralManager holds an instance of YMSCBCentralManagerInterface centralInterface and implements the
 CBCentralManagerDelgate messages sent by manager.
 
 This class provides ObjectiveC block-based callback support for peripheral
 scanning and retrieval.
 
 YMSCBCentralManager is intended to be subclassed: the subclass would in turn be written to 
 handle the set of BLE peripherals of interest to the application.
 
 The subclass is typically implemented (though not necessarily) as a singleton, so that there 
 is only one instance of CBCentralManager that is used by the application.

 All discovered BLE peripherals are stored in the array ymsPeripherals.

 */
@interface YMSCBCentralManager : NSObject <YMSCBCentralManagerInterfaceDelegate, YMSCBLogging>

/** @name Properties */
/**
 Pointer to delegate.
 
 The delegate object will be sent CBCentralManagerDelegate messages received by manager.
 */
@property(assign, nonatomic, nullable) id<YMSCBCentralManagerDelegate> delegate;

@property(readonly) CBCentralManagerState state;

@property (nonatomic, strong, nullable) id<YMSCBLogging> logger;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) dispatch_queue_t ymsPeripheralsQueue;

/**
 The CBCentralManager object.
 
 In typical practice, there is only one instance of CBCentralManager and it is located in a singleton instance of YMSCBCentralManager.
 This class listens to CBCentralManagerDelegate messages sent by manager, which in turn forwards those messages to delegate.
 */
@property (nonatomic, strong) id<YMSCBCentralManagerInterface> centralInterface;

/// Flag to determine if manager is scanning.
@property (atomic, assign) BOOL isScanning;

/**
 Array of YMSCBPeripheral instances.
 
 This array holds all YMSCBPeripheral instances discovered or retrieved by manager.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, YMSCBPeripheral *> *ymsPeripherals;

/// Count of ymsPeripherals.
@property (atomic, readonly, assign) NSUInteger count;

/// API version.
@property (atomic, readonly, assign) NSString *version;


/// Peripheral Discovered Callback
@property (atomic, copy, nullable) YMSCBDiscoverCallbackBlockType discoveredCallback;

@property (atomic, copy, nullable) YMSCBFilterCallbackBlockType filteredCallback;

// TODO: is this obsolete?
/// Peripheral Retreived Callback
@property (atomic, copy, nullable) YMSCBRetrieveCallbackBlockType retrievedCallback;

#pragma mark - Constructors

/** @name Initializing YMSCBCentralManager */

/**
 Constructor for YMSCBCentralManager
 
 This is wrapper

 @param delegate Delegate of this class instance.
 @param queue The dispatch queue for BLE central role events.
 @param options CBCentralManager options
 @return instance of YMSCBCentralManager
 */
- (nullable instancetype)initWithDelegate:(nullable id<YMSCBCentralManagerDelegate>)delegate
                                    queue:(nullable dispatch_queue_t)queue
                                  options:(nullable NSDictionary<NSString *, id> *)options
                                   logger:(id<YMSCBLogging>)logger;


#pragma mark - Peripheral Management
/** @name Peripheral Management */


/**
 Factory method for creating new instances that inherit from YMSCBPeripheral
 

 @param peripheralInterface object which conforms to YMSCBPeripheralInterface
 @return instance of YMSCBPeripheral
 */
- (nullable YMSCBPeripheral *)ymsPeripheralWithInterface:(id<YMSCBPeripheralInterface>)peripheralInterface;

- (void)addPeripheral:(YMSCBPeripheral *)yPeripheral;

- (void)removePeripheral:(YMSCBPeripheral *)yPeripheral;

/**
 Find YMSCBPeripheral instance matching peripheral
 @param peripheral peripheral corresponding with YMSCBPeripheral
 @return instance of YMSCBPeripheral
 */
- (nullable YMSCBPeripheral *)findPeripheral:(nonnull YMSCBPeripheral *)yPeripheral;

#pragma mark - Scan Methods
/** @name Scanning for Peripherals */
/**
 Start CoreBluetooth scan for peripherals. This method is to be overridden.
 
 The implementation of this method in a subclass must include the call to
 scanForPeripheralsWithServices:options:
 
 */
- (BOOL)startScan;

/**
 Wrapper around the method scanForPeripheralWithServices:options: in CBCentralManager.
 
 If this method is invoked without involving a callback block, you must implement handleFoundPeripheral:.
 
 @param serviceUUIDs An array of CBUUIDs the app is interested in.
 @param options A dictionary to customize the scan, see CBCentralManagerScanOptionAllowDuplicatesKey.
 */
- (BOOL)scanForPeripheralsWithServices:(nullable NSArray *)serviceUUIDs options:(nullable NSDictionary *)options;

/**
 Scans for peripherals that are advertising service(s), invoking a callback block for each peripheral
 that is discovered.

 @param serviceUUIDs An array of CBUUIDs the app is interested in.
 @param options A dictionary to customize the scan, see CBCentralManagerScanOptionAllowDuplicatesKey.
 @param discoverCallback Callback block to execute upon discovery of a peripheral. 
 The parameters of discoverCallback are:
 
 * `peripheral` - the discovered peripheral.
 * `advertisementData` - A dictionary containing any advertisement data.
 * `RSSI` - The current received signal strength indicator (RSSI) of the peripheral, in decibels.
 * `error` - The cause of a failure, if any.
 
 */
- (BOOL)scanForPeripheralsWithServices:(nullable NSArray *)serviceUUIDs
                               options:(nullable NSDictionary *)options
                             withBlock:(nullable YMSCBDiscoverCallbackBlockType)discoverCallback
                             withFilter:(nullable YMSCBFilterCallbackBlockType)filterCallback;


/**
 Stop CoreBluetooth scan for peripherals.
 */
- (void)stopScan;


#pragma mark - Retrieve Methods
/** @name Retrieve Peripherals */

/**
 Retrieves a list of known peripherals by their UUIDs.
 
 @param identifiers A list of NSUUID objects.
 @return A list of peripherals.
 */
- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;

/**
 Retrieves a list of the peripherals currently connected to the system and handles them using
 handleFoundPeripheral:
 

 Retrieves all peripherals that are connected to the system and implement 
 any of the services listed in <i>serviceUUIDs</i>.
 Note that this set can include peripherals which were connected by other 
 applications, which will need to be connected locally
 via connectPeripheral:options: before they can be used.

 @param serviceUUIDS A list of NSUUID services
 @return A list of CBPeripheral objects.
 */
- (NSArray *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDs;

- (void)connectPeripheral:(YMSCBPeripheral *)yPeripheral options:(nullable NSDictionary<NSString *, id> *)options;

- (void)cancelPeripheralConnection:(YMSCBPeripheral *)yPeripheral;


#pragma mark - CBCentralManager state handling methods
/** @name CBCentralManager manager state handling methods */
 
/**
 Handler for when manager state is powered on.
 */
- (void)managerPoweredOnHandler;

/**
 Handler for when manager state is unknown.
 */
- (void)managerUnknownHandler;

/**
 Handler for when manager state is powered off
 */
- (void)managerPoweredOffHandler;

/**
 Handler for when manager state is resetting.
 */
- (void)managerResettingHandler;

/**
 Handler for when manager state is unauthorized.
 */
- (void)managerUnauthorizedHandler;

/**
 Handler for when manager state is unsupported.
 */
- (void)managerUnsupportedHandler;

@end

NS_ASSUME_NONNULL_END
