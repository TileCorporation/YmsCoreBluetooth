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

#import "YMSCBService.h"
#import "YMSCBUtils.h"
#import "YMSCBPeripheral.h"
#import "YMSCBCharacteristic.h"

@interface YMSCBService ()

@property (nonatomic, strong) NSMutableDictionary *characteristicsByUUID;
@end

@implementation YMSCBService

- (instancetype)initWithName:(NSString *)oName
                      parent:(YMSCBPeripheral *)pObj
                      baseHi:(int64_t)hi
                      baseLo:(int64_t)lo
               serviceOffset:(int)serviceOffset {

    self = [super init];
    if (self) {
        _name = oName;
        _parent = pObj;
        _base.hi = hi;
        _base.lo = lo;
        _characteristicDict = [NSMutableDictionary new];
        _characteristicsByUUID = [NSMutableDictionary new];
        
        if ((hi == 0) && (lo == 0)) {
            NSString *addrString = [NSString stringWithFormat:@"%x", serviceOffset];
            _uuid = [CBUUID UUIDWithString:addrString];

        } else {
            _uuid = [YMSCBUtils createCBUUID:&_base withIntOffset:serviceOffset];
        }
        
        _logger = _parent.logger;
    }
    return self;
}


- (instancetype)initWithName:(NSString *)oName
                      parent:(YMSCBPeripheral *)pObj
                      baseHi:(int64_t)hi
                      baseLo:(int64_t)lo
            serviceBLEOffset:(int)serviceOffset {

    
    self = [super init];
    if (self) {
        _name = oName;
        _parent = pObj;
        _base.hi = hi;
        _base.lo = lo;
        _characteristicDict = [[NSMutableDictionary alloc] init];
        
        if ((hi == 0) && (lo == 0)) {
            NSString *addrString = [NSString stringWithFormat:@"%x", serviceOffset];
            _uuid = [CBUUID UUIDWithString:addrString];
            
        } else {
            _uuid = [YMSCBUtils createCBUUID:&_base withIntBLEOffset:serviceOffset];
        }
        
        _logger = _parent.logger;
    }
    return self;
}

- (nullable YMSCBCharacteristic *)objectForKeyedSubscript:(id)key {
    YMSCBCharacteristic *result = nil;
    result = self.characteristicDict[key];
    return result;
}

- (YMSCBCharacteristic *)characteristicForUUID:(CBUUID *)uuid {
    YMSCBCharacteristic *result = nil;
    result = self.characteristicsByUUID[uuid.UUIDString];
    return result;
}


- (void)addCharacteristic:(NSString *)cname withOffset:(int)addrOffset {
    YMSCBCharacteristic *yc;
    
    yms_u128_t pbase = self.base;
    
    CBUUID *uuid = [YMSCBUtils createCBUUID:&pbase withIntOffset:addrOffset];
    
    yc = [[YMSCBCharacteristic alloc] initWithName:cname
                                            parent:self.parent
                                              uuid:uuid
                                            offset:addrOffset];
    yc.parent = self.parent;
    
    self.characteristicDict[cname] = yc;
    self.characteristicsByUUID[yc.uuid.UUIDString] = yc;
}


- (void)addCharacteristic:(NSString *)cname withBLEOffset:(int)addrOffset {
    YMSCBCharacteristic *yc;
    
    yms_u128_t pbase = self.base;
    
    CBUUID *uuid = [YMSCBUtils createCBUUID:&pbase withIntBLEOffset:addrOffset];
    
    yc = [[YMSCBCharacteristic alloc] initWithName:cname
                                            parent:self.parent
                                              uuid:uuid
                                            offset:addrOffset];
    yc.parent = self.parent;
    
    self.characteristicDict[cname] = yc;
    self.characteristicsByUUID[yc.uuid.UUIDString] = yc;
}

