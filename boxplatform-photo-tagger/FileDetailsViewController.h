//
//  FileDetailsViewController.h
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 12/14/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BoxContentSDK/BoxContentSDK.h>
#import <CoreLocation/CoreLocation.h>

@interface FileDetailsViewController : UIViewController
@property (strong, nonatomic) BOXFile* boxFile;
@property (strong, nonatomic) CLPlacemark *placemark;
@property (strong, nonatomic) CLLocation *location;

@end
