//
//  HelperClass.h
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/22/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HelperClass : NSObject

+(UIViewController*)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message;
+(NSString*)getBoxAccessToken:(NSString*)auth0Token;

@end