- (void)addCharacteristic:(NSString *)cname withAddress:(int)addr {
    
    YMSCBCharacteristic *yc;
    NSString *addrString = [NSString stringWithFormat:@"%04x", addr];

    
    CBUUID *uuid = [CBUUID UUIDWithString:addrString];
    yc = [[YMSCBCharacteristic alloc] initWithName:cname
                                            parent:self.parent
                                            uuid:uuid
                                          offset:addr];
    self.characteristicDict[cname] = yc;
    self.characteristicsByUUID[yc.uuid.UUIDString] = yc;
}


- (NSArray<id<YMSCBCharacteristicInterface>> *)characteristics {
    NSArray<id<YMSCBCharacteristicInterface>> *result = nil;
    result = [self.characteristicDict allValues];
    return result;
}

- (NSArray<CBUUID *> *)characteristicUUIDs {
    NSArray<CBUUID *> *result = nil;
    
    NSArray<id<YMSCBCharacteristicInterface>> *characteristics = self.characteristics;
    result = [characteristics valueForKeyPath:@"uuid"];
    
    return result;
}

- (NSArray *)characteristicsSubset:(NSArray *)keys {
    NSArray *result = nil;
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:keys.count];
    
    for (NSString *key in keys) {
        YMSCBCharacteristic *yc = (YMSCBCharacteristic *)self[key];
        
        if (yc) {
            [tempArray addObject:yc.uuid];
        } else {
            NSLog(@"WARNING: characteristic key '%@' is not found in service '%@' for characteristicSubset:", key, self.name);
        }
    }
    
    result = [NSArray arrayWithArray:tempArray];
    return result;
}


- (void)syncCharacteristics {
    // @synchronized(self)
    NSArray<id<YMSCBCharacteristicInterface>> *ctInterfaces = [self.serviceInterface characteristics];
    NSArray<YMSCBCharacteristic *> *localCharacteristics = [self.characteristicDict allValues];
    
    for (id<YMSCBCharacteristicInterface> ctInterface in ctInterfaces) {
        for (YMSCBCharacteristic *ct in localCharacteristics) {
            if ([ctInterface.UUID isEqual:ct.uuid]) {
                ct.characteristicInterface = ctInterface;
                break;
            }
        }
    }
    
    __weak YMSCBService *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isEnabled = YES;
    });
    
}


- (void)notifyCharacteristicHandler:(YMSCBCharacteristic *)yc error:(NSError *)error {
    if (error) {
        return;
    }
}


- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs withBlock:(void (^)(NSDictionary *, NSError *))callback {
    self.discoverCharacteristicsCallback = callback;
    
    NSMutableArray *bufArray = [NSMutableArray new];
    [characteristicUUIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [bufArray addObject:[NSString stringWithFormat:@"%@", obj]];
    }];
    NSString *buf = [bufArray componentsJoinedByString:@","];
    
    NSString *message = [NSString stringWithFormat:@"> discoverCharacteristics:%@ forService: %@", buf, self.serviceInterface];
    [self.logger logInfo:message object:self.parent.peripheralInterface];
    
    
    [self.parent.peripheralInterface discoverCharacteristics:characteristicUUIDs
                                                  forService:self.serviceInterface];

}

- (void)handleDiscoveredCharacteristicsResponse:(NSDictionary *)chDict withError:(NSError *)error {
    YMSCBDiscoverCharacteristicsCallbackBlockType callback = [self.discoverCharacteristicsCallback copy];
    
    if (callback) {
        callback(chDict, error);
        self.discoverCharacteristicsCallback = nil;
         
    } else {
        NSAssert(NO, @"ERROR: discoveredCharacteristicsCallback is nil; please check for multi-threaded access of handleDiscoveredCharacteristicsResponse");
    }
    
}

- (void)reset {
    self.isEnabled = NO;
    self.isOn = NO;
    
    for (id key in self.characteristicDict) {
        YMSCBCharacteristic *ct = self.characteristicDict[key];
        [ct reset];
    }
}

@end
