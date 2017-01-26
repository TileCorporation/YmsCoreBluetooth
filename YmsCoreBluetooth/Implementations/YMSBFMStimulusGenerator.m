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

NS_ASSUME_NONNULL_BEGIN

#define YMSBFMStimulusGeneratorClockPeriod (1.0 / 100.0) * NSEC_PER_SEC

@interface YMSBFMStimulusGenerator ()
@property (nonatomic, strong) id<YMSCBCentralManagerInterface> central;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) dispatch_queue_t timerQueue;
@property (nonatomic, strong) NSDate *clock;
@property (nonatomic, strong) YMSBFMModelConfiguration *modelConfiguration;
@property (nonatomic, strong) YMSBFMPeripheralConfiguration *peripheralConfiguration;
@property (nonatomic, strong) NSDictionary<NSString *, YMSBFMPeripheral *> *peripherals;
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
        
        [self genPeripherals];
        
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
    [_modelConfiguration.peripherals enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull uuidString, NSString * _Nonnull peripheralClassname, BOOL * _Nonnull stop) {
        Class peripheralClass = NSClassFromString(peripheralClassname);
        if (peripheralClass) {
            NSDictionary<NSString *, id> *peripheralConfigDict = [_peripheralConfiguration peripheralWithName:peripheralClassname];
            NSString *name = peripheralConfigDict[@"name"];
            YMSBFMPeripheral *peripheral = [[peripheralClass alloc] initWithCentral:_central identifier:uuidString name:name];
            tempDict[uuidString] = peripheral;
        }
    }];
    _peripherals = [NSDictionary dictionaryWithDictionary:tempDict];
    NSLog(@"peripherals: %@", _peripherals);
}

- (void)clockTickHandler {
    //NSLog(@"clockTickHandler %@", _clock);
    NSTimeInterval dt = YMSBFMStimulusGeneratorClockPeriod/1.0e9;
    _clock = [_clock dateByAddingTimeInterval:dt];
    //NSLog(@"clockTickHandler after %@", _clock);
}

@end

NS_ASSUME_NONNULL_END
