//
//  ViewController.m
//  mpopGroceryDemo
//
//  Created by Guillermo Cubero on 11/28/17.
//  Copyright © 2017 Guillermo Cubero. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Communication.h"
#import "GlobalQueueManager.h"
#import "ModelCapability.h"
#import "PrinterInfo+Builder.h"
#import "PrinterInfo.h"

typedef NS_ENUM(NSInteger, CellParamIndex) {
    CellParamIndexBarcodeData = 0
};

@interface ViewController ()

/* TABLEVIEW */
@property (nonatomic) NSMutableArray *cellArray;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

/* UI ELEMENTS */
//@property (weak, nonatomic) IBOutlet UIView *scaleWeight;
//@property (weak, nonatomic) IBOutlet UIView *weight;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
//@property (weak, nonatomic) IBOutlet UITextField *scaleWeight;
@property (weak, nonatomic) IBOutlet UILabel *scaleWeight;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *modelNameButtonItem;

/* BUTTON PRESS ACTIONS */
- (IBAction)pushRefreshButton:(id)sender;
- (IBAction)pushSearchButton:(id)sender;
- (IBAction)pushBookmarkButton:(id)sender;

- (IBAction)pressPrintButton:(id)sender;
- (IBAction)pressCashDrawerButton:(id)sender;
- (IBAction)pressCannabisLabelButton:(id)sender;


/* STAR IO */
@property (nonatomic) StarIoExtManager *starIoExtManager;
@property SMPort *port;

/* STAR SCALE */
@property(nonatomic) NSMutableArray<STARScale *> *contents;
@property(nonatomic) STARScale *connectedScale;
@property (nonatomic) NSDictionary<NSNumber *, NSString *> *unitDict;

@property (nonatomic) NSString *currentWeight;
@property (nonatomic) NSString *price;

/* APP STATE */
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDictionaries];
    
    // Setup the tableview
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    // Set the navigation bar title
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    _navigationBar.topItem.title = [NSString stringWithFormat:@"%@ %@", _navigationBar.topItem.title, version];
    
    // Some setup for our tableview
    _cellArray = [[NSMutableArray alloc] init];
    
    // Instantiate our connection to the printer & barcode scanner
    _starIoExtManager = [[StarIoExtManager alloc] initWithType:StarIoExtManagerTypeWithBarcodeReader
                                                      portName:[AppDelegate getPortName]
                                                  portSettings:[AppDelegate getPortSettings]
                                               ioTimeoutMillis:10000];                                   // 10000mS!!!
    
    // Set drawer polarity
    _starIoExtManager.cashDrawerOpenActiveHigh = [AppDelegate getCashDrawerOpenActiveHigh];
    
    // Setup the printer delegate methods
    _starIoExtManager.delegate = self;
    
    // Setup the ScaleManager delegate methods
    STARDeviceManager.sharedManager.delegate = self;
    
    // An arrray for storing discovered BLE scales
    _contents = [NSMutableArray new];
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Start scanning for scales
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //[STARScaleManager.sharedManager scanForScales];
        [STARDeviceManager.sharedManager scanForScales];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive)  name:UIApplicationDidBecomeActiveNotification  object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification  object:nil];
}

