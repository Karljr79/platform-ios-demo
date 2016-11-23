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

@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UILabel *txtUsername;
@property (weak, nonatomic) IBOutlet UILabel *txtAppUserId;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //show a spinner
    [self.view addSubview:_spinner];
    [_spinner startAnimating];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *auth0_token = [defaults objectForKey:@"auth0_token"];
    
    _txtUsername.text = self.userProfile.name;
    _txtAppUserId.text = [self.userProfile.extraInfo objectForKey:@"box_id"];
}

@end
