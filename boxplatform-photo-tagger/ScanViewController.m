//
//  ScanViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 11/28/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "ScanViewController.h"
#import "HelperClass.h"
#import "FileDetailsViewController.h"
#import <BoxContentSDK/BoxContentSDK.h>
#import <TesseractOCR/TesseractOCR.h>
#import <CoreLocation/CoreLocation.h>

@interface ScanViewController () <UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
BOXAPIAccessTokenDelegate,
G8TesseractDelegate,
CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textOCRData;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnUpload;
@property (weak, nonatomic) IBOutlet UIButton *btnScanUsingCamera;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectImage;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSString *ocrText;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *latitude;
@property (strong, nonatomic) NSString *longitude;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSData *imageToUpload;
@property (strong, nonatomic) BOXFile *boxFile;
//Location services variables
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLPlacemark *placemark;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;


@property (strong, nonatomic) BOXContentClient *boxClient;

@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //init location manager
    _locationManager = [[CLLocationManager alloc] init];
    _geocoder = [[CLGeocoder alloc] init];
    
    // Create a queue to perform recognition operations
    self.operationQueue = [[NSOperationQueue alloc] init];
    
    [self.activityIndicator setHidden:TRUE];
    
    //set the upload button to be disabled
    _btnUpload.enabled = FALSE;
    _textOCRData.hidden = FALSE;
    
    //initialize the Box client
    _boxClient = [BOXContentClient clientForNewSession];
    [_boxClient setAccessTokenDelegate:self];
    
    //update location
    [self getCurrentLocation];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //update button colors
    UIColor *color = [HelperClass getDefaultColor];
    [_btnScanUsingCamera setBackgroundColor:color];
    [_btnSelectImage setBackgroundColor:color];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//user pressed the take photo button
