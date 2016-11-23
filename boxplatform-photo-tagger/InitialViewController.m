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

@interface InitialViewController () <FCColorPickerViewControllerDelegate>
@property (nonatomic, copy) UIColor *color;
@property (weak, nonatomic) IBOutlet UIButton *buttonLogin;

@end

@implementation InitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (_color) {
        A0Theme *myTheme = [[A0Theme alloc] init];
        [myTheme registerColor:_color forKey:@"A0ThemePrimaryButtonNormalColor"];
        [[A0Theme sharedInstance] registerTheme:myTheme];
    }
}


- (IBAction)chooseNavBarColor:(id)sender {
    
    FCColorPickerViewController *colorPicker = [FCColorPickerViewController colorPickerWithColor:self.color
                                                                                        delegate:self];
    colorPicker.tintColor = [UIColor whiteColor];
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
    _color = [color copy];
    [[UINavigationBar appearance] setBarTintColor:_color];
    [_buttonLogin setBackgroundColor:color];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_color];
    [defaults setObject:colorData forKey:@"myColor"];
    [defaults synchronize];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"showProfile"]) {
        MainViewController *destViewController = segue.destinationViewController;
        destViewController.userProfile = sender;
    }}


@end
