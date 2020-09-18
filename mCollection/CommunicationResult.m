//
//  CommunicationResult.m
//  ObjectiveC SDK
//
//  Copyright © 2019 Star Micronics. All rights reserved.
//

#import "CommunicationResult.h"

@implementation CommunicationResult

- (id)initWithResult:(CommResult)result code:(NSInteger)code {
    self = [super init];
    
    if (self == nil) {
        return nil;
    }
    
    _result = result;
    _code   = code;
    
    return self;
}

@end

