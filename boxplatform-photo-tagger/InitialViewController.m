//
//  InitialViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 11/21/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "InitialViewController.h"
#import "MainViewController.h"
#import "HelperClass.h"
#import <Lock/Lock.h>
#import <AFNetworking/AFNetworking.h>
#import <iOS-Color-Picker/FCColorPickerViewController.h>

@interface InitialViewController () <FCColorPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, copy) UIColor *color;
@property (weak, nonatomic) IBOutlet UIButton *buttonLogin;
@property (weak, nonatomic) IBOutlet UIImageView *logoImage;

@end

@implementation InitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //check if the user has already set a color in a previous session
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"myColor"]) {
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"myColor"];
        [self setColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorData]];
    } else {
        [self setColor:[UIColor colorWithRed:103.0f/255.0f green:103.0f/255.0f blue:103.0f/255.0f alpha:1.0]];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"image.png"];
    
    //check if the user has set a custom logo in a pre
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData *pngData = [NSData dataWithContentsOfFile:filePath];
        UIImage *image = [UIImage imageWithData:pngData];
        _logoImage.image = image;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //check if the user has already set a color in a previous session
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"myColor"]) {
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"myColor"];
        [self setColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorData]];
    } else {
        [self setColor:[UIColor colorWithRed:103.0f/255.0f green:103.0f/255.0f blue:103.0f/255.0f alpha:1.0]];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Logo.png"];
    
    //check if the user has set a custom logo in a pre
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData *pngData = [NSData dataWithContentsOfFile:filePath];
        UIImage *image = [UIImage imageWithData:pngData];
        _logoImage.image = image;
    }
    
}

- (IBAction)presentLoginScreen:(id)sender {
    [self setupAuth0Theme];
    
    A0Lock *lock = [A0Lock sharedLock];
    
    A0LockViewController *controller = [lock newLockViewController];
    controller.onAuthenticationBlock = ^(A0UserProfile *profile, A0Token *token) {
        // Add the Auth0 token to the user defaults
        __block NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:token.idToken forKey:@"auth0_token"];
        [defaults synchronize];
        
        //grab contents of config.plist in order to get the webtask URL
        NSURL *file = [[NSBundle mainBundle] URLForResource:@"config" withExtension:@"plist"];
        NSDictionary *plistContent = [NSDictionary dictionaryWithContentsOfURL:file];
        NSURL *URL = [NSURL URLWithString:[plistContent objectForKey:@"webtaskUrl"]];
        
        //set authorzation header
        NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", token.idToken];
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [manager.requestSerializer setValue:authHeader forHTTPHeaderField:@"Authorization"];
        [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            [defaults setObject:[responseObject valueForKey:@"access_token"] forKey:@"box_access_token"];
            [self dismissViewControllerAnimated:YES completion:nil];
            [self performSegueWithIdentifier:@"showProfile" sender:profile];
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error getting Box Access Token: %@", error);
        }];
        
    };
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)setupAuth0Theme {
    //if the user has selected a custom color, apply it to the Auth0 Lock
    if (_color) {
        A0Theme *myTheme = [[A0Theme alloc] init];
        [myTheme registerColor:_color forKey:@"A0ThemePrimaryButtonNormalColor"];
        [[A0Theme sharedInstance] registerTheme:myTheme];
    }
}

//IBAction to handle the user pressing the custom color button
- (IBAction)chooseNavBarColor:(id)sender {
    
    FCColorPickerViewController *colorPicker = [FCColorPickerViewController colorPickerWithColor:self.color
                                                                                        delegate:self];
    colorPicker.tintColor = [UIColor lightGrayColor];
    [colorPicker setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:colorPicker
                       animated:YES
                     completion:nil];
}

- (void)colorPickerViewController:(FCColorPickerViewController *)colorPicker
                   didSelectColor:(UIColor *)color
{
    self.color = color;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorPickerViewControllerDidCancel:(FCColorPickerViewController *)colorPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setColor:(UIColor *)color
{
    //set the selected color and save to NSUserDefaults for subsequent sessions
    _color = [color copy];
    [[UINavigationBar appearance] setBarTintColor:_color];
    [_buttonLogin setBackgroundColor:color];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_color];
    [defaults setObject:colorData forKey:@"myColor"];
    [defaults synchronize];
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
        _logoImage.image = image;
        
        // Create path.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Logo.png"];
        
        // Save image.
        [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
    }
}

- (IBAction)didPressLogoSelectButton:(id)sender {
    // Let the user pick an image from their library.
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"showProfile"]) {
        MainViewController *destViewController = segue.destinationViewController;
        destViewController.userProfile = sender;
        if (_logoImage.image) {
            destViewController.logoImage = _logoImage.image;
        }
    }}


@end
