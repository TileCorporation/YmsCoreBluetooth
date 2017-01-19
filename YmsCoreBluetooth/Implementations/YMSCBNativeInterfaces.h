//
//  YMSCBNativeInterfaces.h
//  Deanna
//
//  Created by Charles Choi on 1/18/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@protocol YMSCBCentralManagerInterface;
@protocol YMSCBPeripheralInterface;
@protocol YMSCBCharacteristicInterface;
@protocol YMSCBDescriptorInterface;

@interface CBCentralManager () <YMSCBCentralManagerInterface>

@end

@interface CBPeripheral () <YMSCBPeripheralInterface>

@end

@interface CBService () <YMSCBServiceInterface>

@end

@interface CBCharacteristic () <YMSCBCharacteristicInterface>

@end

@interface CBDescriptor () <YMSCBDescriptorInterface>

@end