- (void)applicationDidBecomeActive {
    [_cellArray removeAllObjects];
    
    [_starIoExtManager disconnect];
        
    NSString *message = @"";
    NSString *modelName = [AppDelegate getModelName];
    _modelNameButtonItem.title = [AppDelegate getModelName];
    
    if ([_starIoExtManager connect] == NO) {
        message = [NSString stringWithFormat:@"Failed to connect to %@", modelName];
    }
    else {
        message = [NSString stringWithFormat:@"Connected to %@", modelName];
    }
    if (_connectedScale != nil) {
        [STARDeviceManager.sharedManager connectScale:_connectedScale];
    }
    
    [_tableView reloadData];
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // Handle OK button press action here
                                   // Currently do nothing
                               }];
    
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)applicationWillResignActive {
    [_starIoExtManager disconnect];
    
    //disconnect the scale manager & delegate methods when the
    if (_connectedScale != nil) {
        [STARDeviceManager.sharedManager disconnectScale:_connectedScale];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Triggered when you push the refresh button
- (IBAction)pushRefreshButton:(id)sender {
    
    [_cellArray removeAllObjects];
    
    [_starIoExtManager disconnect];
    
    NSString *modelName = [AppDelegate getModelName];
    _modelNameButtonItem.title = [AppDelegate getModelName];
    
    _starIoExtManager = [[StarIoExtManager alloc] initWithType:StarIoExtManagerTypeWithBarcodeReader portName:[AppDelegate getPortName] portSettings:[AppDelegate getPortSettings] ioTimeoutMillis:10000];
    
    NSString *title = @"";
    NSString *message = @"";
    
    if ([_starIoExtManager connect] == NO) {
        title = @"Uh oh...";
        message = [NSString stringWithFormat:@"Well this is embarrassing... We're having trouble connecting to your %@", modelName];
        
    }
    else {
        title = @"Printer Detected";
        message = [NSString stringWithFormat:@"%@, is now connected.", modelName];
    }
    
    [_tableView reloadData];
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle your yes please button action here
                                   // Do nothing
                               }];
    
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *cellParam = _cellArray[indexPath.row];
    
    static NSString *CellIdentifier = @"UITableViewCellStyleValue1";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    if (cell != nil) {
        cell.textLabel.text = cellParam[CellParamIndexBarcodeData];
        cell.detailTextLabel.text = @"$10/g";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didBarcodeDataReceive:(StarIoExtManager *)manager data:(NSData *)data {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSMutableString *text = [NSMutableString stringWithString:@""];
    
    const uint8_t *p = data.bytes;
    
    for (int i = 0; i < data.length; i++) {
        uint8_t ch = *(p + i);
        
        if(ch >= 0x20 && ch <= 0x7f) {
            [text appendFormat:@"%c", (char) ch];
        }
        else if (ch == 0x0d) {
            if (_cellArray.count > 30) {     // Max.30Line
                [_cellArray removeObjectAtIndex:0];
                [self.tableView reloadData];
                
            }
            if([text isEqualToString:@"0123456789"]) {
                text = (NSMutableString *)@"Star Chocolates";
                [_cellArray addObject:@[text]];
            }
            else if([text isEqualToString:@"Star."]) {
                text = (NSMutableString *)@"Pin. Express";
                [_cellArray addObject:@[text]];
            }
            else {
                [_cellArray addObject:@[text]];
            }
            
        }
    }
    
    [_tableView reloadData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_cellArray.count - 1 inSection:0];
    
    [_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ISDCBBuilder *displayBuilder = [StarIoExt createDisplayCommandBuilder:StarIoExtDisplayModelSCD222];
    [displayBuilder appendClearScreen];
    [displayBuilder appendData:(NSData *)[text dataUsingEncoding:NSASCIIStringEncoding]];
    
    [displayBuilder appendSpecifiedPosition:14 y:1];
    [displayBuilder appendData:(NSData *)[@"@ $10/g" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [displayBuilder appendSpecifiedPosition:0 y:2];
    [displayBuilder appendData:(NSData *)[_currentWeight dataUsingEncoding:NSASCIIStringEncoding]];
    
    [displayBuilder appendSpecifiedPosition:14 y:2];
    [displayBuilder appendData:(NSData *)[_price dataUsingEncoding:NSASCIIStringEncoding]];
    
    NSData *commands = [displayBuilder.passThroughCommands copy];
    
    [_starIoExtManager.lock lock];
    
    dispatch_async(GlobalQueueManager.sharedManager.serialQueue, ^{
        [Communication
         sendCommands:commands
         port:self->_starIoExtManager.port
         completionHandler:^(CommunicationResult *communicationResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (communicationResult != CommResultSuccess) {
                    
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"Uh oh..."
                                                 message:nil
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* okButton = [UIAlertAction
                                               actionWithTitle:@"OK"
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   //Handle your yes please button action here
                                                   // Do nothing
                                               }];
                    
                    [alert addAction:okButton];
                    [self presentViewController:alert animated:YES completion:nil];
                    
                }
            });
        }];
    });
}

- (void)initDictionaries {
    _unitDict = @{@(STARUnitInvalid): @"Invalid",
                  @(STARUnitMG): @"mg",
                  @(STARUnitG): @"g",
                  @(STARUnitCT): @"ct",
                  @(STARUnitMOM): @"mom",
                  @(STARUnitOZ): @"oz",
                  @(STARUnitLB): @"pound",
                  @(STARUnitOZT): @"ozt",
                  @(STARUnitDWT): @"dwt",
                  @(STARUnitGN): @"GN",
                  @(STARUnitTLH): @"tlH",
                  @(STARUnitTLS): @"tlS",
                  @(STARUnitTLT): @"tlT",
                  @(STARUnitTO): @"to",
                  @(STARUnitMSG): @"MSG",
                  @(STARUnitBAT): @"BAt",
                  @(STARUnitPCS): @"PCS",
                  @(STARUnitPercent): @"%",
                  @(STARUnitCoefficient): @"#"
                  };
}

- (void)didPrinterImpossible:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterOnline:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterOffline:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterPaperReady:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterPaperNearEmpty:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    /* The following printers do not have a low paper sensor:
     * TSP100, TSP100III, mC-Print, portable printers
     */
}

- (void)didPrinterPaperEmpty:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterCoverOpen:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterCoverClose:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didCashDrawerOpen:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didCashDrawerClose:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderImpossible:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderConnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderDisconnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryConnectSuccess:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryConnectFailure:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryDisconnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didStatusUpdate:(StarIoExtManager *)manager status:(NSString *)status {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (IBAction)pressPrintButton:(id)sender {
    
    ISCBBuilder *receiptBuilder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarPRNT];
    
    NSStringEncoding encoding = NSASCIIStringEncoding;
    [receiptBuilder appendCodePage:SCBCodePageTypeCP998];
    [receiptBuilder appendAlignment:SCBAlignmentPositionCenter];
    
    [receiptBuilder appendData:[@"Star Grocery\n"
                         "123 Star Road\n"
                         "City, State 12345\n"
                         "\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendAlignment:SCBAlignmentPositionLeft];
    [receiptBuilder appendData:[@"Date:05/21/2018                    Time:12:44 PM\n"
                         "------------------------------------------------\n"
                         "\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendDataWithEmphasis:[@"SALE\n" dataUsingEncoding:encoding]];
    [receiptBuilder appendData:[@"SKU               Description              Total\n"
                                "300678566         Apples                     .99\n"
                                "300692003         Oranges                    .99\n"
                                "300651148         Bananas                    .99\n"
                                "300642980         Pears                      .99\n"
                                "300638471         Kiwi                       .99\n"
                                "300614342         Mangos                     .99\n"
                                "\n"
                                "------------------------------------------------\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendAlignment:SCBAlignmentPositionRight];
    [receiptBuilder appendData:[@"Subtotal:   $ 5.94\n"
                                "Tax:   $ 0.00\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendData:[@"Total:   $ 5.94\n" dataUsingEncoding:encoding]];
    [receiptBuilder appendAlignment:SCBAlignmentPositionRight];
    
    [receiptBuilder appendData:[@"Cash:   $11.00\n"
                                "Change:   $ 5.06\n"
                                "------------------------------------------------\n" dataUsingEncoding:encoding]];
    [receiptBuilder appendAlignment:SCBAlignmentPositionCenter];
    [receiptBuilder appendData:[@"Thank you for shopping at \nStar Grocery!\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendBarcodeData:[@"{BStar." dataUsingEncoding:NSASCIIStringEncoding]
                            symbology:SCBBarcodeSymbologyCode128
                                width:SCBBarcodeWidthMode2
                               height:40
                                  hri:YES];
    
    [receiptBuilder appendAlignment:SCBAlignmentPositionLeft];
    [receiptBuilder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
    [receiptBuilder appendPeripheral:SCBPeripheralChannelNo1];
    [receiptBuilder appendPeripheral:SCBPeripheralChannelNo2];
    
    //NSData *commands = [receiptBuilder.commands copy];
    
    [_starIoExtManager.lock lock];
    
    dispatch_async(GlobalQueueManager.sharedManager.serialQueue, ^{
        [Communication sendCommands:receiptBuilder.commands
                               port:self->_starIoExtManager.port
                  completionHandler:^(CommunicationResult *communicationResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(communicationResult.result != CommResultSuccess) {
                    UIAlertController *alert = [UIAlertController
                                                alertControllerWithTitle:@"Printer Error"
                                                message:[NSString stringWithFormat:@"Result Code: %ld", (long)communicationResult.result]
                                                preferredStyle:UIAlertControllerStyleAlert];
                
                    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:nil];
                    [alert addAction:action];
                    [self presentViewController:alert animated:YES completion:nil];
                }
                [self->_starIoExtManager.lock unlock];
            });
        }];
    });
}

- (IBAction)pressCashDrawerButton:(id)sender {
    ISCBBuilder *cashDrawer = [StarIoExt createCommandBuilder:StarIoExtEmulationStarPRNT];
    
    [cashDrawer appendPeripheral:SCBPeripheralChannelNo1];
    [cashDrawer appendPeripheral:SCBPeripheralChannelNo2];
    
    //[_starIoExtManager.lock lock];
    dispatch_async(GlobalQueueManager.sharedManager.serialQueue, ^{
        [Communication sendCommands:cashDrawer.commands
                               port:self->_starIoExtManager.port
                  completionHandler:^(CommunicationResult *communicationResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(communicationResult.result != CommResultSuccess) {
                               
                               UIAlertController *alert = [UIAlertController
                                                           alertControllerWithTitle:@"Printer Error"
                                                           message:[NSString stringWithFormat:@"Result Code: %ld", (long)communicationResult.code]
                                                           preferredStyle:UIAlertControllerStyleAlert];
                               
                               UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                                                style:UIAlertActionStyleDefault
                                                                              handler:nil];
                               [alert addAction:action];
                               [self presentViewController:alert animated:YES completion:nil];
                }
                [self->_starIoExtManager.lock unlock];
            });
        }];
    });
}

- (IBAction)pressCannabisLabelButton:(id)sender {
    
    UIImage *image = [UIImage imageNamed:@"afghan_sour_kush.png"];
    
    ISCBBuilder * builder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarLine];
    [builder appendBlackMark:SCBBlackMarkTypeValidWithDetection];
    [builder appendBitmapWithAlignment:image diffusion:false width:384 bothScale:YES position:SCBAlignmentPositionCenter];
    [builder appendCutPaper:SCBCutPaperActionFullCutWithFeed];
    [builder appendBlackMark:SCBBlackMarkTypeInvalid];
    
    dispatch_async(GlobalQueueManager.sharedManager.serialQueue, ^{
        [Communication sendCommands:builder.commands
                               port:self->_starIoExtManager.port
                  completionHandler:^(CommunicationResult *communicationResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController
                                            alertControllerWithTitle:nil
                                            message:[NSString stringWithFormat:@"%@",communicationResult]
                                            preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:nil];
                [alert addAction:action];
                
                [self presentViewController:alert animated:YES completion:nil];
                
                [self->_starIoExtManager.lock unlock];
            });
        }];
    });
}

- (IBAction)pushSearchButton:(id)sender {
    
    NSArray *portInfoArray = nil;
    NSError *error = nil;
    
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Please choose a Printer"
        message:nil
        preferredStyle:UIAlertControllerStyleActionSheet];
    
    portInfoArray = [SMPort searchPrinter:@"ALL:" :&error];
    if (portInfoArray == nil) {
        return;
    }
    else {
        for (PortInfo *portInfo in portInfoArray) {

            if ([portInfo.modelName containsString:@"MCP2"] ||
                [portInfo.modelName containsString:@"MCP3"] ||
                [portInfo.modelName containsString:@"POP10"]) {
                
                
                ModelIndex index = [ModelCapability modelIndexAtModelName:portInfo.modelName];
                
                PrinterInfo *printerInfo = [ModelCapability printerInfoAtModelIndex:index];
                
                [alert addAction: [UIAlertAction actionWithTitle:portInfo.modelName
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                    [AppDelegate setPortName:portInfo.portName];
                    [AppDelegate setModelName:portInfo.modelName];
                    [AppDelegate setEmulation:printerInfo.emulation];
                    [AppDelegate setPortSettings:printerInfo.portSettings];
                    [AppDelegate setCashDrawerOpenActiveHigh:printerInfo.cashDrawerOpenActive];
                
                }]];
                
            }
        }
    }
    
    [alert setModalPresentationStyle:UIModalPresentationPopover];
    
    alert.popoverPresentationController.barButtonItem = sender;
    alert.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)pushBookmarkButton:(id)sender {
    
    NSString *message = [NSString stringWithFormat:@"%@ %@\n%@\n", @"StarIO version",
    [SMPort StarIOVersion], [StarIoExt description]];
        
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"mCollection Demo"
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // Handle OK button press action here
                                   // Currently do nothing
                               }];
    
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - STARDeviceManagerDelegate Methods

