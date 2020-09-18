//
//  Communication.m
//  ObjectiveC SDK
//
//  Created by Yuji on 2015/**/**.
//  Copyright (c) 2015年 Star Micronics. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Communication.h"

#import "CommunicationResult.h"

#import "AppDelegate.h"

@implementation Communication

+ (BOOL)sendCommands:(NSData *)commands
                port:(SMPort *)port
   completionHandler:(SendCompletionHandler)completionHandler {
    CommResult result = CommResultErrorOpenPort;
    NSInteger  code   = SMStarIOResultCodeFailedError;
    
    while (YES) {
        NSError *error = nil;
        
        if (port == nil) {
            break;
        }
        
        StarPrinterStatus_2 printerStatus;
        
        result = CommResultErrorBeginCheckedBlock;
        
        [port beginCheckedBlock:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
        if (printerStatus.offline == SM_TRUE) {
            break;
        }
        
        result = CommResultErrorWritePort;
        
        NSDate *startDate = [NSDate date];
        
        uint32_t total = 0;
        
        while (total < (uint32_t) commands.length) {
            uint32_t written = [port writePort:(unsigned char *) commands.bytes :total :(uint32_t) commands.length - total :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            total += written;
            
            if ([[NSDate date] timeIntervalSinceDate:startDate] >= 30.0) {     // 30000mS!!!
                break;
            }
        }
        
        if (total < (uint32_t) commands.length) {
            break;
        }
        
        port.endCheckedBlockTimeoutMillis = 30000;     // 30000mS!!!
        
        result = CommResultErrorEndCheckedBlock;
        
        [port endCheckedBlock:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
        if (printerStatus.offline == SM_TRUE) {
            break;
        }
        
        result = CommResultSuccess;
        code   = SMStarIOResultCodeSuccess;
        
        break;
    }
    
    if (completionHandler != nil) {
        completionHandler([[CommunicationResult alloc] initWithResult:result code:code]);
    }
    
    return result == CommResultSuccess;
}

+ (BOOL)sendCommandsDoNotCheckCondition:(NSData *)commands
                                   port:(SMPort *)port
                      completionHandler:(SendCompletionHandler)completionHandler {
    CommResult result = CommResultErrorOpenPort;
    NSInteger  code   = SMStarIOResultCodeFailedError;
    
    while (YES) {
        NSError *error = nil;
        
        if (port == nil) {
            break;
        }
        
        StarPrinterStatus_2 printerStatus;
        
        result = CommResultErrorWritePort;
        
        [port getParsedStatus:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
//      if (printerStatus.offline == SM_TRUE) {     // Do not check condition.
//          break;
//      }
        
        NSDate *startDate = [NSDate date];
        
        uint32_t total = 0;
        
        while (total < (uint32_t) commands.length) {
            uint32_t written = [port writePort:(unsigned char *) commands.bytes :total :(uint32_t) commands.length - total :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            total += written;
            
            if ([[NSDate date] timeIntervalSinceDate:startDate] >= 30.0) {     // 30000mS!!!
                break;
            }
        }
        
        if (total < (uint32_t) commands.length) {
            break;
        }
        
        [port getParsedStatus:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
//      if (printerStatus.offline == SM_TRUE) {     // Do not check condition.
//          break;
//      }
        
        result = CommResultSuccess;
        code   = SMStarIOResultCodeSuccess;
        
        break;
    }
    
    if (completionHandler != nil) {
        completionHandler([[CommunicationResult alloc] initWithResult:result code:code]);
    }
    
    return result == CommResultSuccess;
}

+ (BOOL)parseDoNotCheckCondition:(ISCPParser *)parser
                            port:(SMPort *)port
               completionHandler:(SendCompletionHandler)completionHandler {
    CommResult result = CommResultErrorOpenPort;
    NSInteger  code   = SMStarIOResultCodeFailedError;
    
    NSData *commands = [parser createSendCommands];
    
    while (YES) {
        NSError *error = nil;
        
        if (port == nil) {
            break;
        }
        
        StarPrinterStatus_2 printerStatus;
        
        result = CommResultErrorWritePort;
        
        [port getParsedStatus:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
//      if (printerStatus.offline == SM_TRUE) {     // Do not check condition.
//          break;
//      }
        
        NSDate *startDate = [NSDate date];
        
        uint32_t total = 0;
        
        while (total < (uint32_t) commands.length) {
            uint32_t written = [port writePort:(unsigned char *) commands.bytes :total :(uint32_t) commands.length - total :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            total += written;
            
            if ([[NSDate date] timeIntervalSinceDate:startDate] >= 30.0) {     // 30000mS!!!
                break;
            }
        }
        
        if (total < (uint32_t) commands.length) {
            break;
        }
        
        result = CommResultErrorReadPort;
        
        startDate = [NSDate date];     // Restart
        
        NSMutableData *receivedData = [NSMutableData data];
        
        while (YES) {
            uint8_t buffer[1024 + 8] = {0};
            
            if ([[NSDate date] timeIntervalSinceDate:startDate] >= 1.0) {     // 1000mS!!!
                break;
            }
            
            [NSThread sleepForTimeInterval:0.01];     // Break time.
            
            uint32_t readLength = [port readPort:buffer :0 :1024 :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            if (readLength == 0) {
                continue;
            }
            
            [receivedData appendBytes:buffer length:readLength];
            
            int recvDataLength = (int) receivedData.length;
            
            uint8_t *recvDataBytes = (uint8_t *) receivedData.bytes;
            
            if (parser.completionHandler(recvDataBytes, &recvDataLength) == StarIoExtParserCompletionResultSuccess) {
                result = CommResultSuccess;
                code   = SMStarIOResultCodeSuccess;
                
                break;
            }
        }
        
        break;
    }
    
    if (completionHandler != nil) {
        completionHandler([[CommunicationResult alloc] initWithResult:result code:code]);
    }
    
    return result == CommResultSuccess;
}

+ (BOOL)sendCommands:(NSData *)commands
            portName:(NSString *)portName
        portSettings:(NSString *)portSettings
             timeout:(NSInteger)timeout
   completionHandler:(SendCompletionHandler)completionHandler {
    CommResult result = CommResultErrorOpenPort;
    NSInteger  code   = SMStarIOResultCodeFailedError;
    
    if (timeout > UINT32_MAX) {
        timeout = UINT32_MAX;
    }
    
    SMPort *port = nil;
    
    while (YES) {
        NSError *error = nil;
        
        // Modify portSettings argument to improve connectivity when continously connecting via some Ethernet/Wireless LAN model.
        // (Refer Readme for details)
//      port = [SMPort getPort:portName :@"(your original portSettings);l1000)" :(uint32_t) timeout :&error];
        port = [SMPort getPort:portName :portSettings :(uint32_t) timeout :&error];
        
        if (port == nil) {
            code = error.code;
            break;
        }
        
        // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
        // (Refer Readme for details)
        NSOperatingSystemVersion version = {11, 0, 0};
        BOOL isOSVer11OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
        if ((isOSVer11OrLater) && ([portName.uppercaseString hasPrefix:@"BT:"])) {
            [NSThread sleepForTimeInterval:0.2];
        }
        
        StarPrinterStatus_2 printerStatus;
        
        result = CommResultErrorBeginCheckedBlock;
        
        [port beginCheckedBlock:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
        if (printerStatus.offline == SM_TRUE) {
            break;
        }
        
        result = CommResultErrorWritePort;
        
        NSDate *startDate = [NSDate date];
        
        uint32_t total = 0;
        
        while (total < (uint32_t) commands.length) {
            uint32_t written = [port writePort:(unsigned char *) commands.bytes :total :(uint32_t) commands.length - total :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            total += written;
            
            if ([[NSDate date] timeIntervalSinceDate:startDate] >= 30.0) {     // 30000mS!!!
                break;
            }
        }

        if (total < (uint32_t) commands.length) {
            break;
        }
        
        port.endCheckedBlockTimeoutMillis = 30000;     // 30000mS!!!
        
        result = CommResultErrorEndCheckedBlock;
        
        [port endCheckedBlock:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
        if (printerStatus.offline == SM_TRUE) {
            break;
        }
        
        result = CommResultSuccess;
        code   = SMStarIOResultCodeSuccess;
        
        break;
    }
    
    if (port != nil) {
        [SMPort releasePort:port];
        
        port = nil;
    }
    
    if (completionHandler != nil) {
        completionHandler([[CommunicationResult alloc] initWithResult:result code:code]);
    }
    
    return result == CommResultSuccess;
}

+ (BOOL)sendCommandsDoNotCheckCondition:(NSData *)commands
                               portName:(NSString *)portName
                           portSettings:(NSString *)portSettings
                                timeout:(NSInteger)timeout
                      completionHandler:(SendCompletionHandler)completionHandler {
    CommResult result = CommResultErrorOpenPort;
    NSInteger  code   = SMStarIOResultCodeFailedError;
    
    if (timeout > UINT32_MAX) {
        timeout = UINT32_MAX;
    }
    
    SMPort *port = nil;
    
    while (YES) {
        NSError *error = nil;
        
        // Modify portSettings argument to improve connectivity when continously connecting via some Ethernet/Wireless LAN model.
        // (Refer Readme for details)
//      port = [SMPort getPort:portName :@"(your original portSettings);l1000)" :(uint32_t) timeout :&error];
        port = [SMPort getPort:portName :portSettings :(uint32_t) timeout :&error];
        
        if (port == nil) {
            code = error.code;
            break;
        }
        
        // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
        // (Refer Readme for details)
        NSOperatingSystemVersion version = {11, 0, 0};
        BOOL isOSVer11OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
        if ((isOSVer11OrLater) && ([portName.uppercaseString hasPrefix:@"BT:"])) {
            [NSThread sleepForTimeInterval:0.2];
        }
        
        StarPrinterStatus_2 printerStatus;
        
        result = CommResultErrorWritePort;
        
        [port getParsedStatus:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
//      if (printerStatus.offline == SM_TRUE) {     // Do not check condition.
//          break;
//      }
        
        NSDate *startDate = [NSDate date];
        
        uint32_t total = 0;
        
        while (total < (uint32_t) commands.length) {
            uint32_t written = [port writePort:(unsigned char *) commands.bytes :total :(uint32_t) commands.length - total :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            total += written;
            
            if ([[NSDate date] timeIntervalSinceDate:startDate] >= 30.0) {     // 30000mS!!!
                break;
            }
        }
        
        if (total < (uint32_t) commands.length) {
            break;
        }
        
        [port getParsedStatus:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
//      if (printerStatus.offline == SM_TRUE) {     // Do not check condition.
//          break;
//      }
        
        result = CommResultSuccess;
        code   = SMStarIOResultCodeSuccess;
        
        break;
    }

    if (port != nil) {
        [SMPort releasePort:port];
        
        port = nil;
    }
    
    if (completionHandler != nil) {
        completionHandler([[CommunicationResult alloc] initWithResult:result code:code]);
    }
    
    return result == CommResultSuccess;
}

+ (void)connectBluetooth:(ConnectBluetoothCompletionHandler)completionHandler {
    [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:^(NSError *error) {
        BOOL result;
        
        NSString *title   = @"";
        NSString *message = @"";
        
        if (error != nil) {
            NSLog(@"Error:%@", error.description);
            
            switch (error.code) {
                case EABluetoothAccessoryPickerAlreadyConnected :
                    title   = @"Success";
                    message = @"";
                    
                    result = YES;
                    break;
                case EABluetoothAccessoryPickerResultCancelled :
                case EABluetoothAccessoryPickerResultFailed    :
                    title   = nil;
                    message = nil;
                    
                    result = NO;
                    break;
                default                                       :
//              case EABluetoothAccessoryPickerResultNotFound :
                    title   = @"Fail to Connect";
                    message = @"";
                    
                    result = NO;
                    break;
            }
        }
        else {
            title   = @"Success";
            message = @"";
            
            result = YES;
        }
        
        if (completionHandler != nil) {
            completionHandler(result, title, message);
        }
    }];
}

+ (BOOL)disconnectBluetooth:(NSString *)modelName
                   portName:(NSString *)portName
               portSettings:(NSString *)portSettings
                    timeout:(NSInteger)timeout
          completionHandler:(SendCompletionHandler)completionHandler {
    CommResult result = CommResultErrorOpenPort;
    NSInteger  code   = SMStarIOResultCodeFailedError;
    
    SMPort *port = nil;
    
    while (YES) {
        NSError *error = nil;
        
        port = [SMPort getPort:portName :portSettings :(uint32_t) timeout :&error];
        
        if (port == nil) {
            code = error.code;
            break;
        }
        
        // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
        // (Refer Readme for details)
        NSOperatingSystemVersion version = {11, 0, 0};
        BOOL isOSVer11OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
        if ((isOSVer11OrLater) && ([portName.uppercaseString hasPrefix:@"BT:"])) {
            [NSThread sleepForTimeInterval:0.2];
        }
        
        if ([modelName hasPrefix:@"TSP143IIIBI"]) {
            unsigned char commandBytes[] = {0x1b, 0x1c, 0x26, 0x49};     // Only TSP143IIIBI
            
            StarPrinterStatus_2 printerStatus;
            
            result = CommResultErrorBeginCheckedBlock;
            
            [port beginCheckedBlock:&printerStatus :2 :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            if (printerStatus.offline == SM_TRUE) {
                break;
            }
            
            result = CommResultErrorWritePort;
            
            NSDate *startDate = [NSDate date];
            
            uint32_t total = 0;
            
            while (total < sizeof(commandBytes)) {
                uint32_t written = [port writePort:(unsigned char *) commandBytes :total :sizeof(commandBytes) - total :&error];
                
                if (error != nil) {
                    code = error.code;
                    break;
                }
                
                total += written;
                
                if ([[NSDate date] timeIntervalSinceDate:startDate] >= 30.0) {     // 30000mS!!!
                    break;
                }
            }
            
            if (total < sizeof(commandBytes)) {
                break;
            }
            
//          port.endCheckedBlockTimeoutMillis = 30000;     // 30000mS!!!
//
//          [port endCheckedBlock:&printerStatus :2 :&error];
//
//          if (error != nil) {
//              code = error.code;
//              break;
//          }
//
//          if (printerStatus.offline == SM_TRUE) {
//              break;
//          }
        }
        else {
            result = CommResultErrorWritePort;
            
            if ([port disconnect:&error] == NO) {
                code = error.code;
                break;
            }
        }
        
        result = CommResultSuccess;
        code   = SMStarIOResultCodeSuccess;
        
        break;
    }

    if (port != nil) {
        [SMPort releasePort:port];
        
        port = nil;
    }
    
    if (completionHandler != nil) {
        completionHandler([[CommunicationResult alloc] initWithResult:result code:code]);
    }
    
    return result == CommResultSuccess;
}

+ (BOOL)confirmSerialNumber:(NSString *)portName
               portSettings:(NSString *)portSettings
                    timeout:(NSInteger)timeout
          completionHandler:(SerialNumberCompletionHandler)completionHandler {
    CommResult result = CommResultErrorOpenPort;
    NSInteger  code   = SMStarIOResultCodeFailedError;
    
    NSString *message = nil;
    
    if (timeout > UINT32_MAX) {
        timeout = UINT32_MAX;
    }
    
    SMPort *port = nil;
    
    while (YES) {
        NSError *error = nil;
        
        // Modify portSettings argument to improve connectivity when continously connecting via some Ethernet/Wireless LAN model.
        // (Refer Readme for details)
//      port = [SMPort getPort:portName :@"(your original portSettings);l1000)" :(uint32_t) timeout :&error];
        port = [SMPort getPort:portName :portSettings :(uint32_t) timeout :&error];
        
        if (port == nil) {
            code = error.code;
            break;
        }
        
        // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
        // (Refer Readme for details)
        NSOperatingSystemVersion version = {11, 0, 0};
        BOOL isOSVer11OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
        if ((isOSVer11OrLater) && ([portName.uppercaseString hasPrefix:@"BT:"])) {
            [NSThread sleepForTimeInterval:0.2];
        }
        
        StarPrinterStatus_2 printerStatus;
        
        result = CommResultErrorWritePort;
        
        [port getParsedStatus:&printerStatus :2 :&error];
        
        if (error != nil) {
            code = error.code;
            break;
        }
        
        NSDate *startDate = [NSDate date];
        
        uint32_t total = 0;
        
        unsigned char commandBytes[] = {0x1b, 0x1d, ')', 'I', 0x01, 0x00, 49};     // <ESC><GS>')''I'pLpHfn
        
        while (total < sizeof(commandBytes)) {
            uint32_t written = [port writePort:(unsigned char *) commandBytes :total :sizeof(commandBytes) - total :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            total += written;
            
            if ([[NSDate date] timeIntervalSinceDate:startDate] >=  3.0) {     //  3000mS!!!
                break;
            }
        }
        
        if (total < sizeof(commandBytes)) {
            break;
        }
        
        result = CommResultErrorReadPort;
        
        NSString *information = nil;
        
        NSMutableData *receivedData = [NSMutableData data];
        
        while (YES) {
            uint8_t readBuffer[1024 + 8] = {0};
            
            if ([[NSDate date] timeIntervalSinceDate:startDate] >=  3.0) {     //  3000mS!!!
                break;
            }
            
            [NSThread sleepForTimeInterval:0.01];     // Break time.
            
            uint32_t readLength = [port readPort:readBuffer :0 :1024 :&error];
            
            if (error != nil) {
                code = error.code;
                break;
            }
            
            if (readLength == 0) {
                continue;
            }
            
            [receivedData appendBytes:readBuffer length:readLength];
            
            if (receivedData.length >= 2) {
                for (int i = 0; i <= receivedData.length - 2; i++) {
                    if (readBuffer[i + 0] == 0x0a &&
                        readBuffer[i + 1] == 0x00) {
                        for (int j = 0; j <= receivedData.length - 9; j++) {
                            if (readBuffer[j + 0] == 0x1b &&
                                readBuffer[j + 1] == 0x1d &&
                                readBuffer[j + 2] == ')'  &&
                                readBuffer[j + 3] == 'I'  &&
                                readBuffer[j + 6] == 49) {
                                information = [NSString stringWithCString:(const char *) &readBuffer[j + 7]
                                                                 encoding:NSASCIIStringEncoding];
                                
                                result = CommResultSuccess;
                                break;
                            }
                        }
                        
                        break;
                    }
                }
            }
            
            if (result == CommResultSuccess) {
                break;
            }
        }
        
        if (result != CommResultSuccess) {
            break;
        }
        
        result = CommResultErrorReadPort;
        
        NSRange range = [information rangeOfString:@"PrSrN="];
        
        if (range.location == NSNotFound) {
            break;
        }
        
        NSString *work = [information substringFromIndex:range.location + range.length];
        
        range = [work rangeOfString:@","];
        
        if (range.location != NSNotFound) {
            work = [work substringToIndex:range.location];
        }
        
        message = work;
        
        result = CommResultSuccess;
        code   = SMStarIOResultCodeSuccess;
        
        break;
    }

    if (port != nil) {
        [SMPort releasePort:port];
        
        port = nil;
    }
    
    if (completionHandler != nil) {
        completionHandler([[CommunicationResult alloc] initWithResult:result code:code], message);
    }
    
    return result == CommResultSuccess;
}

+ (NSString *)getCommunicationResultMessage:(CommunicationResult *)communicationResult {
    NSString *message;

    switch (communicationResult.result) {
        case CommResultSuccess:
            message = @"Success!";
            break;
        case CommResultErrorOpenPort:
            message = @"Fail to openPort";
            break;
        case CommResultErrorBeginCheckedBlock:
            message = @"Printer is offline (beginCheckedBlock)";
            break;
        case CommResultErrorEndCheckedBlock:
            message = @"Printer is offline (endCheckedBlock)";
            break;
        case CommResultErrorReadPort:
            message = @"Read port error (readPort)";
            break;
        case CommResultErrorWritePort:
            message = @"Write port error (writePort)";
            break;
        default:
            message = @"Unknown error";
            break;
    }
    
    if (communicationResult.result != CommResultSuccess) {
        switch (communicationResult.code) {
            case SMStarIOResultCodeInUseError:
                message = [NSString stringWithFormat:@"%@\n\nError code: %ld (In Use)", message, (long) communicationResult.code];
                break;
            case SMStarIOResultCodeFailedError:
                message = [NSString stringWithFormat:@"%@\n\nError code: %ld (Failed)", message, (long) communicationResult.code];
                break;
            default:
                message = [NSString stringWithFormat:@"%@\n\nError code: %ld", message, (long) communicationResult.code];
                break;
        }
    }
    
    return message;
}

@end
