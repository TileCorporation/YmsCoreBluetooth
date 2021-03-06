//
//  YMSBFMStimulusGenerator.m
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMStimulusGenerator.h"
#import "YMSBFMModelConfiguration.h"
#import "YMSBFMPeripheralConfiguration.h"
#import "YMSBFMPeripheral.h"
#import "NSMutableArray+fifoQueue.h"
#import "YMSBFMStimulusEvent.h"
#import "YMSCBCentralManager.h"
#import "YMSBFMSyntheticValue.h"
#import "YMSBFMService.h"
#import "YMSBFMCharacteristic.h"
#import "YMSCBCharacteristic.h"
#import "YMSCBService.h"

NS_ASSUME_NONNULL_BEGIN

#define YMSBFMStimulusGeneratorClockPeriod (1.0 / 100.0) * NSEC_PER_SEC

@interface YMSBFMStimulusGenerator ()
@property (nonatomic, strong) id<YMSCBCentralManagerInterface> central;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) dispatch_queue_t timerQueue;
@property (nonatomic, strong) NSDate *clock;
@property (nonatomic, strong) NSMutableArray<YMSBFMStimulusEvent *> *events;
@property (nonatomic) BOOL isScanning;
@end

@implementation YMSBFMStimulusGenerator

- (instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central {
    self = [super init];
    if (self) {
        _central = central;
        _timerQueue = dispatch_queue_create("com.yummymelon.bfmsgtimerqueue", DISPATCH_QUEUE_SERIAL);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _timerQueue);
        _clock = [NSDate date];
        _modelConfiguration = [[YMSBFMModelConfiguration alloc] initWithConfigurationFile:nil];
        _peripheralConfiguration = [[YMSBFMPeripheralConfiguration alloc] initWithConfigurationFile:nil];
        _events = [NSMutableArray new];
        
        [self genPeripherals];
        //[self dummyPopulateEvents];
        
        // !!!:start simulation clock
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, YMSBFMStimulusGeneratorClockPeriod, 0);
        
        __weak typeof(self) this = self;
        dispatch_source_set_event_handler(_timer, ^{
            __strong typeof(this) strongThis = this;
            
            [strongThis clockTickHandler];
        });
        
        // Start the timer
        dispatch_resume(_timer);
    }
    return self;
}

- (instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central bfmConfig:(NSURL *)bfmURL modelConfig:(NSURL *)modelURL {
    self = [super init];
    if (self) {
        _central = central;
        _timerQueue = dispatch_queue_create("com.yummymelon.bfmsgtimerqueue", DISPATCH_QUEUE_SERIAL);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _timerQueue);
        _clock = [NSDate date];
        _modelConfiguration = [[YMSBFMModelConfiguration alloc] initWithConfigurationURL:modelURL];
        _peripheralConfiguration = [[YMSBFMPeripheralConfiguration alloc] initWithConfigurationURL:bfmURL];
        _events = [NSMutableArray new];
        
        [self genPeripherals];
        //[self dummyPopulateEvents];
        
        // !!!:start simulation clock
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, YMSBFMStimulusGeneratorClockPeriod, 0);
        
        __weak typeof(self) this = self;
        dispatch_source_set_event_handler(_timer, ^{
            __strong typeof(this) strongThis = this;
            
            [strongThis clockTickHandler];
        });
        
        // Start the timer
        dispatch_resume(_timer);
    }
    return self;
}

- (void)dealloc {
    dispatch_source_cancel(_timer);
}

- (void)genPeripherals {
    __block NSMutableDictionary<NSString *, YMSBFMPeripheral *> *tempDict = [NSMutableDictionary new];
    [_modelConfiguration.peripherals enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull uuidString, NSDictionary<NSString *, id> * _Nonnull peripheral, BOOL * _Nonnull stop) {
        NSString *peripheralClassname = peripheral[@"type"];
        Class peripheralClass = NSClassFromString(peripheralClassname);
        if (peripheralClass) {
            NSDictionary<NSString *, id> *peripheralConfigDict = [_peripheralConfiguration peripheralWithName:peripheralClassname];
            NSString *name = peripheralConfigDict[@"name"];
            YMSBFMPeripheral *peripheral = [[peripheralClass alloc] initWithCentral:_central stimulusGenerator:self identifier:uuidString name:name];
            tempDict[uuidString] = peripheral;
        }
    }];
    _peripherals = [NSDictionary dictionaryWithDictionary:tempDict];
    NSLog(@"peripherals: %@", _peripherals);
}

