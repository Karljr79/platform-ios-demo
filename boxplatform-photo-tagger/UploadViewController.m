//
//  UploadViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/6/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "UploadViewController.h"
#import "ClarifaiClient.h"
#import "HelperClass.h"
#import <BoxContentSDK/BoxContentSDK.h>

#define INSURANCE_MODE False

@interface UploadViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, BOXAPIAccessTokenDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectImage;
@property (weak, nonatomic) IBOutlet UIButton *btnTakePhoto;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnUploadToBox;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) NSString *tags;
@property (strong, nonatomic) NSData *imageToUpload;

@property (strong, nonatomic) BOXContentClient *boxClient;
@property (strong, nonatomic) ClarifaiClient *clarifaiClient;

- (IBAction)pressedUploadToBoxButton:(id)sender;
- (IBAction)pressedSelectImageButton:(id)sender;
- (IBAction)pressedTakePhotoButton:(id)sender;

@end


@implementation UploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //grab Clarifai creds from config.plist
    //grab contents of config.plist
    NSURL *file = [[NSBundle mainBundle] URLForResource:@"config" withExtension:@"plist"];
    NSDictionary *plistContent = [NSDictionary dictionaryWithContentsOfURL:file];
    
    //grab hard-coded app user id from the config.plist
    NSString *clarifaiClientId = [plistContent objectForKey:@"clarifaiClientId"];
    NSString *clarifaiSecret = [plistContent objectForKey:@"clarifaiSecret"];
    
    //initialize the clarifai client
    _clarifaiClient = [[ClarifaiClient alloc] initWithAppID:clarifaiClientId appSecret:clarifaiSecret];
    
    //initialize the Box client
    _boxClient = [BOXContentClient clientForNewSession];
    [_boxClient setAccessTokenDelegate:self];
}

- (void) viewWillAppear:(BOOL)animated {
    //update button colors
    UIColor *color = [HelperClass getDefaultColor];
    [_btnTakePhoto setBackgroundColor:color];
    [_btnSelectImage setBackgroundColor:color];
}

#pragma mark - Button Handlers

- (IBAction)pressedUploadToBoxButton:(id)sender {
    if(_imageToUpload){
        [self uploadPhotoToBox:_imageToUpload];
    } else {
        NSLog(@"Error: No Image Found");
        UIViewController *alert = [HelperClass showAlertWithTitle:@"Error" andMessage:@"Sorry, there was an error recognizing the image"];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)pressedSelectImageButton:(id)sender {
    // Let the user pick an image from their library.
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)pressedTakePhotoButton:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
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

#pragma mark - UIImagePicker

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image) {
        // The user picked an image. Update UI.
        _imageView.image = image;
        _btnSelectImage.enabled = NO;
        _btnTakePhoto.enabled = NO;
        
        // Encode as a JPEG.
        _imageToUpload = UIImageJPEGRepresentation(image, 1.0);
        
        // Run the image through Clarifai
        [self recognizeImage:image];
    }
}

// Step 1
- (void)recognizeImage:(UIImage *)image
{
    // Scale down the image.
    UIImage *scaledImage = [self scaleDownImage:image];
    
    //convert it to jpeg
    NSData *jpeg = UIImageJPEGRepresentation(scaledImage, 0.9);
    
    // Send the JPEG to Clarifai for standard image tagging.
    [_clarifaiClient recognizeJpegs:@[jpeg] completion:^(NSArray *results, NSError *error) {
        // Handle the response from Clarifai. This happens asynchronously.
        if (error) {
            NSLog(@"Error: %@", error);
            UIViewController *alert = [HelperClass showAlertWithTitle:@"Error" andMessage:@"Sorry, there was an error recognizing the image"];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        } else {
            ClarifaiResult *result = results.firstObject;
            //Store tags as comma separated list and make upload button active
            _tags = [result.tags componentsJoinedByString:@", "];
            _btnUploadToBox.enabled = YES;
            NSLog(@"Clarifai Found: %@", _tags);
        }
        _btnSelectImage.enabled = YES;
        _btnTakePhoto.enabled = YES;
    }];
}


// Step 2 handle uploading the photo file to Box
- (void)uploadPhotoToBox:(NSData*)image {
    //start the spinner
    [_spinner startAnimating];
    
//    //add a timestamp to the file name to avoid duplicate file names
//    NSString *prefixString = @"BoxPlatformUpload";
//    time_t unixTime = (time_t) [[NSDate date] timeIntervalSince1970];
//    NSString *timestamp = [NSString stringWithFormat:@"%ld", unixTime];
//    NSString *fileName = [NSString stringWithFormat:@"%@_%@.jpg", prefixString, timestamp];
    
    NSString *fileName = [HelperClass getFileNameWithBaseName:@"BoxPlatformPhotoUpload" andExtension:@"jpg"];
    
    //prepare the request.  Folder ID is hard coded for demo purposes.  Ideally you would have
    //a defined folder structure for each app user and use that to determine where images should be uploaded to
    BOXFileUploadRequest *request = [_boxClient fileUploadRequestToFolderWithID:@"0" fromData:image fileName:fileName];
    
    //send the request
    [request performRequestWithProgress:^(long long totalBytesTransferred, long long totalBytesExpectedToTransfer) {
    } completion:^(BOXFile *file, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            UIViewController *alert = [HelperClass showAlertWithTitle:@"Error" andMessage:@"Sorry, there was an error uploading the file"];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        } else {
            [_spinner stopAnimating];
            NSLog(@"Successfully uploaded file ID: %@", file.modelID);
        
            //now that the upload was successful, set the metadata for the returned file id
            [self setBoxMetadataWithFileId:file.modelID];
        }
    }];
}

// Step 3 handle setting the metadata tags
- (void)setBoxMetadataWithFileId:(NSString*)fileId {
    BOXMetadataKeyValue *task = [[BOXMetadataKeyValue alloc] initWithPath:@"tags" value:_tags];
    BOXMetadataKeyValue *task2 = [[BOXMetadataKeyValue alloc] initWithPath:@"imageRecognitionVersion" value:@"Clarifai"];
    NSArray *tasks = [[NSArray alloc] initWithObjects:task, task2, nil];
    BOXMetadataCreateRequest *metadataCreateRequest = [_boxClient metadataCreateRequestWithFileID:fileId scope:@"enterprise" template:@"photouploads" tasks:tasks];
    [metadataCreateRequest performRequestWithCompletion:^(BOXMetadata *metadata, NSError *error){
        if(error){
            NSLog(@"Error Setting Metadata: %@", error);
        } else {
            UIViewController *alert = [HelperClass showAlertWithTitle:[NSString stringWithFormat:@"File ID: %@", fileId] andMessage:[NSString stringWithFormat:@"Metadata: %@", _tags]];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        }
    }];
}


-(UIImage*)scaleDownImage:(UIImage *)image
{
    CGSize size = CGSizeMake(320, 320 * image.size.height / image.size.width);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
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
