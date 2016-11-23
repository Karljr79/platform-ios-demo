//
//  FileDetailViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/20/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "FileDetailViewController.h"
#import <BoxContentSDK/BoxContentSDK.h>

@interface FileDetailViewController () <BOXAPIAccessTokenDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textMetadata;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation FileDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    BOXContentClient *client = [BOXContentClient clientForNewSession];
    [client setAccessTokenDelegate:self];
    
    BOXFileRequest *request = [client fileInfoRequestWithID:self.fileId];
    [request performRequestWithCompletion:^(BOXFile *file, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            self.textFileName.text = file.name;
        }
    }];
    
    BOXMetadataRequest *mdreq = [client metadataAllInfoRequestWithFileID:self.fileId];
    [mdreq performRequestWithCompletion:^(NSArray *metadata, NSError *error){
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            BOXMetadata *item = metadata[0];
            self.textMetadata.text = item.info[@"tags"];
        }
    }];
    
//    NSOutputStream *outputStream = [[NSOutputStream alloc] initToMemory];
//    
//    BOXFileDownloadRequest *dreq = [client fileDownloadRequestWithID:self.fileId toOutputStream:outputStream];
//    [dreq performRequestWithProgress:^(long long totalBytesTransferred, long long totalBytesExpectedToTransfer) {
//        // Update a progress bar, etc.
//        NSLog(@"progress %lld",totalBytesTransferred);
//    } completion:^(NSError *error) {
//        // Download has completed. If it failed, error will contain reason (e.g. network connection)
//        if (error) {
//            NSLog(@"error %@",[error description]);
//            //[[NSNotificationCenter defaultCenter] postNotificationName:@"customUpdateBG" object:nil];
//        } else {
//            NSData *data = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
//            UIImage *img = [UIImage imageWithData:data];
//            
//            self.imageView.image = img;
//        }
//    }];
}

#pragma mark - BOXAPIAccessTokenDelegate
//Delegate method override for changing the default authentication for the Box iOS SDK
//I am using NSUserDefaults, which would not be the way to handle this in a production scenario
- (void)fetchAccessTokenWithCompletion:(void (^)(NSString *, NSDate *, NSError *))completion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    completion([defaults objectForKey:@"access_token"], [NSDate dateWithTimeIntervalSinceNow:100], nil);
}

@end