- (void)dummyPopulateEvents {
    for (int i = 0; i < 10; i++) {
        NSDate *time = [_clock dateByAddingTimeInterval:arc4random_uniform(5)];
        YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:time type:YMSBFMStimulusEvent_centralDidDiscoverPeripheral];
        event.central = _central;
        [_events push:event];
    }
    NSLog(@"events: %@", _events);
    [_events threadSafeSortUsingComparator:^NSComparisonResult(YMSBFMStimulusEvent *obj1, YMSBFMStimulusEvent *obj2) {
        return [obj1.time compare:obj2.time];
    }];
}

- (void)clockTickHandler {
    // 1. Execute events
    // 1a. Remove event from event table
    // TODO: Pop off all events that have the same time
    while (true) {
        YMSBFMStimulusEvent *event = [_events firstObject];
        NSTimeInterval dt = [event.time timeIntervalSinceDate:_clock];
        if (event && dt <= 0) {
            // 1b. Execute event
            [self executeEvent:event];
            [_events pop];
        } else {
            break;
        }
    }
    
    // 2. Advance time
    //NSLog(@"clockTickHandler %@", _clock);
    NSTimeInterval dt = YMSBFMStimulusGeneratorClockPeriod/1.0e9;
    _clock = [_clock dateByAddingTimeInterval:dt];
    //NSLog(@"clockTickHandler after %@", _clock);
    
    // 3. Update state
    // TODO: TBD
    
    // 4. Delete unfeasible events
    // TODO: Filter through events queue and remove those that are invalid.
    // e.g. a didReadRSSI when the peripheral is already disconnected.
    [self deleteUnfeasibleEvents];
    
    // 5. Add feasible events not already scheduled
    // TODO: addConnectionEvents, addDisconnectEvents, etc.
    [self addFeasibleEvents];

    // 6. Reorder event list
    [_events threadSafeSortUsingComparator:^NSComparisonResult(YMSBFMStimulusEvent *obj1, YMSBFMStimulusEvent *obj2) {
        return [obj1.time compare:obj2.time];
    }];
}

// MARK: - Clock Tick Handler Methods

- (void)executeEvent:(YMSBFMStimulusEvent *)event {
    NSLog(@"executingEvent: %@", event);
    
    id<YMSCBCentralManagerInterfaceDelegate> central = (id<YMSCBCentralManagerInterfaceDelegate>)event.central;
    id<YMSCBPeripheralInterfaceDelegate> peripheral = (id<YMSCBPeripheralInterfaceDelegate>)event.peripheral;
    
    if (event.type == YMSBFMStimulusEvent_centralDidDiscoverPeripheral) {
        [central centralManager:event.central didDiscoverPeripheral:event.peripheral advertisementData:@{} RSSI:event.RSSI];
        
    } else if (event.type == YMSBFMStimulusEvent_centralDidConnect) {
        YMSBFMPeripheral *bfmPeripheral = (YMSBFMPeripheral *)event.peripheral;
        [bfmPeripheral setConnectionState:CBPeripheralStateConnected];
        [central centralManager:event.central didConnectPeripheral:event.peripheral];
        
    } else if (event.type == YMSBFMStimulusEvent_centralDidDisconnect) {
        YMSBFMPeripheral *bfmPeripheral = (YMSBFMPeripheral *)event.peripheral;
        [bfmPeripheral setConnectionState:CBPeripheralStateDisconnected];
        [central centralManager:event.central didDisconnectPeripheral:event.peripheral error:event.error];
        
    } else if (event.type == YMSBFMStimulusEvent_peripheralDidDiscoverServices) {
        [peripheral peripheral:event.peripheral didDiscoverServices:event.error];
        
    } else if (event.type == YMSBFMStimulusEvent_peripheralDidDiscoverCharacteristics) {
        [peripheral peripheral:event.peripheral didDiscoverCharacteristicsForService:event.service error:event.error];
        
    } else if (event.type == YMSBFMStimulusEvent_peripheralDidUpdateValue) {
        YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)event.characteristic;
        [characteristic didUpdateValueWithPeripheral:event.peripheral error:event.error];
        
    } else if (event.type == YMSBFMStimulusEvent_peripheralDidWriteValue) {
        [peripheral peripheral:event.peripheral didWriteValueForCharacteristic:event.characteristic error:event.error];
        YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)event.characteristic;
        [characteristic didWriteValueWithPeripheral:event.peripheral error:event.error];
    }
}

