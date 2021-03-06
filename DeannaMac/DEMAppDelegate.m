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

#import "DEMAppDelegate.h"
#import "DEACentralManager.h"
#import "YMSCBPeripheral.h"
#import "DEASensorTag.h"
#import "DEMPeripheralViewCell.h"
#import "DEASimpleKeysService.h"
#import "DEASensorTagWindow.h"
#import "YMSCBLogger.h"

@implementation DEMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [DEACentralManager initSharedServiceWithCentral:nil
                                           delegate:self
                                              queue:nil
                                            options:nil
                                             logger:[YMSCBLogger new]];
}

- (void)applicationWillBecomeActive:(NSNotification *)notification {

}

- (IBAction)scanAction:(id)sender {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    if (centralManager.isScanning) {
        [centralManager stopScan];
        self.scanButton.title = @"Start Scanning";
        
        [self.peripheralTableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
            
            DEMPeripheralViewCell *pvc = [rowView viewAtColumn:0];
            
            if (pvc.sensorTag) {
                NSLog(@"%@", rowView);
                [pvc.connectButton setEnabled:YES];
            }
            
        }];
        
        
        
    } else {
        [centralManager startScan];
        self.scanButton.title = @"Stop Scanning";
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
}


- (void)openPeripheralWindow:(YMSCBPeripheral *)yp {
    NSLog(@"yp open: %@", yp);
    
    if (self.peripheralWindows == nil) {
        self.peripheralWindows = [NSMutableArray new];
    }
    
    BOOL foundWindow = NO;
    for (DEASensorTagWindow *stWindow in self.peripheralWindows) {
        if (stWindow.sensorTag == yp) {
            foundWindow = YES;
            [stWindow showWindow:self];
            break;
        }
    }
    
    if (foundWindow == NO) {
        DEASensorTagWindow *stWindow = [[DEASensorTagWindow alloc] init];
        
        DEASensorTag *sensorTag = (DEASensorTag *)yp;
        stWindow.sensorTag = sensorTag;
        
        [self.peripheralWindows addObject:stWindow];
        [stWindow showWindow:self];
        
    }
    
    
}




#pragma mark - NSTableViewDelegate & NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSInteger result = 0;
    
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    if (centralManager) {
        result = centralManager.count;
    }
    
    return result;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    DEMPeripheralViewCell *result = [tableView makeViewWithIdentifier:@"myView" owner:self];
    
    if (result == nil) {
        CGRect frame = CGRectMake(0, 0, self.peripheralTableView.bounds.size.width, 0);
        result = [[DEMPeripheralViewCell alloc] initWithFrame:frame];
        result.identifier = @"myView";
        
    }
    
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    YMSCBPeripheral *yp = centralManager.peripherals[row];
    if (yp) {
        if ([yp isKindOfClass:[DEASensorTag class]]) {
            [result configureWithSensorTag:(DEASensorTag *)yp];
        } else {
            [result.connectButton setHidden:YES];
            [result.dbLabel setHidden:YES];
            [result.rssiLabel setHidden:YES];
            [result.detailButton setHidden:YES];
        }
        
        if (yp.name != nil) {
            result.nameLabel.stringValue = yp.name;
        } else {
            result.nameLabel.stringValue = @"Unknown";
        }
    }
    
    result.delegate = self;
    
    return result;
    
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 107.0;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView {
    return NO;
}


#pragma mark - CBCentralManager Delegate Methods

- (void)centralManager:(YMSCBCentralManager *)yCentral didDiscoverPeripheral:(YMSCBPeripheral *)yPeripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    __weak typeof(self) this = self;

    _YMS_PERFORM_ON_MAIN_THREAD((^{
        __strong typeof (this) strongThis = this;
        
        DEACentralManager *centralManager = [DEACentralManager sharedService];
        YMSCBPeripheral *yp = [centralManager findPeripheral:yPeripheral];
        yp.delegate = strongThis;
        
        if (strongThis.oldCount == 0) {
            strongThis.oldCount = (int)centralManager.count;
            [strongThis.peripheralTableView reloadData];
        } else {
            if (centralManager.count != strongThis.oldCount) {
                strongThis.oldCount = (int)centralManager.count;
                [strongThis.peripheralTableView reloadData];
            }
        }
        
        [strongThis.peripheralTableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
            
            DEMPeripheralViewCell *pvc = [rowView viewAtColumn:0];
            
            if (pvc.sensorTag == yp) {
                pvc.rssiLabel.stringValue = [NSString stringWithFormat:@"%d", [RSSI intValue]];
            }
            
        }];
        
        //[strongThis.peripheralTableView reloadData];
    }));
    
    
}

