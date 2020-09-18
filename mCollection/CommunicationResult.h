//
//  CommunicationResult.h
//  ObjectiveC SDK
//
//  Copyright © 2019 Star Micronics. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CommResult) {
    CommResultSuccess = 0,
    CommResultErrorOpenPort,
    CommResultErrorBeginCheckedBlock,
    CommResultErrorEndCheckedBlock,
    CommResultErrorWritePort,
    CommResultErrorReadPort,
    CommResultErrorUnknown,
};

@interface CommunicationResult : NSObject

@property (nonatomic) CommResult result;
@property (nonatomic) NSInteger  code;

- (id)initWithResult:(CommResult)result code:(NSInteger)code;

@end
