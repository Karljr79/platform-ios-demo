//
//  SearchViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/8/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchResultsTableViewController.h"
#import "HelperClass.h"
#import <BoxContentSDK/BoxContentSDK.h>

@interface SearchViewController () <UITextFieldDelegate, BOXAPIAccessTokenDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textInputSearch;
@property (strong, nonatomic) NSArray *items;
@property (weak, nonatomic) IBOutlet UIButton *buttonSearch;
@property (strong, nonatomic) BOXContentClient *boxClient;
- (IBAction)pressedSearchButton:(id)sender;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //set delegate for the text input
    _textInputSearch.delegate = self;

    //initialize Box client
    _boxClient = [BOXContentClient clientForNewSession];
    [_boxClient setAccessTokenDelegate:self];
}

- (void) viewWillAppear:(BOOL)animated {
    //update button colors
    UIColor *color = [HelperClass getDefaultColor];
    [_buttonSearch setBackgroundColor:color];
    [_textInputSearch setTintColor:color];
}

- (IBAction)pressedSearchButton:(id)sender {
    if(_textInputSearch.text.length > 0) {
        [self performBoxSearchWithText:_textInputSearch.text];
    } else {
        UIViewController *alert = [HelperClass showAlertWithTitle:@"Error" andMessage:@"No Text Entered"];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - BOXAPIAccessTokenDelegate
//Delegate method override for changing the default authentication for the Box iOS SDK
- (void)fetchAccessTokenWithCompletion:(void (^)(NSString *, NSDate *, NSError *))completion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"Box Access token is: %@", [defaults objectForKey:@"box_access_token"]);
    completion([defaults objectForKey:@"box_access_token"], [NSDate dateWithTimeIntervalSinceNow:100], nil);
}

#pragma mark - UITextField
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    [self performBoxSearchWithText:_textInputSearch.text];
    
    return YES;
}

#pragma mark - Box Functions
- (void)performBoxSearchWithText:(NSString *)searchText {
    
    //create search request for photos
    BOXSearchRequest *request = [_boxClient searchRequestWithQuery:searchText inRange:NSMakeRange(0, 200)];
    request.fileExtensions = @[@"jpg", @"png"];
    
    //send the request
    [request performRequestWithCompletion:^(NSArray *items, NSUInteger totalCount, NSRange range, NSError *error) {
        if(error){
            NSLog(@"Error Searching for Files: %@", error);
            UIViewController *alert = [HelperClass showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        } else if ([items count] == 0) {
            UIViewController *alert = [HelperClass showAlertWithTitle:@"Search" andMessage:@"No Results"];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        } else {
            //set the items array and trigger segue
            _items = items;
            [self performSegueWithIdentifier:@"searchResults" sender:self];
        }
    }];
    
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //pass the search results to the SearchResultsTableViewController
    if ([[segue identifier] isEqualToString:@"searchResults"])
    {
        SearchResultsTableViewController *svc = (SearchResultsTableViewController*)[segue destinationViewController];
        svc.results = _items;
    }
}


@end
