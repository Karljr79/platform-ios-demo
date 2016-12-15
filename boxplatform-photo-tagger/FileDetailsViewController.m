//
//  FileDetailsViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 12/14/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "FileDetailsViewController.h"

@interface FileDetailsViewController ()
@property (strong, nonatomic) IBOutlet UILabel *labelFileName;
@property (strong, nonatomic) IBOutlet UILabel *labelGpsLat;
@property (strong, nonatomic) IBOutlet UILabel *labelGpsLong;
@property (strong, nonatomic) IBOutlet UITextView *textMetadata;
@property (strong, nonatomic) IBOutlet UITextView *textAddress;
@property (strong, nonatomic) IBOutlet UIImageView *imageFile;

@end

@implementation FileDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
