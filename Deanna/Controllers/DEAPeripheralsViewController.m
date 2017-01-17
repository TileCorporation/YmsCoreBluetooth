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

#import "DEAPeripheralsViewController.h"
#import "DEASensorTag.h"
#import "DEASensorTagViewController.h"
#import "DEAPeripheralTableViewCell.h"
#import "DEAStyleSheet.h"
#import "DEATheme.h"

@interface DEAPeripheralsViewController ()<YMSCBCentralManagerDelegate>
- (void)editButtonAction:(id)sender;
@end

@implementation DEAPeripheralsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Deanna";
    
    /*
     First time DEACentralManager singleton is instantiated.
     All subsequent references will use [DEACentralManager sharedService].
     */
    DEACentralManager *centralManager = [DEACentralManager initSharedServiceWithDelegate:self];
    

    [self.navigationController setToolbarHidden:NO];


    self.scanButton = [[UIBarButtonItem alloc] initWithTitle:@"Start Scanning" style:UIBarButtonItemStylePlain target:self action:@selector(scanButtonAction:)];
    
    self.toolbarItems = @[self.scanButton];
    
    [self.peripheralsTableView reloadData];
    
    [centralManager addObserver:self
                     forKeyPath:@"isScanning"
                        options:NSKeyValueObservingOptionNew
                        context:NULL];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonAction:)];
    
    self.navigationItem.rightBarButtonItem = editButton;
    
    [DEATheme customizeTableView:self.peripheralsTableView forType:DEAPeripheralTableViewStyle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    centralManager.delegate = self;
    
    for (DEAPeripheralTableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        cell.yperipheral.delegate = self;
    }
    [self.peripheralsTableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    if (object == centralManager) {
        if ([keyPath isEqualToString:@"isScanning"]) {
            if (centralManager.isScanning) {
                self.scanButton.title = @"Stop Scanning";
            } else {
                self.scanButton.title = @"Start Scan";
            }
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)scanButtonAction:(id)sender {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    if (centralManager.isScanning == NO) {
        BOOL result = [centralManager startScan];
        if (result) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        } else {
            NSLog(@"ERROR: Scan failed; BT Server not on");
        }
            
        
    }
    else {
        [centralManager stopScan];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        for (DEAPeripheralTableViewCell *cell in [self.peripheralsTableView visibleCells]) {
            if (cell.yperipheral.state == CBPeripheralStateDisconnected) {
                cell.rssiLabel.text = @"—";
                cell.peripheralStatusLabel.text = @"QUIESCENT";
                [cell.peripheralStatusLabel setTextColor:[[DEATheme sharedTheme] bodyTextColor]];
            }
        }

    }
}


- (void)editButtonAction:(id)sender {
    UIBarButtonItem *button = nil;
    
    [self.peripheralsTableView setEditing:(!self.peripheralsTableView.editing) animated:YES];

    if (self.peripheralsTableView.editing) {
        button = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonAction:)];
    } else {
        button = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonAction:)];
    }
    self.navigationItem.rightBarButtonItem = button;
        
}

#pragma mark - YMSCBCentralManagerDelegate Methods

- (void)centralManagerDidUpdateState:(YMSCBCentralManager *)yCentral {

    _YMS_PERFORM_ON_MAIN_THREAD(^{
        switch (yCentral.state) {
            case CBCentralManagerStatePoweredOn:
                break;
            case CBCentralManagerStatePoweredOff:
                break;
                
            case CBCentralManagerStateUnsupported: {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dang."
                                                                message:@"Unfortunately this device can not talk to Bluetooth Smart (Low Energy) Devices"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
                
                [alert show];
                break;
            }
            case CBCentralManagerStateResetting: {
                [self.peripheralsTableView reloadData];
                break;
            }
            case CBCentralManagerStateUnauthorized:
                break;
                
            case CBCentralManagerStateUnknown:
                break;
                
            default:
                break;
        }
    });
}

- (void)centralManager:(YMSCBCentralManager *)yCentral didConnectPeripheral:(YMSCBPeripheral *)yPeripheral {

    __weak typeof(self) this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        DEACentralManager *centralManager = [DEACentralManager sharedService];
        DEASensorTag *yp = (DEASensorTag *)[centralManager findPeripheral:yPeripheral];
        yp.delegate = self;
        
        [yp readRSSI];
        
        for (DEAPeripheralTableViewCell *cell in [this.peripheralsTableView visibleCells]) {
            if (cell.yperipheral == yp) {
                [cell updateDisplay];
                break;
            }
        }
    });
}

- (void)centralManager:(YMSCBCentralManager *)yCentral didDisconnectPeripheral:(YMSCBPeripheral *)yPeripheral error:(NSError *)error {

    __weak typeof(self) this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        for (DEAPeripheralTableViewCell *cell in [this.peripheralsTableView visibleCells]) {
            [cell updateDisplay];
        }
    });
}

