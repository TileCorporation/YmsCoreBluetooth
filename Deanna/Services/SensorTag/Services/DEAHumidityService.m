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

#import "DEAHumidityService.h"
#import "YMSCBCharacteristic.h"

double calcHumTmp(uint16_t rawT) {
    double v;
    v = -46.85 + 175.72/65536 *(double)rawT;
    return v;
}

double calcHumRel(uint16_t rawH) {
    double v;
    v = -6.0 + (125.0/65536.0) * (double)rawH;
    return v;
}

@interface DEAHumidityService ()

@property (nonatomic, strong) NSNumber *ambientTemp;
@property (nonatomic, strong) NSNumber *relativeHumidity;

@end


@implementation DEAHumidityService

- (instancetype)initWithName:(NSString *)oName
                      parent:(YMSCBPeripheral *)pObj
                      baseHi:(int64_t)hi
                      baseLo:(int64_t)lo
               serviceOffset:(int)serviceOffset {
    
    self = [super initWithName:oName
                        parent:pObj
                        baseHi:hi
                        baseLo:lo
                 serviceOffset:serviceOffset];
    
    if (self) {
        [self addCharacteristic:@"data" withOffset:kSensorTag_HUMIDITY_DATA];
        [self addCharacteristic:@"config" withOffset:kSensorTag_HUMIDITY_CONFIG];
    }
    return self;
    
}



- (void)turnOn {
    __weak DEABaseService *this = self;
    
    YMSCBCharacteristic *configCt = self.characteristicDict[@"config"];
    [configCt writeByte:0x1 withBlock:^(NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
            return;
        }
        
        NSLog(@"TURNED ON: %@", this.name);
    }];
    
    YMSCBCharacteristic *dataCt = self.characteristicDict[@"data"];
    [dataCt setNotifyValue:YES withStateChangeBlock:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
            return;
        }
        
        NSLog(@"Data notification for %@ on", this.name);
        
    } withNotificationBlock:^(NSData * _Nonnull data, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
            return;
        }
        
        NSLog(@"Data notification received %@ for %@", data, this.name);
        char val[data.length];
        
        [data getBytes:&val length:data.length];
        
        uint16_t v0 = val[0];
        uint16_t v1 = val[1];
        uint16_t v2 = val[2];
        uint16_t v3 = val[3];
        
        uint16_t rawTemperature = yms_u16_build(v0, v1);
        uint16_t rawHumidity = yms_u16_build(v2, v3);
        
        __weak DEAHumidityService *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            [self willChangeValueForKey:@"sensorValues"];
            this.ambientTemp = @(calcHumTmp(rawTemperature));
            this.relativeHumidity = @(calcHumRel(rawHumidity));
            [self didChangeValueForKey:@"sensorValues"];
        });

        
    }];
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isOn = YES;
    });
}


- (NSDictionary *)sensorValues
{
    return @{ @"ambientTemp": self.ambientTemp,
              @"relativeHumidity": self.relativeHumidity };
}

@end