- (void)deleteUnfeasibleEvents {
    NSMutableArray<YMSBFMStimulusEvent *> *eventsToRemove = [NSMutableArray new];
    
    // if peripheral is connected, remove any existing advertising events
    for (YMSBFMStimulusEvent *event in _events) {
        if (event.peripheral
            && event.type == YMSBFMStimulusEvent_centralDidDiscoverPeripheral
            && event.peripheral.state != CBPeripheralStateDisconnected) {
            [eventsToRemove addObject:event];
        }
    }
    
    [_events threadSafeRemoveObjectsInArray:eventsToRemove];
}

- (void)addFeasibleEvents {
    [self addCentralDidDiscoverPeripheralEvents];
    [self addCentralDidDisconnectPeripheralEvents];
    [self addNotifyingCharacteristicEvents];
}

- (void)addCentralDidDiscoverPeripheralEvents {
    if (!_isScanning) {
        return;
    }
    
    NSMutableArray<YMSBFMPeripheral *> *centralDidDiscoverPeripheralEvents = [NSMutableArray new];
    
    // check to see if there are existing YMSBFMStimulusEvent_centralDidDiscoverPeripheral events
    BOOL eventExists = NO;
    for (YMSBFMPeripheral *peripheral in [_peripherals allValues]) {
        for (YMSBFMStimulusEvent *event in _events) {
            if (event.type == YMSBFMStimulusEvent_centralDidDiscoverPeripheral && [peripheral isEqual:event.peripheral]) {
                eventExists = YES;
                break;
            }
        }
        
        if (!eventExists) {
            [centralDidDiscoverPeripheralEvents addObject:peripheral];
        }
        
        eventExists = NO;
    }
    
    for (YMSBFMPeripheral *peripheral in centralDidDiscoverPeripheralEvents) {
        if (peripheral.state == CBPeripheralStateDisconnected) {
            __weak typeof(self) this = self;
            
            if (peripheral.syntheticRSSI.hasNext) {
                [peripheral.syntheticRSSI genValueAndTime:^(NSNumber *value, NSTimeInterval time, NSError *error) {
                    __strong typeof(self) strongThis = this;
                    
                    if (error) {
                        NSAssert(NO, @"ERROR: Invalid synthetic value generation: %@", error);
                        return;
                    }
                    
                    NSDate *dateTime = [_clock dateByAddingTimeInterval:time];
                    YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:dateTime type:YMSBFMStimulusEvent_centralDidDiscoverPeripheral];
                    event.central = _central;
                    event.peripheral = peripheral;
                    NSInteger rssiInt = 0;
                    [value getValue:&rssiInt];
                    event.RSSI = @(rssiInt);
                    [strongThis.events push:event];
                }];
            }
        }
    }
}

- (void)addCentralDidDisconnectPeripheralEvents {
    NSMutableArray<YMSBFMPeripheral *> *centralDidDisconnectPeripheralEvents = [NSMutableArray new];
    
    // check to see if there are existing YMSBFMStimulusEvent_centralDidDiscoverPeripheral events
    BOOL eventExists = NO;
    for (YMSBFMPeripheral *peripheral in [_peripherals allValues]) {
        for (YMSBFMStimulusEvent *event in _events) {
            if (event.type == YMSBFMStimulusEvent_centralDidDisconnect && [peripheral isEqual:event.peripheral]) {
                eventExists = YES;
                break;
            }
        }
        
        if (!eventExists) {
            [centralDidDisconnectPeripheralEvents addObject:peripheral];
        }
        
        eventExists = NO;
    }
    
    for (YMSBFMPeripheral *peripheral in centralDidDisconnectPeripheralEvents) {
        if (peripheral.state == CBPeripheralStateConnecting || peripheral.state == CBPeripheralStateConnected) {
            NSNumber *connectionDuration = _modelConfiguration.peripherals[peripheral.identifier.UUIDString][@"connection_duration"];
            NSDate *time = [_clock dateByAddingTimeInterval:connectionDuration.doubleValue];
            YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:time type:YMSBFMStimulusEvent_centralDidDisconnect];
            event.central = _central;
            event.peripheral = peripheral;
            [_events push:event];
        }
    }
}

