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
            _UUID = [CBUUID UUIDWithString:addrString];

        } else {
            _UUID = [YMSCBUtils createCBUUID:&_base withIntOffset:serviceOffset];
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
            _UUID = [CBUUID UUIDWithString:addrString];
            
        } else {
            _UUID = [YMSCBUtils createCBUUID:&_base withIntBLEOffset:serviceOffset];
        }
        
        _logger = _parent.logger;
    }
    return self;
}

- (instancetype)initWithUUID:(NSString *)UUID
                      parent:(YMSCBPeripheral *)pObj {
    
    self = [super init];
    if (self) {
        _name = UUID;
        _parent = pObj;
        _characteristicDict = [[NSMutableDictionary alloc] init];
        _UUID = [CBUUID UUIDWithString:UUID];
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
                                              uuid:uuid];
    yc.parent = self.parent;
    
    self.characteristicDict[cname] = yc;
    self.characteristicsByUUID[yc.UUID.UUIDString] = yc;
}


- (void)addCharacteristic:(NSString *)cname withBLEOffset:(int)addrOffset {
    YMSCBCharacteristic *yc;
    
    yms_u128_t pbase = self.base;
    
    CBUUID *uuid = [YMSCBUtils createCBUUID:&pbase withIntBLEOffset:addrOffset];
    
    yc = [[YMSCBCharacteristic alloc] initWithName:cname
                                            parent:self.parent
                                              uuid:uuid];
    yc.parent = self.parent;
    
    self.characteristicDict[cname] = yc;
    self.characteristicsByUUID[yc.UUID.UUIDString] = yc;
}

- (void)addCharacteristic:(NSString *)cname withAddress:(int)addr {
    YMSCBCharacteristic *yc;
    NSString *addrString = [NSString stringWithFormat:@"%04x", addr];

    
    CBUUID *uuid = [CBUUID UUIDWithString:addrString];
    yc = [[YMSCBCharacteristic alloc] initWithName:cname
                                            parent:self.parent
                                            uuid:uuid];
    self.characteristicDict[cname] = yc;
    self.characteristicsByUUID[yc.UUID.UUIDString] = yc;
}

- (void)addCharacteristic:(NSString *)UUIDString {
    YMSCBCharacteristic *yc;
    
    CBUUID *uuid = [CBUUID UUIDWithString:UUIDString];
    yc = [[YMSCBCharacteristic alloc] initWithName:UUIDString
                                            parent:self.parent
                                              uuid:uuid];
    self.characteristicDict[UUIDString] = yc;
    self.characteristicsByUUID[yc.UUID.UUIDString] = yc;
}


- (NSArray<YMSCBCharacteristic *> *)characteristics {
    NSArray<YMSCBCharacteristic *> *result = nil;
    result = [self.characteristicDict allValues];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characteristicInterface != NULL"];
    result = [result filteredArrayUsingPredicate:predicate];
    
    return result;
}

- (NSArray<CBUUID *> *)characteristicUUIDs {
    NSArray<CBUUID *> *result = nil;
    
    NSArray<YMSCBCharacteristic *> *characteristics = [_characteristicDict allValues];
    result = [characteristics valueForKeyPath:@"UUID"];
    
    return result;
}

- (NSArray *)characteristicsSubset:(NSArray *)keys {
    NSArray *result = nil;
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:keys.count];
    
    for (NSString *key in keys) {
        YMSCBCharacteristic *yc = (YMSCBCharacteristic *)self[key];
        
        if (yc) {
            [tempArray addObject:yc.UUID];
        } else {
            NSLog(@"WARNING: characteristic key '%@' is not found in service '%@' for characteristicSubset:", key, self.name);
        }
    }
    
    result = [NSArray arrayWithArray:tempArray];
    return result;
}


- (void)syncWithCharacteristics:(NSArray<id<YMSCBCharacteristicInterface>> *)characteristics {
    // TODO: Does this need to be @synchronized(self)?
    
    // User defined characteristics
    NSArray<NSString *> *expectedCharacteristicUUIDs = [self.characteristicsByUUID allKeys];
    // Actual characteristics on the CBService
    NSArray<NSString *> *actualCharacteristicUUIDs = [characteristics valueForKeyPath:@"UUID.UUIDString"];
    
    NSSet<NSString *> *expectedUUIDs = [NSMutableSet setWithArray:expectedCharacteristicUUIDs];
    NSSet<NSString *> *actualUUIDs = [NSMutableSet setWithArray:actualCharacteristicUUIDs];
    
    NSMutableSet<NSString *> *missingUUIDs = [expectedUUIDs mutableCopy];
    NSMutableSet<NSString *> *addedUUIDs = [actualUUIDs mutableCopy];
    
    // Find missing UUIDs
    [missingUUIDs minusSet:actualUUIDs];
    // Find added UUIDs
    [addedUUIDs minusSet:expectedUUIDs];
    
    // Remove missing keys from self.characteristicDict and self.characteristicsByUUID
    [self.characteristicsByUUID removeObjectsForKeys:[missingUUIDs allObjects]];
    
    NSMutableArray<NSString *> *characteristicsToRemove = [NSMutableArray new];
    for (NSString *key in missingUUIDs) {
        [self.characteristicDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull characteristicKey, YMSCBCharacteristic * _Nonnull characteristic, BOOL * _Nonnull stop) {
            if ([key isEqualToString:characteristic.UUID.UUIDString]) {
                [characteristicsToRemove addObject:characteristicKey];
            }
        }];
    }
    [self.characteristicDict removeObjectsForKeys:characteristicsToRemove];
    
    // Add the added characteristics that exist on the CBService to self.characteristicDict and self.characteristicsByUUID
    for (NSString *UUID in addedUUIDs) {
        [self addCharacteristic:UUID];
    }
    
    // Set the characteristicInterface
    NSArray<id<YMSCBCharacteristicInterface>> *ctInterfaces = characteristics;
    for (id<YMSCBCharacteristicInterface> ctInterface in ctInterfaces) {
        YMSCBCharacteristic *characteristic = self.characteristicsByUUID[ctInterface.UUID.UUIDString];
        characteristic.characteristicInterface = ctInterface;
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
    
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:self.parent.peripheralInterface];
    [objects addObject:_serviceInterface];
    if (characteristicUUIDs) {
        [objects addObjectsFromArray:characteristicUUIDs];
    }
    
    NSString *message = @"discoverCharacteristics:forService:";
    [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeRequest objects:objects];
    
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