- (IBAction)didPressScanButton:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // Let the user take a photo with the device camera
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.allowsEditing = YES;
        picker.delegate = self;
        
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        //if the device has no camera or we're on the simulator, show alert
        UIViewController *alert = [HelperClass showAlertWithTitle:@"Error" andMessage:@"Device camera unavailable!"];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)didPressImageSelectButton:(id)sender {
    // Let the user pick an image from their library.
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)didPressUploadToBoxButton:(id)sender {
    if(_imageToUpload){
        [self uploadPhotoToBox:_imageToUpload];
    } else {
        NSLog(@"Error: No Image Found");
        UIViewController *alert = [HelperClass showAlertWithTitle:@"Error" andMessage:@"Sorry, there was an error recognizing the image"];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

// Step 2 handle uploading the photo file to Box
- (void)uploadPhotoToBox:(NSData*)image {
    //start the spinner
    [_activityIndicator startAnimating];
    
    _progressView.hidden = FALSE;
    
    NSString *fileName = [HelperClass getFileNameWithBaseName:@"BoxPlatformPhotoScan" andExtension:@"jpg"];
    
    //prepare the request.  Folder ID is hard coded for demo purposes.  Ideally you would have
    //a defined folder structure for each app user and use that to determine where images should be uploaded to
    BOXFileUploadRequest *request = [_boxClient fileUploadRequestToFolderWithID:@"0" fromData:image fileName:fileName];
    
    //send the request
    [request performRequestWithProgress:^(long long totalBytesTransferred, long long totalBytesExpectedToTransfer) {
        float progress = (float)totalBytesTransferred / (float)totalBytesExpectedToTransfer;
        [_progressView setProgress:progress animated:YES];
    } completion:^(BOXFile *file, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            UIViewController *alert = [HelperClass showAlertWithTitle:@"Error" andMessage:@"Sorry, there was an error uploading the file"];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        } else {
            [_activityIndicator stopAnimating];
            NSLog(@"Successfully uploaded file ID: %@", file.modelID);
            _boxFile = file;
            _progressView.hidden = TRUE;
            //now that the upload was successful, set the ocr data for the returned file id
            [self setBoxMetadataWithFileId:file.modelID];
        }
    }];
}

// Step 3 handle setting the metadata tags
- (void)setBoxMetadataWithFileId:(NSString*)fileId {
    BOXMetadataKeyValue *task = [[BOXMetadataKeyValue alloc] initWithPath:@"ocrpage1" value:_ocrText];
    BOXMetadataKeyValue *task2 = [[BOXMetadataKeyValue alloc] initWithPath:@"ocrversion" value:@"Tesseract"];
    BOXMetadataKeyValue *task3 = [[BOXMetadataKeyValue alloc] initWithPath:@"gpslatitude" value:_latitude];
    BOXMetadataKeyValue *task4 = [[BOXMetadataKeyValue alloc] initWithPath:@"gpslongitude" value:_longitude];
    BOXMetadataKeyValue *task5 = [[BOXMetadataKeyValue alloc] initWithPath:@"gpsaddress" value:_address];
    NSArray *tasks = [[NSArray alloc] initWithObjects:task, task2, task3, task4, task5, nil];
    BOXMetadataCreateRequest *metadataCreateRequest = [_boxClient metadataCreateRequestWithFileID:fileId scope:@"enterprise" template:@"ocrdata" tasks:tasks];
    [metadataCreateRequest performRequestWithCompletion:^(BOXMetadata *metadata, NSError *error){
        if(error){
            NSLog(@"Error Setting Metadata: %@", error);
        } else {
//            UIViewController *alert = [HelperClass showAlertWithTitle:[NSString stringWithFormat:@"File ID: %@", fileId] andMessage:[NSString stringWithFormat:@"OCR Text Set! /n Address: %@", metadata.info[@"gpsaddress"]]];
//            [self.navigationController presentViewController:alert animated:YES completion:nil];
//            NSLog(@"Metadata Set");
            [self performSegueWithIdentifier:@"ScanFileDetails" sender:self];

        }
    }];
}

-(void)recognizeImageWithTesseract:(UIImage *)image {
    // Animate a progress activity indicator
    [self.activityIndicator startAnimating];
    
    // Create a new `G8RecognitionOperation` to perform the OCR asynchronously
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage:@"eng"];
    
    // Use the original Tesseract engine mode in performing the recognition
    operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
    
    // Let Tesseract automatically segment the page into blocks of text
    operation.tesseract.pageSegmentationMode = G8PageSegmentationModeAutoOnly;
    
    // Optionally limit the time Tesseract should spend performing the
    operation.tesseract.maximumRecognitionTime = 1.0;
    
    // Set the delegate for the recognition to be this class
    // (see `progressImageRecognitionForTesseract` and
    // `shouldCancelImageRecognitionForTesseract` methods below)
    operation.delegate = self;
    
    // Set the image on which Tesseract should perform recognition
    operation.tesseract.image = image;
    
    //OCR Completion Block
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
        // Fetch the recognized text
        NSString *recognizedText = tesseract.recognizedText;
        
        NSLog(@"%@", recognizedText);
        
        // Remove the animated progress activity indicator
        [self.activityIndicator stopAnimating];
        [self.activityIndicator setHidden:TRUE];
        
        _textOCRData.text = recognizedText;
        _ocrText = recognizedText;
        
        NSUInteger count = recognizedText.length;
        NSLog(@"Count: %lu", (unsigned long)count);
    };
    
    // Finally, add the recognition operation to the queue
    [self.operationQueue addOperation:operation];
}

//helper function to get the user's location
- (void)getCurrentLocation {
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager requestWhenInUseAuthorization];
    
    [_locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIViewController *errorAlert = [HelperClass showAlertWithTitle:[NSString stringWithFormat:@"Error"] andMessage:[NSString stringWithFormat:@"Failed to Get Your Location"]];
    [self.navigationController presentViewController:errorAlert animated:YES completion:nil];}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    _location = newLocation;
    
    // Stop Location Manager
    [_locationManager stopUpdatingLocation];
    
    _latitude = [NSString stringWithFormat:@"%.8f", _location.coordinate.latitude];
    _longitude = [NSString stringWithFormat:@"%.8f", _location.coordinate.longitude];
    
    // Reverse Geocoding
    NSLog(@"Resolving the Address");
    [_geocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"Found address: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            _placemark = [placemarks lastObject];
            _address = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@",
                        _placemark.subThoroughfare, _placemark.thoroughfare,
                        _placemark.locality, _placemark.administrativeArea,
                        _placemark.postalCode, _placemark.country];
        } else {
            NSLog(@"Error getting address: %@", error.debugDescription);
        }
    } ];
}

#pragma mark - UIImagePicker

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    // Encode as a JPEG.
    _imageToUpload = UIImageJPEGRepresentation(image, 1.0);
    //send image to OCR recognition
    [self recognizeImageWithTesseract:image];
    //enable button
    _btnUpload.enabled = TRUE;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ScanFileDetails"])
    {
        FileDetailsViewController *fvc = [segue destinationViewController];
        //pass the file to the next view
        fvc.boxFile = _boxFile;
        fvc.placemark = _placemark;
        fvc.location = _location;
    }
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

@end
