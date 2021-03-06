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

#import "DEABaseService.h"
#import "YMSCBCharacteristic.h"
#import "YMSCBUtils.h"

@interface DEABaseService ()

@end

@implementation DEABaseService


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
        yms_u128_t pbase = self.base;
        
        if (![oName isEqualToString:@"simplekeys"]) {
            self.UUID = [YMSCBUtils createCBUUID:&pbase withIntBLEOffset:serviceOffset];
        }
    }
    return self;
}


- (void)turnOff {
    __weak DEABaseService *this = self;

    YMSCBCharacteristic *configCt = self.characteristicDict[@"config"];
    [configCt writeByte:0x0 withBlock:^(NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
            return;
        }
        
        NSLog(@"TURNED OFF: %@", this.name);
    }];
    
    YMSCBCharacteristic *dataCt = self.characteristicDict[@"data"];
    
    [dataCt setNotifyValue:NO withStateChangeBlock:^(NSError * _Nullable error) {
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
    }];

    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isOn = YES;
    });
}

- (NSDictionary *)sensorValues
{
    NSLog(@"WARNING: -[%@ sensorValues] has not been implemented.", NSStringFromClass([self class]));
    return nil;
}

@end
