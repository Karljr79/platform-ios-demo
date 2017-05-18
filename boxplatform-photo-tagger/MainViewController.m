//
//  ViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/6/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "MainViewController.h"
#import "HelperClass.h"
#import <Lock/Lock.h>
#import <BoxContentSDK/BoxContentSDK.h>

@interface MainViewController () <BOXAPIAccessTokenDelegate>
@property (weak, nonatomic) IBOutlet UILabel *txtUsername;
@property (weak, nonatomic) IBOutlet UILabel *txtAppUserId;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIButton *buttonSearch;
@property (weak, nonatomic) IBOutlet UIButton *buttonUpload;
@property (weak, nonatomic) IBOutlet UIImageView *imageLogo;
@property (weak, nonatomic) IBOutlet UIButton *buttonScan;
@property (strong, nonatomic) BOXContentClient *boxClient;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //show a spinner
    [self.view addSubview:_spinner];
    [_spinner startAnimating];
    
    _txtUsername.text = [NSString stringWithFormat:@"Username: %@", self.userProfile.name];
    _txtAppUserId.text = [NSString stringWithFormat:@"App User ID: %@", [self.userProfile.extraInfo objectForKey:@"box_id"]];
    
    //initialize the Box client
    _boxClient = [BOXContentClient clientForNewSession];
    [_boxClient setAccessTokenDelegate:self];
    
    
    if(![self checkForUploadFolder]) {
        //We dont have an upload folder make one and store the ID
        NSString *folderName = [HelperClass getFileName:@"iOS Photo Uploads"];
        BOXFolderCreateRequest *folderCreateRequest = [_boxClient folderCreateRequestWithName:folderName parentFolderID:BOXAPIFolderIDRoot];
        [folderCreateRequest performRequestWithCompletion:^(BOXFolder *folder, NSError *error) {
            __block NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:folder.modelID forKey:@"uploadFolder"];
            [defaults synchronize];
        }];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    UIColor *color = [HelperClass getDefaultColor];
    [_buttonSearch setBackgroundColor:color];
    [_buttonUpload setBackgroundColor:color];
    [_buttonScan setBackgroundColor:color];
    
    if (_logoImage) {
        _imageLogo.image = _logoImage;
        
        //set Navbar image
        UIImageView *navigationImage=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 98, 34)];
        navigationImage.image=_logoImage;
        
        UIImageView *workaroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 98, 34)];
        [workaroundImageView addSubview:navigationImage];
        self.navigationItem.titleView=workaroundImageView;
    }
    
    
}

-(Boolean)checkForUploadFolder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([[[defaults dictionaryRepresentation] allKeys] containsObject:@"uploadFolder"]){
        
        NSLog(@"uploadFolder ID Found");
        return TRUE;
    } else {
        return FALSE;
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
