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


#import "DEACentralManager.h"
#import "DEASensorTag.h"
#include "TISensorTag.h"
#import "YMSCBLogger.h"
#import "YMSCBPeripheral.h"
#import "SensorTagStimulusGenerator.h"

#if TARGET_IPHONE_SIMULATOR
#import "YMSBFMCentralManager.h"
#endif

#define CALLBACK_EXAMPLE 1

static DEACentralManager *sharedCentralManager;

@interface DEACentralManager()


@end


@implementation DEACentralManager

+ (DEACentralManager *)initSharedServiceWithDelegate:(id)delegate {
    if (sharedCentralManager == nil) {
        dispatch_queue_t queue = dispatch_queue_create("com.yummymelon.deanna", DISPATCH_QUEUE_CONCURRENT);
        sharedCentralManager = [[super allocWithZone:NULL] initWithDelegate:delegate
                                                                      queue:queue
                                                                    options:nil
                                                                     logger:[YMSCBLogger new]];
#if TARGET_IPHONE_SIMULATOR
        SensorTagStimulusGenerator *stimulusGenerator = [[SensorTagStimulusGenerator alloc] init];
        YMSBFMCentralManager *centralInterface = (YMSBFMCentralManager *)sharedCentralManager.centralInterface;
        centralInterface.stimulusGenerator = stimulusGenerator;
#endif
    }
    return sharedCentralManager;
    
}


+ (nullable DEACentralManager *)sharedService {
    if (sharedCentralManager == nil) {
        NSLog(@"ERROR: must call initSharedServiceWithDelegate: first.");
    }
    return sharedCentralManager;
}


- (BOOL)startScan {
    /*
     Setting CBCentralManagerScanOptionAllowDuplicatesKey to YES will allow for repeated updates of the RSSI via advertising.
     */
    
    NSDictionary *options = @{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES };
    // NOTE: TI SensorTag firmware does not included services in advertisementData.
    // This prevents usage of serviceUUIDs array to filter on.

    /*
     Note that in this implementation, handleFoundPeripheral: is implemented so that it can be used via block callback or as a
     delagate handler method. This is an implementation specific decision to handle discovered and retrieved peripherals identically.

     This may not always be the case, where for example information from advertisementData and the RSSI are to be factored in.
     */
    
    
#ifdef CALLBACK_EXAMPLE
    
    __weak typeof(self) this = self;
    BOOL result = [self scanForPeripheralsWithServices:nil
                                 options:options
                               withBlock:^(YMSCBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
                                   __strong typeof (this) strongThis = this;
                                   
                                   //NSLog(@"DISCOVERED: %@, %@, %@ db", peripheral, peripheral.name, RSSI);
                                   NSString *message = [NSString stringWithFormat:@"DISCOVERED: %@, %@, %@ db", peripheral, peripheral.name, RSSI];
                                   
                                   if (strongThis) {
                                       [strongThis.logger logInfo:message object:nil];
                                   }
                                   
                               }
     
                              withFilter:^BOOL(NSString *name, NSDictionary * _Nonnull advertisementData, NSNumber * _Nonnull RSSI) {
                                  
                                  BOOL result = NO;
                                  if (name &&
                                      (RSSI.integerValue < 0) &&
                                      (RSSI.integerValue > -55) &&
                                      [name containsString:@"Sensor"]
                                      ) {
                                      result = YES;
                                  }
                                  return result;
                              }];
    
#else
    BOOL result = [self scanForPeripheralsWithServices:nil options:options];
#endif
    return result;
}

- (nullable YMSCBPeripheral *)ymsPeripheralWithInterface:(id<YMSCBPeripheralInterface>)peripheralInterface {
    YMSCBPeripheral *result = nil;
    
    if ([peripheralInterface.name containsString:@"Sensor"] && peripheralInterface.identifier) {
        DEASensorTag *sensorTag = [[DEASensorTag alloc] initWithPeripheral:peripheralInterface
                                                                   central:self
                                                                    baseHi:kSensorTag_BASE_ADDRESS_HI
                                                                    baseLo:kSensorTag_BASE_ADDRESS_LO];
        
        result = sensorTag;
    }
    return result;
}

- (NSArray *)peripherals {
    NSArray *result = nil;

    NSArray *sortedKeys = [[self.ymsPeripherals allKeys] sortedArrayUsingSelector: @selector(compare:)];
    NSMutableArray *sortedValues = [NSMutableArray array];
    for (NSString *key in sortedKeys)
        [sortedValues addObject: [self.ymsPeripherals objectForKey: key]];
    
    result = [NSArray arrayWithArray:sortedValues];
    return result;
}

- (YMSCBPeripheral *)peripheralAtIndex:(NSUInteger)index {
    YMSCBPeripheral *result = nil;
    result = [[self peripherals] objectAtIndex:index];
    return result;
}



- (void)managerPoweredOnHandler {
    
}



@end
