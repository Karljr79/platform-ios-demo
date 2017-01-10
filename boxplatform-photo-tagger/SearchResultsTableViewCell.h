//
//  SearchResultsTableViewCell.h
//  boxplatform-photo-tagger
//
//  Created by Karl Hirschhorn on 7/18/16.
//  Copyright © 2016 Karl Hirschhorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchResultsTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelFileName;
@property (weak, nonatomic) IBOutlet UILabel *labelCreatedDate;
@property (weak, nonatomic) IBOutlet UIImageView *imageThumbnail;
@end
