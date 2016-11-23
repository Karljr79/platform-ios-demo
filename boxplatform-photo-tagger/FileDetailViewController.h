//
//  FileDetailViewController.h
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/20/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileDetailViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *textFileName;
@property (strong, nonatomic) NSString *fileId;

@end
