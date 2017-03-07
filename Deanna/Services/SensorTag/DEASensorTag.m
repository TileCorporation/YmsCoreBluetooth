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

#import "DEASensorTag.h"
#import "DEABaseService.h"
#import "DEAAccelerometerService.h"
#import "DEABarometerService.h"
#import "DEADeviceInfoService.h"
#import "DEAGyroscopeService.h"
#import "DEAHumidityService.h"
#import "DEAMagnetometerService.h"
#import "DEASimpleKeysService.h"
#import "DEATemperatureService.h"
#import "YMSCBCharacteristic.h"
#import "YMSCBDescriptor.h"
#import "TISensorTag.h"


@implementation DEASensorTag

- (instancetype)initWithPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface
                           central:(YMSCBCentralManager *)owner
                            baseHi:(int64_t)hi
                            baseLo:(int64_t)lo {

    self = [super initWithPeripheral:peripheralInterface central:owner baseHi:hi baseLo:lo];
    
    if (self) {
        DEATemperatureService *ts = [[DEATemperatureService alloc] initWithName:@"temperature" parent:self baseHi:hi baseLo:lo serviceOffset:kSensorTag_TEMPERATURE_SERVICE];
        self[@"temperature"] = ts;

        DEAAccelerometerService *as = [[DEAAccelerometerService alloc] initWithName:@"accelerometer" parent:self baseHi:hi baseLo:lo serviceOffset:kSensorTag_ACCELEROMETER_SERVICE];
        self[@"accelerometer"] = as;
        
        DEASimpleKeysService *sks = [[DEASimpleKeysService alloc] initWithName:@"simplekeys" parent:self baseHi:0 baseLo:0 serviceOffset:kSensorTag_SIMPLEKEYS_SERVICE];
        self[@"simplekeys"] = sks;
        
        DEAHumidityService *hs = [[DEAHumidityService alloc] initWithName:@"humidity" parent:self baseHi:hi baseLo:lo serviceOffset:kSensorTag_HUMIDITY_SERVICE];
        self[@"humidity"] = hs;
        
        DEABarometerService *bs = [[DEABarometerService alloc] initWithName:@"barometer" parent:self baseHi:hi baseLo:lo serviceOffset:kSensorTag_BAROMETER_SERVICE];
        self[@"barometer"] = bs;
        
        DEAGyroscopeService *gs = [[DEAGyroscopeService alloc] initWithName:@"gyroscope" parent:self baseHi:hi baseLo:lo serviceOffset:kSensorTag_GYROSCOPE_SERVICE];
        self[@"gyroscope"] = gs;
        
        DEAMagnetometerService *ms = [[DEAMagnetometerService alloc] initWithName:@"magnetometer" parent:self baseHi:hi baseLo:lo serviceOffset:kSensorTag_MAGNETOMETER_SERVICE];
        self[@"magnetometer"] = ms;
        
        DEADeviceInfoService *ds = [[DEADeviceInfoService alloc] initWithName:@"devinfo" parent:self baseHi:0 baseLo:0 serviceOffset:kSensorTag_DEVINFO_SERV_UUID];
        self[@"devinfo"] = ds;
    }

    return self;
}

- (void)connect {
    // Watchdog aware method
    [self resetWatchdog];
    
    __weak typeof(self) this = self;
    
    [self connectWithOptions:nil withBlock:^(YMSCBPeripheral *yp, NSError *error) {
        if (error) {
            return;
        }
        
        // Example where only a subset of services is to be discovered.
        //[yp discoverServices:[yp servicesSubset:@[@"temperature", @"simplekeys", @"devinfo"]] withBlock:^(NSArray *yservices, NSError *error) {
        
        [yp discoverServices:[yp serviceUUIDs] withBlock:^(NSArray *yservices, NSError *error) {
            if (error) {
                return;
            }
            
            for (YMSCBService *service in yservices) {
                if ([service.name isEqualToString:@"simplekeys"]) {
                    __weak DEASimpleKeysService *thisService = (DEASimpleKeysService *)service;
                    [service discoverCharacteristics:[service characteristicUUIDs] withBlock:^(NSDictionary *chDict, NSError *error) {
                        [thisService turnOn];
                    }];
                    
                } else if ([service.name isEqualToString:@"devinfo"]) {
                    __weak DEADeviceInfoService *thisService = (DEADeviceInfoService *)service;
                    [service discoverCharacteristics:[service characteristicUUIDs] withBlock:^(NSDictionary *chDict, NSError *error) {
                        [thisService readDeviceInfo];
                    }];
                    
                } else {
                    __weak DEABaseService *thisService = (DEABaseService *)service;
                    [service discoverCharacteristics:[service characteristicUUIDs] withBlock:^(NSDictionary *chDict, NSError *error) {
                        if (error) {
                            NSString *message = [NSString stringWithFormat:@"%@", error];
                            [this.logger logError:message object:this];
                            return;
                        }
                        
                        for (NSString *key in chDict) {
                            YMSCBCharacteristic *ct = chDict[key];
                            NSLog(@"%@ %@ %@", ct, ct.characteristicInterface, ct.UUID);
                            
                            [ct discoverDescriptorsWithBlock:^(NSArray *yDescriptors, NSError *error) {
                                if (error) {
                                    return;
                                }
                                for (YMSCBDescriptor *yd in yDescriptors) {
                                    NSLog(@"Descriptor: %@ %@ %@", thisService.name, yd.UUID, yd.descriptorInterface);
                                }
                            }];
                            
                        }

                    }];
                }
            }
        }];
    }];
}


- (DEAAccelerometerService *)accelerometer {
    return (DEAAccelerometerService *)self[@"accelerometer"];
}

- (DEABarometerService *)barometer {
    return (DEABarometerService *)self[@"barometer"];
}

- (DEADeviceInfoService *)devinfo {
    return (DEADeviceInfoService *)self[@"devinfo"];
}

- (DEAGyroscopeService *)gyroscope {
    return (DEAGyroscopeService *)self[@"gyroscope"];
}

- (DEAHumidityService *)humidity {
    return (DEAHumidityService *)self[@"humidity"];
}

- (DEAMagnetometerService *)magnetometer {
    return (DEAMagnetometerService *)self[@"magnetometer"];
}

- (DEASimpleKeysService *)simplekeys {
    return (DEASimpleKeysService *)self[@"simplekeys"];
}

- (DEATemperatureService *)temperature {
    return (DEATemperatureService *)self[@"temperature"];
}

@end
