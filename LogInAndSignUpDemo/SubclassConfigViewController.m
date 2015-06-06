//
//  SubclassConfigViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "SubclassConfigViewController.h"
#import "MyLogInViewController.h"
#import "MySignUpViewController.h"
#import "TimeTableViewCell.h"


@implementation SubclassConfigViewController


#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

- (void)viewDidLoad {
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logOut)];
    self.navigationItem.leftBarButtonItem = logoutButton;
    
    self.calendar = [JTCalendar new];
    
    
    self.calendar.calendarAppearance.calendar.firstWeekday = 2; // Sunday == 1, Saturday == 7
//    self.calendar.calendarAppearance.dayCircleRatio = 9. / 10.;
    self.calendar.calendarAppearance.ratioContentMenu = 2.;
    self.calendar.calendarAppearance.focusSelectedDayChangeMode = YES;
    self.calendar.calendarAppearance.isWeekMode = YES;
    
    [self.calendar setMenuMonthsView:self.calendarMenuView];
    [self.calendar setContentView:self.calendarContentView];
    [self.calendar setDataSource:self];
    
    [self.calendar reloadData];
    
    NSDate *d = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                               fromDate:d];
    
    components.minute = 0;
    components.hour = 0;
    
    d = [calendar dateFromComponents:components];
    [self.calendar setCurrentDateSelected:d];
    
}

- (void)viewDidLayoutSubviews
{
    [self.calendar repositionViews];
}

- (BOOL)calendarHaveEvent:(JTCalendar *)calendar date:(NSDate *)date
{
    return NO;
}

- (void)calendarDidDateSelected:(JTCalendar *)calendar date:(NSDate *)date
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:8 inSection:0];
    [_tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
    PFQuery *q = [PFQuery queryWithClassName:@"CalendarEvent"];
    [q whereKey:@"source" equalTo:[PFUser currentUser][@"source"]];
    [q whereKey:@"date" equalTo:date];

    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {//4
        if (!error) {
            _tableData = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        } else {
            NSString *errorString = [[error userInfo] objectForKey:@"error"];
            NSLog(@"Error: %@", errorString);
        }
    }];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Check if user is logged in
    if (![PFUser currentUser]) {        
        // Customize the Log In View Controller
        MyLogInViewController *logInViewController = [[MyLogInViewController alloc] init];
        logInViewController.delegate = self;
        logInViewController.facebookPermissions = @[@"friends_about_me"];
        logInViewController.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsSignUpButton  | PFLogInFieldsLogInButton ;
        
        // Customize the Sign Up View Controller
        MySignUpViewController *signUpViewController = [[MySignUpViewController alloc] init];
        signUpViewController.delegate = self;
        signUpViewController.fields = PFSignUpFieldsDefault | PFSignUpFieldsAdditional;
        logInViewController.signUpController = signUpViewController;
        
        // Present Log In View Controller
        [self presentViewController:logInViewController animated:YES completion:NULL];
    }
    NSIndexPath *path = [NSIndexPath indexPathForRow:8 inSection:0];
    [_tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
    if ([PFUser currentUser]) {
        if (![PFUser currentUser][@"source"]) {
            PFQuery *q = [PFUser query];
            [q whereKey:@"additional" equalTo:[PFUser currentUser][@"additional"]];
            
            [q getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (object) {
                    if (object[@"source"]) {
                        [[PFUser currentUser]  setObject:object[@"source"] forKey:@"source"];
                        [[PFUser currentUser]  setObject:@(0) forKey:@"initial"];
                        [[PFUser currentUser]  saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            [self loadTable];
                        }];
                    }
                    [[PFUser currentUser] setObject:[PFUser currentUser] forKey:@"source"];
                    [[PFUser currentUser]  setObject:@(1) forKey:@"initial"];
                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [self loadTable];
                    }];
                }
            }];
        }
        else {
            [self loadTable];
        }
    }
}

- (void) loadTable {
    
    PFQuery *q = [PFQuery queryWithClassName:@"CalendarEvent"];
    [q whereKey:@"source" equalTo:[PFUser currentUser][@"source"]];
    [q whereKey:@"date" equalTo:_calendar.currentDateSelected];
    
    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {//4
        if (!error) {
            _tableData = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        } else {
            NSString *errorString = [[error userInfo] objectForKey:@"error"];
            NSLog(@"Error: %@", errorString);
        }
    }];
}