- (void)manager:(STARDeviceManager *)manager didDiscoverScale:(STARScale *)scale error:(NSError *)error {
    [_contents addObject:scale];
    
    [STARDeviceManager.sharedManager stopScan];
    [STARDeviceManager.sharedManager connectScale:scale];
}

- (void)manager:(STARDeviceManager *)manager didConnectScale:(STARScale *)scale error:(NSError *)error {
    NSLog(@"Scale %@ is now connected", scale.name);
    
    _connectedScale = scale.self;
    _connectedScale.delegate = self;
}

- (void)manager:(STARDeviceManager *)manager didDisconnectScale:(STARScale *)scale error:(NSError *)error {
    NSLog(@"Scale %@ has been disconnected", scale.name);
}

- (void)scale:(STARScale *)scale didReadScaleData:(STARScaleData *)scaleData error:(NSError *)error {
    
    _currentWeight = [NSString stringWithFormat:@"%.03lf [%@]", scaleData.weight, _unitDict[@(scaleData.unit)]];
    _price = [NSString stringWithFormat:@"$%.02lf", scaleData.weight * 10];
    _scaleWeight.text = [NSString stringWithFormat:@"Scale Weight: %.03lf [%@]", scaleData.weight, _unitDict[@(scaleData.unit)]];
    
    NSLog(@"Scale Weight: %f", scaleData.weight);
    
}

- (void)scale:(STARScale *)scale didUpdateSetting:(STARScaleSetting)setting error:(NSError *)error {
    if (error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
        [alert addAction:action];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)modelNameBarButtonItem:(id)sender {
}
@end
