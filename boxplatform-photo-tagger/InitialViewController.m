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

@interface InitialViewController ()

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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"showProfile"]) {
        MainViewController *destViewController = segue.destinationViewController;
        destViewController.userProfile = sender;
    }}


@end