- (void)centralManagerDidUpdateState:(YMSCBCentralManager *)yCentral {

    __weak typeof(self) this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof (this) strongThis = this;

        switch (yCentral.state) {
            case CBCentralManagerStatePoweredOn:
                [strongThis.peripheralTableView reloadData];
                break;
            case CBCentralManagerStatePoweredOff:
                break;
                
            case CBCentralManagerStateUnsupported: {
                NSLog(@"ERROR: This system does not support Bluetooth 4.0 Low Energy communication. "
                      "Please run this app on a system that either has BLE hardware support or has a BLE USB adapter attached.");
                break;
            }

            default:
                break;
        }
    });
}

- (void)centralManager:(YMSCBCentralManager *)yCentral didConnectPeripheral:(YMSCBPeripheral *)yPeripheral {

    __weak typeof(self) this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof (this) strongThis = this;
        
        DEACentralManager *centralManager = [DEACentralManager sharedService];
        DEASensorTag *sensorTag = (DEASensorTag *)[centralManager findPeripheral:yPeripheral];
        
        sensorTag.delegate = self;
        [sensorTag readRSSI];
        
        [strongThis.peripheralTableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
            DEMPeripheralViewCell *pvc = [rowView viewAtColumn:0];
            
            if (pvc.sensorTag == sensorTag) {
                
                NSLog(@"%@", rowView);
                pvc.connectButton.title = @"Disconnect";
                [pvc.detailButton setHidden:NO];
            }
            
        }];
    });
}
                                
- (void)centralManager:(YMSCBCentralManager *)yCentral didDisconnectPeripheral:(YMSCBPeripheral *)yPeripheral error:(NSError *)error {

    
    __weak typeof(self) this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof (this) strongThis = this;
        
        DEACentralManager *centralManager = [DEACentralManager sharedService];
        __weak DEASensorTag *sensorTag = (DEASensorTag *)[centralManager findPeripheral:yPeripheral];
        
        [strongThis.peripheralTableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
            DEMPeripheralViewCell *pvc = [rowView viewAtColumn:0];
            
            if (pvc.sensorTag == sensorTag) {
                //NSLog(@"%@", rowView);
                pvc.connectButton.title = @"Connect";
                [pvc.detailButton setHidden:YES];
            }
        }];
    });
}



#pragma mark - CBPeripheralDelegate Methods

- (void)peripheralDidUpdateRSSI:(YMSCBPeripheral *)yPeripheral error:(NSError *)error {

    __weak typeof(self) this = self;
    _YMS_PERFORM_ON_MAIN_THREAD((^{
        __strong typeof (this) strongThis = this;

        DEACentralManager *centralManager = [DEACentralManager sharedService];
        __weak DEASensorTag *sensorTag = (DEASensorTag *)[centralManager findPeripheral:yPeripheral];
        
        if (error) {
            NSLog(@"ERROR: readRSSI failed, retrying. %@", error.description);
            if (yPeripheral.state == CBPeripheralStateConnected) {
                [sensorTag readRSSI];
            }
            return;
        }
        
        [strongThis.peripheralTableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
            
            DEMPeripheralViewCell *pvc = [rowView viewAtColumn:0];
            
            if (pvc.sensorTag == sensorTag) {
                pvc.rssiLabel.stringValue = [NSString stringWithFormat:@"%d", [sensorTag.peripheralInterface.RSSI intValue]];
            }
            
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sensorTag readRSSI];
        });
    }));
    
}



@end
