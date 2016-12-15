//
//  FileDetailsViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 12/14/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "FileDetailsViewController.h"
#import <MapKit/MapKit.h>
#import <BoxContentSDK/BoxContentSDK.h>
#import <CoreLocation/CoreLocation.h>

@interface FileDetailsViewController () <BOXAPIAccessTokenDelegate>
@property (strong, nonatomic) IBOutlet UILabel *labelFileName;
@property (strong, nonatomic) IBOutlet UILabel *labelGps;
@property (strong, nonatomic) IBOutlet UITextView *textMetadata;
@property (strong, nonatomic) IBOutlet UITextView *textAddress;
@property (strong, nonatomic) IBOutlet UIImageView *imageFile;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;


@property (strong, nonatomic) BOXContentClient *boxClient;

@end

@implementation FileDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //initialize the Box client
    _boxClient = [BOXContentClient clientForNewSession];
    [_boxClient setAccessTokenDelegate:self];
    
    //update MapView
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:_placemark];
    [_mapView addAnnotation:placemark];
    [self updateMapView:_location];
}

- (void)viewWillAppear:(BOOL)animated {
    _labelFileName.text = _boxFile.name;
    _imageFile.image = _image;
    
    BOXMetadataRequest *mdreq = [_boxClient metadataAllInfoRequestWithFileID:_boxFile.modelID];
    [mdreq performRequestWithCompletion:^(NSArray *metadata, NSError *error){
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            BOXMetadata *md = metadata[0];
            NSString *mdText;
            //be sure we are displaying the correct metadata
            if (md.info[@"tags"]){
                //photo tags
                _textMetadata.text = md.info[@"tags"];
            } else if (md.info[@"ocrpage1"]) {
                //OCR scanning
                mdText = md.info[@"ocrpage1"];
            }
            _labelGps.text = md.info[@"gpslatlong"];
            _textAddress.text = md.info[@"gpsaddress"];
        }
    }];
}

- (void)updateMapView:(CLLocation *)location {
    
    // create a region and pass it to the Map View
    CLLocationCoordinate2D coordinate = [_location coordinate];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - BOXAPIAccessTokenDelegate
//Delegate method override for changing the default authentication for the Box iOS SDK
//I am using NSUserDefaults, which would not be the way to handle this in a production scenario
- (void)fetchAccessTokenWithCompletion:(void (^)(NSString *, NSDate *, NSError *))completion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"Box Access token is: %@", [defaults objectForKey:@"box_access_token"]);
    completion([defaults objectForKey:@"box_access_token"], [NSDate dateWithTimeIntervalSinceNow:100], nil);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
