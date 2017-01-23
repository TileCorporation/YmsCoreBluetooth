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

#import "DEAAccelerometerService.h"
#import "YMSCBCharacteristic.h"


float calcAccel(int16_t rawV) {
    float v;
    v = ((float)rawV + 1.0) / (256.0/4.0);
    return v;
}

@interface DEAAccelerometerService ()

@property (nonatomic, strong) NSNumber *x;
@property (nonatomic, strong) NSNumber *y;
@property (nonatomic, strong) NSNumber *z;
@property (nonatomic, strong) NSNumber *period;

@end


@implementation DEAAccelerometerService


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
        [self addCharacteristic:@"data" withBLEOffset:kSensorTag_ACCELEROMETER_DATA];
        [self addCharacteristic:@"config" withBLEOffset:kSensorTag_ACCELEROMETER_CONFIG];
        [self addCharacteristic:@"period" withBLEOffset:kSensorTag_ACCELEROMETER_PERIOD];
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
        int8_t xx = val[0];
        int8_t yy = val[1];
        int8_t zz = val[2];
        
        __weak DEAAccelerometerService *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            [self willChangeValueForKey:@"sensorValues"];
            this.x = @(calcAccel(xx));
            this.y = @(calcAccel(yy));
            this.z = @(calcAccel(zz));
            [self didChangeValueForKey:@"sensorValues"];
        });
    }];
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isOn = YES;
    });
}


- (void)configPeriod:(uint8_t)value {
    
    YMSCBCharacteristic *periodCt = self.characteristicDict[@"period"];
    __weak DEAAccelerometerService *this = self;
    [periodCt writeByte:value withBlock:^(NSError *error) {
        //NSLog(@"Set period to: %x", value);
        if (error) {
            NSLog(@"ERROR: %@", [error localizedDescription]);
            this.period = this.period;
        } else {
            _YMS_PERFORM_ON_MAIN_THREAD(^{
                this.period = @(value);
            });
        }
    }];
}

- (void)requestReadPeriod {
    YMSCBCharacteristic *periodCt = self.characteristicDict[@"period"];
    
    __weak DEAAccelerometerService *this = self;
    
    [periodCt readValueWithBlock:^(NSData *data, NSError *error) {
        char val[data.length];
        [data getBytes:&val length:data.length];
        
        int16_t periodValue = val[0];
        
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            this.period = @(periodValue);
        });
    }];
}

- (NSDictionary *)sensorValues
{
    return @{ @"x": self.x,
              @"y": self.y,
              @"z": self.z };
}

@end
