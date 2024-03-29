//
//  FirstViewController.h
//  run
//
//  Created by Griffin Kelly on 5/3/14.
//  Copyright (c) 2014 Griffin Kelly. All rights reserved.
//


#import <UIKit/UIKit.h>
@class TRACDoc;

@interface FirstViewController :UIViewController <UITableViewDelegate,UITableViewDataSource>
{
    TRACDoc *_tracDoc;
}

@property (strong, nonatomic) NSMutableArray *first_seen;
@property (strong, nonatomic) NSMutableArray *last_seen;
@property (strong, nonatomic) NSMutableArray *has_split;
@property (strong, nonatomic) NSMutableArray *runners;
@property (strong, nonatomic) NSMutableArray *runnerID;
@property (strong, nonatomic) NSMutableArray *lasttimearray;
@property (strong, nonatomic) NSMutableArray *summationTimeArray;
@property (strong, nonatomic) NSMutableArray *interval;
@property (strong, nonatomic) NSMutableArray *selectedRunners;
@property (strong, nonatomic) NSMutableArray *selectedRunnersUTC;
@property (strong, nonatomic) NSMutableArray *selectedRunnersToast;
@property (strong, nonatomic) NSMutableArray *resetValueArray;
@property (strong, nonatomic) NSMutableArray *athleteIDArray;
@property (strong, nonatomic) NSMutableArray *utcTimeArray;

@property (retain) TRACDoc *tracDoc;
@property (strong, nonatomic) NSString *storeDelete;
@property (strong, nonatomic) NSMutableArray *athleteDictionaryArray;
//@property (strong, nonatomic) NSArray *name;
@property (weak, nonatomic) IBOutlet UITableView *tableData;
@property (weak, nonatomic)  IBOutlet UILabel* humanReadble;
@property (weak, nonatomic) IBOutlet UILabel* jsonSummary;
@property (nonatomic, strong) NSString *urlID;
@property (nonatomic, strong) NSString *urlName;
@property (nonatomic, strong) NSString *workoutName;
@property (nonatomic, strong) NSString *workoutDate;
@property (nonatomic, strong) NSTimer *timer;





   // IBOutlet UITableView* groupTable;

@end