#pragma mark - PFLogInViewControllerDelegate

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    if (username && password && username.length && password.length) {
        return YES;
    }
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    return NO;
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    NSLog(@"User dismissed the logInViewController");
}


#pragma mark - PFSignUpViewControllerDelegate

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) {
            informationComplete = NO;
            break;
        }
    }
    
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}

- (void)logOut {
    [PFUser logOut];
    MyLogInViewController *logInViewController = [[MyLogInViewController alloc] init];
    logInViewController.delegate = self;
    logInViewController.facebookPermissions = @[@"friends_about_me"];
    logInViewController.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsSignUpButton  | PFLogInFieldsLogInButton;
    
    // Customize the Sign Up View Controller
    MySignUpViewController *signUpViewController = [[MySignUpViewController alloc] init];
    signUpViewController.delegate = self;
    signUpViewController.fields = PFSignUpFieldsDefault | PFSignUpFieldsAdditional;
    logInViewController.signUpController = signUpViewController;
    
    // Present Log In View Controller
    [self presentViewController:logInViewController animated:YES completion:NULL];
}

#pragma mark - ()

- (IBAction)logOutButtonTapAction:(id)sender {
    [PFUser logOut];
    [self.navigationController popViewControllerAnimated:YES];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TimeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"id"];
    
    if (!cell) {
        [tableView registerNib:[UINib nibWithNibName:@"TimeTableViewCell" bundle:nil] forCellReuseIdentifier:@"id"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"id"];
    }
    cell.time.text = [NSString stringWithFormat:@"%d:00",indexPath.row];
    BOOL noEvent = YES;
    
    
    for (NSDictionary *event in _tableData) {
        if ([event[@"time"] intValue] == indexPath.row) {
            switch ([event[@"confirmed"] intValue]) {
                case 0:
                    cell.eventText.text = @"avaliable";
                    cell.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.2];
                    noEvent = NO;
                    break;
                case 1:
                    cell.eventText.text = [NSString stringWithFormat:@"pending approval from %@",event[@"clientId"]];
                    cell.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
                    noEvent = NO;
                    break;
                case 2:
                    cell.eventText.text = [NSString stringWithFormat:@"appontment with: %@",event[@"clientId"]];
                    cell.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.2];
                    noEvent = NO;
                    break;
                    
                default:
                    break;
            }
        }
    }
    if (noEvent) {
        cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        cell.eventText.text = @"no event";
    }
    

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL noEvent = YES;
    
    for (NSDictionary *event in _tableData) {
        if ([event[@"time"] intValue] == indexPath.row) {
            noEvent = NO;
            switch ([event[@"confirmed"] intValue]) {
                case 0:
                    if (!([[PFUser currentUser][@"initial"] boolValue])) {
                        PFQuery *query = [PFQuery queryWithClassName:@"CalendarEvent"];
                        [query whereKey:@"ident" equalTo:event[@"ident"]];
                        
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                            if (!object) {
                                NSLog(@"The getFirstObject request failed.");
                            } else {
                                
                                [object setObject:@(1) forKey:@"confirmed"];
                                [object setObject:[PFUser currentUser] forKey:@"clientId"];
                                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                    [self loadTable];
                                }];
                            }
                        }];
                    }
                    break;
                case 1:
                    if ([[PFUser currentUser][@"initial"] boolValue]) {
                        PFQuery *query = [PFQuery queryWithClassName:@"CalendarEvent"];
                        [query whereKey:@"ident" equalTo:event[@"ident"]];
                        
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                            if (!object) {
                                NSLog(@"The getFirstObject request failed.");
                            } else {
                                [object setObject:@(2) forKey:@"confirmed"];
                                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                    [self loadTable];
                                }];
                            }
                        }];

                    }
                    break;
                    
                default:
                    break;
            }
        }
    }
    if ( noEvent && [[PFUser currentUser][@"initial"] boolValue]) {
        PFObject *obj = [[PFObject alloc] initWithClassName:@"CalendarEvent"];
        [obj setObject:[NSString stringWithFormat:@"%@",[NSUUID UUID]] forKey:@"ident"];
        [obj setObject:[PFUser currentUser] forKey:@"source"];
        [obj setObject:_calendar.currentDateSelected forKey:@"date"];
        [obj setObject:@(indexPath.row) forKey:@"time"];
        [obj setObject:@(0) forKey:@"confirmed"];
        
        [obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self loadTable];
        }];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 24;
}

@end
