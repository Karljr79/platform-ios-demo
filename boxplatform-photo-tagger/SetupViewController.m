//
//  SetupViewController.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 11/23/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "SetupViewController.h"
#import "InitialViewController.h"
#import <iOS-Color-Picker/FCColorPickerViewController.h>

@interface SetupViewController () <FCColorPickerViewControllerDelegate>
@property (nonatomic, copy) UIColor *color;

@end

@implementation SetupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_color];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:colorData forKey:@"myColor"];
    [defaults synchronize];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"showInitial"]) {
        InitialViewController *destViewController = segue.destinationViewController;
        destViewController.barColor = _color;
    }
}


@end
