//
//  ScanViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 11/28/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "ScanViewController.h"
#import "HelperClass.h"
#import <BoxContentSDK/BoxContentSDK.h>
#import <TesseractOCR/TesseractOCR.h>

@interface ScanViewController () <UINavigationControllerDelegate,
                                  UIImagePickerControllerDelegate,
                                  BOXAPIAccessTokenDelegate,
                                  G8TesseractDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textOCRData;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnUpload;
@property (weak, nonatomic) IBOutlet UIButton *btnScanUsingCamera;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectImage;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (weak, nonatomic) NSString *ocrText;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) BOXContentClient *boxClient;

@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a queue to perform recognition operations
    self.operationQueue = [[NSOperationQueue alloc] init];
    
    //set the upload button to be disabled
    _btnUpload.enabled = FALSE;
    _textOCRData.hidden = FALSE;
    
    //initialize the Box client
    _boxClient = [BOXContentClient clientForNewSession];
    [_boxClient setAccessTokenDelegate:self];
}

- (void) viewWillAppear:(BOOL)animated {
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
        
//        // Spawn an alert with the recognized text
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OCR Result"
//                                                        message:recognizedText
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
        
        _textOCRData.text = recognizedText;
        
        NSUInteger count = recognizedText.length;
        NSLog(@"Count: %lu", (unsigned long)count);
    };
    
    // Finally, add the recognition operation to the queue
    [self.operationQueue addOperation:operation];
}

#pragma mark - UIImagePicker

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //send image to OCR recognition
    [self recognizeImageWithTesseract:image];
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
