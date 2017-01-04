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

#import "DEASimpleKeysService.h"
#import "YMSCBCharacteristic.h"

@interface DEASimpleKeysService ()

@property (nonatomic, strong) NSNumber *keyValue;

@end

@implementation DEASimpleKeysService


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
        [self addCharacteristic:@"data" withAddress:kSensorTag_SIMPLEKEYS_DATA];
    }
    return self;
}


- (void)turnOff {
    __weak DEASimpleKeysService *this = self;
    YMSCBCharacteristic *ct = self.characteristicDict[@"data"];
    [ct setNotifyValue:NO withStateChangeBlock:^(NSError * _Nonnull error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
            return;
        }
        
        NSLog(@"Data notification for %@ off", this.name);

      
    } withNotificationBlock:nil];
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isOn = NO;
    });
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
        
        
        int16_t value = val[0];
        
        __weak typeof(self) this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(this) strongThis = this;
            
            [strongThis willChangeValueForKey:@"sensorValues"];
            strongThis.keyValue = [NSNumber numberWithInt:value];
            [strongThis didChangeValueForKey:@"sensorValues"];
        });
    }];
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isOn = YES;
    });
}


- (NSDictionary *)sensorValues
{
    return @{ @"keyValue": self.keyValue };
}

@end
