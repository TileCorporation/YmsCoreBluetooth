//
//  SensorTagStimulusGenerator.m
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "SensorTagStimulusGenerator.h"
#import "YMSBFMPeripheral.h"
#import "YMSBFMModelConfiguration.h"
#import "YMSBFMSyntheticValue.h"

@implementation SensorTagStimulusGenerator

- (void)genPeripherals {
    [super genPeripherals];
    
    for (YMSBFMPeripheral *peripheral in [self.peripherals allValues]) {
        NSDictionary<NSString *, id> *peripheralModelConfig = self.modelConfiguration.peripherals[peripheral.identifier.UUIDString];
        
        peripheral.syntheticRSSI = [[YMSBFMSyntheticValue alloc] initWithJSON:peripheralModelConfig[@"rssi"]];
    }
}

@end
