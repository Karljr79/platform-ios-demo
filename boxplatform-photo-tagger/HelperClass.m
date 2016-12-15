//
//  HelperClass.m
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/22/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import "HelperClass.h"
#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

@implementation HelperClass

+(UIViewController*)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle your yes please button action here
                                   //TODO send user back to main view
                               }];
    [alert addAction:okButton];
    
    return alert;
}

+(NSString*)getBoxAccessToken:(NSString*)auth0Token
{
    //grab contents of config.plist
    NSURL *file = [[NSBundle mainBundle] URLForResource:@"config" withExtension:@"plist"];
    NSDictionary *plistContent = [NSDictionary dictionaryWithContentsOfURL:file];
    NSURL *URL = [NSURL URLWithString:[plistContent objectForKey:@"webtaskUrl"]];
    __block NSString *str = @"";
    
    //set authorzation header
    NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", auth0Token];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:authHeader forHTTPHeaderField:@"Authorization"];
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        str = [responseObject valueForKey:@"access_token"];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error getting Box Access Token: %@", error);
    }];
    return str;
}

//Helper Method to get the default UI color
+(UIColor*)getDefaultColor {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"myColor"];
    UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    return color;
}

//Helper Method to generate file names
+(NSString*)getFileNameWithBaseName:(NSString*)baseName andExtension:(NSString*)extension {
    //add a timestamp to the file name to avoid duplicate file names
    NSString *prefixString = baseName;
    time_t unixTime = (time_t) [[NSDate date] timeIntervalSince1970];
    NSString *timestamp = [NSString stringWithFormat:@"%ld", unixTime];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.%@", prefixString, timestamp, extension];
    return fileName;
}

@end