- (void)addNotifyingCharacteristicEvents {
    // TODO: Think about what happens on disconnect, do we need to delete those events in deleteFeasibleEvents?
    NSMutableArray<YMSBFMPeripheral *> *connectedPeripherals = [NSMutableArray new];
    for (YMSBFMPeripheral *peripheral in [_peripherals allValues]) {
        if (peripheral.state == CBPeripheralStateConnected) {
            [connectedPeripherals addObject:peripheral];
        }
    }
    
    for (YMSBFMPeripheral *peripheral in connectedPeripherals) {
        for (YMSBFMService *service in peripheral.services) {
            for (YMSBFMCharacteristic *characteristic in service.characteristics) {
                if (characteristic.isNotifying) {
                    BOOL eventExists = NO;
                    for (YMSBFMStimulusEvent *event in _events) {
                        if (event.type == YMSBFMStimulusEvent_peripheralDidUpdateValue && [characteristic isEqual:event.characteristic]) {
                            eventExists = YES;
                            break;
                        }
                    }
                    
                    if (!eventExists) {
                        [characteristic.syntheticValue genValueAndTime:^(NSNumber * _Nonnull value, NSTimeInterval time, NSError * _Nonnull error) {
                            if (error) {
                                NSAssert(NO, @"ERROR: Invalid synthetic value generation for addNotifyingCharacteristicEvents: %@", error);
                                return;
                            } else {
                                characteristic.behavioralValue = value;
                                
                                NSDate *futureTime = [_clock dateByAddingTimeInterval:time];
                                YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:futureTime type:YMSBFMStimulusEvent_peripheralDidUpdateValue];
                                event.central = _central;
                                event.peripheral = characteristic.service.peripheralInterface;
                                event.service = characteristic.service;
                                event.characteristic = characteristic;
                                [_events push:event];
                            }
                        }];
                    }
                }
            }
        }
    }
}

// MARK: - YMSCBCentralManagerInterfaceDelegate Methods

- (void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options {
    _isScanning = YES;
    // TODO: Read options for duplicate filtering
    // TODO: Also filter for serviceUUIDs filtering
}

- (void)connectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface options:(nullable NSDictionary<NSString *, id> *)options {
    YMSBFMPeripheral *peripheral = (YMSBFMPeripheral *)peripheralInterface;
    [peripheral setConnectionState:CBPeripheralStateConnecting];
    
    NSDate *time = [_clock dateByAddingTimeInterval:1];
    YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:time type:YMSBFMStimulusEvent_centralDidConnect];
    event.central = _central;
    event.peripheral = peripheralInterface;
    [_events push:event];
}

- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didDisconnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error {
    NSDate *time = [_clock dateByAddingTimeInterval:1];
    YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:time type:YMSBFMStimulusEvent_centralDidDisconnect];
    event.central = _central;
    event.peripheral = peripheralInterface;
    [_events push:event];
}

- (void)cancelPeripheralConnection:(id<YMSCBPeripheralInterface>)peripheralInterface {
    YMSBFMPeripheral *peripheral = (YMSBFMPeripheral *)peripheralInterface;
#if TARGET_OS_IOS
    [peripheral setConnectionState:CBPeripheralStateDisconnecting];
#else
    [peripheral setConnectionState:CBPeripheralStateDisconnected];
#endif
    
    NSError *error = nil;
    [self centralManager:_central didDisconnectPeripheral:peripheralInterface error:error];
}

