//
//  DEAExternalCentral.m
//  Deanna
//
//  Created by Charles Choi on 3/8/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "DEAExternalCentral.h"
#import "YMSCBNativeInterfaces.h"

@implementation DEAExternalCentral

- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_queue_create("com.bose.connect", DISPATCH_QUEUE_CONCURRENT);
        _central = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:nil];
    }
    return self;
}

- (void)centralManagerDidUpdateState:(id<YMSCBCentralManagerInterface>)centralInterface {

    if ([self.delegate respondsToSelector:@selector(centralManagerDidUpdateState:)]) {
        [self.delegate centralManagerDidUpdateState:centralInterface];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        [self.delegate centralManager:central didConnectPeripheral:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        [self.delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
        [self.delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
        [self.delegate centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
    
}

@end
