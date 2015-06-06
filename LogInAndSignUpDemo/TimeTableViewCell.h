//
//  TimeTableViewCell.h
//  LogInAndSignUpDemo
//
//  Created by alex on 06/06/15.
//
//

#import <UIKit/UIKit.h>

@interface TimeTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *time;
@property (strong, nonatomic) IBOutlet UILabel *eventText;
@property (strong, nonatomic) PFObject *event;

@end
