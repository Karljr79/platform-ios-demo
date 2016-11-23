//
//  SearchResultsTableViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/8/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "SearchResultsTableViewController.h"
#import "SearchResultsTableViewCell.h"
#import "FileDetailViewController.h"
#import "HelperClass.h"
#import <BoxContentSDK/BoxContentSDK.h>
#import <BoxPreviewSDK/BoxPreviewSDK.h>

@interface SearchResultsTableViewController () <BOXAPIAccessTokenDelegate, BOXFilePreviewControllerDelegate>
@property (weak, nonatomic) NSString *selectedItemId;
@property (strong, nonatomic) BOXContentClient *boxClient;

@end

@implementation SearchResultsTableViewController

@synthesize results;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //initialize Box client
    _boxClient = [BOXContentClient clientForNewSession];
    [_boxClient setAccessTokenDelegate:self];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Handle populating the cells with data from the file
    SearchResultsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchResultCell" forIndexPath:indexPath];
    BOXItem *item = self.results[indexPath.row];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-YYYY"];
    
    cell.labelFileName.text = item.name;
    cell.labelCreatedDate.text = [NSString stringWithFormat:@"Created: %@",[dateFormatter stringFromDate:item.createdDate]];
    
    BOXFileThumbnailRequest *request = [_boxClient fileThumbnailRequestWithID:item.modelID size:128];
    [request performRequestWithProgress:^(long long totalBytesTransferred, long long totalBytesExpectedToTransfer) {
    } completion:^(UIImage *image, NSError *error) {
        if(error){
            NSLog(@"error getting thumbnail: %@", error);
        } else {
            cell.imageThumbnail.image = image;
        }
    }];
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOXFile *file = self.results[indexPath.row];
    self.selectedItemId = file.modelID;
    

    BOXPreviewClient *pc = [[BOXPreviewClient alloc] initWithContentClient:_boxClient];
    BOXFilePreviewController *fpc = [[BOXFilePreviewController alloc] initWithPreviewClient:pc file:file];
    fpc.delegate = self;
    [self.navigationController pushViewController:fpc animated:YES];
}

#pragma mark BOXFilePreviewControllerDelegate

- (NSArray *)boxFilePreviewController:(BOXFilePreviewController *)controller willChangeToRightBarButtonItems:(NSArray *)items
{
    // We are updating the navigation bar button for the BOXFilePreviewController
    UIBarButtonItem *barButton=[[UIBarButtonItem alloc]init];
    barButton.title=@"Metadata";
    [barButton setTarget:self];
    [barButton setAction:@selector(showMetadata:)];
    
    NSMutableArray *barButtonsUpdate = [items mutableCopy];
    barButtonsUpdate[0] = barButton;
    items = [NSArray arrayWithArray:barButtonsUpdate];
    
    return items;
}

#pragma mark Bar Button Functions

- (IBAction)showMetadata:(id)sender
{
    BOXMetadataRequest *mdreq = [_boxClient metadataAllInfoRequestWithFileID:self.selectedItemId];
    [mdreq performRequestWithCompletion:^(NSArray *metadata, NSError *error){
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            BOXMetadata *md = metadata[0];
            UIViewController *alert = [HelperClass showAlertWithTitle:[NSString stringWithFormat:@"File ID: %@", self.selectedItemId] andMessage:[NSString stringWithFormat:@"Metadata: %@", md.info[@"tags"]]];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        }
    }];
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
