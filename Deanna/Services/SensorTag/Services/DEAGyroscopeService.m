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

#import "DEAGyroscopeService.h"
#import "YMSCBCharacteristic.h"

float calcGyro(int16_t v, float c, int16_t d) {
    float result;
    
    result = (((float)v * d) / (65536/500.0)) - c;
    
    return result;
}

@interface DEAGyroscopeService ()

@property (nonatomic, strong) NSNumber *roll;
@property (nonatomic, strong) NSNumber *pitch;
@property (nonatomic, strong) NSNumber *yaw;

@property (nonatomic, assign) float lastRoll;
@property (nonatomic, assign) float lastPitch;
@property (nonatomic, assign) float lastYaw;

@property (nonatomic, assign) float cRoll;
@property (nonatomic, assign) float cPitch;
@property (nonatomic, assign) float cYaw;

@end

@implementation DEAGyroscopeService

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
        [self addCharacteristic:@"data" withBLEOffset:kSensorTag_GYROSCOPE_DATA];
        [self addCharacteristic:@"config" withBLEOffset:kSensorTag_GYROSCOPE_CONFIG];
        _lastPitch = 0.0;
        _lastRoll = 0.0;
        _lastYaw = 0.0;
        _cPitch = 0.0;
        _cRoll = 0.0;
        _cYaw = 0.0;
    }
    return self;
}


- (void)turnOn {
    __weak DEABaseService *this = self;
    
    YMSCBCharacteristic *configCt = self.characteristicDict[@"config"];
    [configCt writeByte:0x7 withBlock:^(NSError *error) {
        if (error) {
            return;
        }
        NSLog(@"Turned On: %@", this.name);
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
        uint16_t v4 = val[4];
        uint16_t v5 = val[5];
        
        uint16_t xx = yms_u16_build(v0, v1);
        uint16_t yy = yms_u16_build(v2, v3);
        uint16_t zz = yms_u16_build(v4, v5);
        
        self.lastRoll = calcGyro(zz, self.cRoll, 1);
        self.lastPitch = calcGyro(yy, self.cPitch, -1);
        self.lastYaw = calcGyro(xx, self.cYaw, 1);
        
        __weak DEAGyroscopeService *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            [self willChangeValueForKey:@"sensorValues"];
            this.roll = @(self.lastRoll);
            this.pitch = @(self.lastPitch);
            this.yaw = @(self.lastYaw);
            [self didChangeValueForKey:@"sensorValues"];
        });

    }];
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isOn = YES;
    });
}


- (void)calibrate {
    self.cRoll = self.lastRoll;
    self.cPitch = self.lastPitch;
    self.cYaw = self.lastYaw;
}


- (NSDictionary *)sensorValues
{
    return @{ @"roll": self.roll,
              @"pitch": self.pitch,
              @"yaw": self.yaw };
}

@end
