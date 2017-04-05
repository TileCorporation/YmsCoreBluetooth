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


#import "YMSCBCentralManager.h"

NS_ASSUME_NONNULL_BEGIN

@class YMSCBPeripheral;

/**
 Application CoreBluetooth central manager service for Deanna.
 
 This class defines a singleton application service instance which manages access to
 the TI SensorTag via the CoreBluetooth API. 
 
 */
@interface DEACentralManager : YMSCBCentralManager


+ (instancetype)initSharedServiceWithCentral:(nullable id<YMSCBCentralManagerInterface>)centralInterface
                                    delegate:(nullable id<YMSCBCentralManagerDelegate>)delegate
                                       queue:(nullable dispatch_queue_t)queue
                                     options:(nullable NSDictionary<NSString *, id> *)options
                                      logger:(id<YMSCBLogging>)logger;

/**
 Return singleton instance.
 */

+ (nullable DEACentralManager *)sharedService;

- (NSArray *)peripherals ;

/**
 Returns the YSMCBPeripheral instance from ymsPeripherals at index.
 @param index An index within the bounds of ymsPeripherals.
 */
- (nullable YMSCBPeripheral *)peripheralAtIndex:(NSUInteger)index;


NS_ASSUME_NONNULL_END
@end