- (void)stopScan {
    _isScanning = NO;
    // TODO: Clear out any remaining scanning/discovery events in the events table
}

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs peripheral:(id<YMSCBPeripheralInterface>)peripheral {
    // TODO: Create peripherals when event gets executed
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *services = [_peripheralConfiguration servicesForPeripheral:NSStringFromClass(peripheral.class)];
    for (CBUUID *serviceUUID in serviceUUIDs) {
        NSDictionary<NSString *, id> *service = services[serviceUUID.UUIDString];
     
        Class YMSBFMService = NSClassFromString(service[@"class_name"]);
        if (YMSBFMService) {
            id service = [[YMSBFMService alloc] initWithCBUUID:serviceUUID peripheralInterface:peripheral stimulusGenerator:self];
            [((YMSBFMPeripheral *)peripheral) addService:service];
        }
    }
    
    NSDate *time = [_clock dateByAddingTimeInterval:1];
    YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:time type:YMSBFMStimulusEvent_peripheralDidDiscoverServices];
    event.central = _central;
    event.peripheral = peripheral;
    [_events push:event];
}

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(id<YMSCBServiceInterface>)serviceInterface peripheral:(id<YMSCBPeripheralInterface>)peripheral {
    if (!characteristicUUIDs) {
        NSDictionary<NSString *, NSDictionary<NSString *, id> *> *characteristics = [_peripheralConfiguration characteristicsForServiceUUID:serviceInterface.UUID.UUIDString peripheral:NSStringFromClass(peripheral.class)];
        NSArray<NSString *> *keys = [characteristics allKeys];
        __block NSMutableArray<CBUUID *> *tempList = [NSMutableArray new];
        
        [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            CBUUID *uuid = [CBUUID UUIDWithString:key];
            [tempList addObject:uuid];
        }];
        
        characteristicUUIDs = [NSArray arrayWithArray:tempList];
    }
    
    for (CBUUID *uuid in characteristicUUIDs) {
        NSDictionary<NSString *, NSDictionary<NSString *, id> *> *characteristics = [_peripheralConfiguration characteristicsForServiceUUID:serviceInterface.UUID.UUIDString peripheral:NSStringFromClass(peripheral.class)];
        
        // TODO: Make sure the uuid exists and if not create an error
        NSDictionary<NSString *, id> *characteristic = characteristics[uuid.UUIDString];
        Class YMSBFMCharacteristic = NSClassFromString(characteristic[@"class_name"]);
        if (YMSBFMCharacteristic) {
            id characteristic = [[YMSBFMCharacteristic alloc] initWithCBUUID:uuid serviceInterface:serviceInterface stimulusGenerator:self];
            [((YMSBFMService *)serviceInterface) addCharacteristic:characteristic];
        }
    }
    
    NSDate *time = [_clock dateByAddingTimeInterval:1];
    YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:time type:YMSBFMStimulusEvent_peripheralDidDiscoverCharacteristics];
    event.central = _central;
    event.peripheral = peripheral;
    event.service = serviceInterface;
    [_events push:event];
}

- (void)readValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    [characteristic.syntheticValue genValueAndTime:^(NSNumber * _Nonnull value, NSTimeInterval time, NSError * _Nonnull error) {
        if (error) {
            NSAssert(NO, @"ERROR: Invalid synthetic value generation for readValueForCharacteristic: %@", error);
            return;
        } else {
            characteristic.behavioralValue = value;
            
            NSDate *futureTime = [_clock dateByAddingTimeInterval:time];
            YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:futureTime type:YMSBFMStimulusEvent_peripheralDidUpdateValue];
            event.central = _central;
            event.peripheral = characteristicInterface.service.peripheralInterface;
            event.service = characteristicInterface.service;
            event.characteristic = characteristicInterface;
            [_events push:event];
        }
    }];
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    // TODO: TBD
}

- (void)writeValue:(NSData *)data forCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface type:(CBCharacteristicWriteType)type {
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    [characteristic.syntheticValue genValueAndTime:^(NSNumber * _Nonnull value, NSTimeInterval time, NSError * _Nonnull error) {
        // TODO: handle retain cycle?
        [characteristic writeValue:data];
        
        if (type == CBCharacteristicWriteWithResponse) {
            NSDate *futureTime = [_clock dateByAddingTimeInterval:time];
            YMSBFMStimulusEvent *event = [[YMSBFMStimulusEvent alloc] initWithTime:futureTime type:YMSBFMStimulusEvent_peripheralDidWriteValue];
            event.peripheral = characteristicInterface.service.peripheralInterface;
            event.characteristic = characteristicInterface;
            [_events push:event];
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