- (void)centralManager:(YMSCBCentralManager *)yCentral didDiscoverPeripheral:(YMSCBPeripheral *)yPeripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    __weak typeof(self) this = self;
    _YMS_PERFORM_ON_MAIN_THREAD((^{
        DEACentralManager *centralManager = [DEACentralManager sharedService];
        
        YMSCBPeripheral *yp = [centralManager findPeripheral:yPeripheral];
        
        if ([yp isKindOfClass:[DEASensorTag class]]) {
            DEASensorTag *sensorTag = (DEASensorTag *)yp;
            if (sensorTag.isRenderedInViewCell == NO) {
                [self.peripheralsTableView reloadData];
                sensorTag.isRenderedInViewCell = YES;
            }
        }
        
        // SensorTag 2.0 Service UUID AA80
        if (centralManager.isScanning) {
            for (DEAPeripheralTableViewCell *cell in [this.peripheralsTableView visibleCells]) {
                if (cell.yperipheral == yPeripheral) {
                    if (yPeripheral.state == CBPeripheralStateDisconnected) {
                        cell.rssiLabel.text = [NSString stringWithFormat:@"%ld", (long)[RSSI integerValue]];
                        cell.peripheralStatusLabel.text = @"ADVERTISING";
                        [cell.peripheralStatusLabel setTextColor:[[DEATheme sharedTheme] advertisingColor]];
                    } else {
                        continue;
                    }
                }
            }
        }
    }));
}




#pragma mark - CBPeripheralDelegate Methods


//- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
//    
//    __weak typeof(self) this = self;
//    _YMS_PERFORM_ON_MAIN_THREAD((^{
//        __strong typeof (this) strongThis = this;
//        
//        DEASensorTag *sensorTag = (DEASensorTag *)[[DEACentralManager sharedService] findPeripheral:peripheral];
//        
//        if (error) {
//            NSLog(@"ERROR: readRSSI failed, retrying. %@", error.description);
//            if (peripheral.state == CBPeripheralStateConnected) {
//                [sensorTag readRSSI];
//            }
//        }
//        
//        
//        for (DEAPeripheralTableViewCell *cell in [strongThis.peripheralsTableView visibleCells]) {
//            if (cell.yperipheral) {
//                if (cell.yperipheral.isConnected) {
//                    if (cell.yperipheral.cbPeripheral == peripheral) {
//                        cell.rssiLabel.text = [NSString stringWithFormat:@"%@", RSSI];
//                        break;
//                    }
//                }
//            }
//        }
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [sensorTag readRSSI];
//        });
//    }));
//}



#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result;
    result = 166.0;
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *SensorTagCellIdentifier = @"SensorTagCell";
    //static NSString *UnknownPeripheralCellIdentifier = @"UnknownPeripheralCell";

    DEACentralManager *centralManager = [DEACentralManager sharedService];
    YMSCBPeripheral *yp = [centralManager peripheralAtIndex:indexPath.row];
    
    
    UITableViewCell *cell = nil;
    
    DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SensorTagCellIdentifier];
    
    if (pcell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"DEAPeripheralTableViewCell" owner:self options:nil];
        pcell = self.tvCell;
        self.tvCell = nil;
    }
    
    DEASensorTag *sensorTag = (DEASensorTag *)yp;
    
    sensorTag.isRenderedInViewCell = YES;
    
    [pcell configureWithPeripheral:yp];
    
    cell = pcell;
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
        [DEATheme customizePeripheralTableViewCell:(DEAPeripheralTableViewCell *)cell];
    }

    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    

    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete: {
            DEACentralManager *centralManager = [DEACentralManager sharedService];
            YMSCBPeripheral *yp = [centralManager peripheralAtIndex:indexPath.row];
            if ([yp isKindOfClass:[DEASensorTag class]]) {
                if (yp.state == CBPeripheralStateConnected) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Disconnect the peripheral before deleting."
                                                                   delegate:nil cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil];
                    
                    [alert show];
                    
                    break;
                }
            }
            [centralManager removePeripheral:yp];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
            
        case UITableViewCellEditingStyleInsert:
        case UITableViewCellEditingStyleNone:
            break;
            
        default:
            break;
    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    NSInteger result;
    result = centralManager.count;
    return result;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    DEASensorTag *sensorTag = (DEASensorTag *)[centralManager peripheralAtIndex:indexPath.row];
    
    DEASensorTagViewController *stvc = [[DEASensorTagViewController alloc] initWithNibName:@"DEASensorTagViewController" bundle:nil];
    stvc.sensorTag = sensorTag;

    
    [self.navigationController pushViewController:stvc animated:YES];
    
    
}


- (void)viewDidUnload {
    [self setTvCell:nil];
    [super viewDidUnload];
}
@end
