//
//  ViewController.h
//  mpopGroceryDemo
//
//  Created by Guillermo Cubero on 11/28/17.
//  Copyright © 2017 Guillermo Cubero. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <StarIO_Extension/StarIoExtManager.h>

#import <StarMgsIO/StarMgsIO.h>

@interface ViewController : UIViewController <StarIoExtManagerDelegate, STARDeviceManagerDelegate, STARScaleDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UITextFieldDelegate>

@property(nonatomic) STARScale *scale;

@end

