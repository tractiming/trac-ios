//
//  FirstViewController.m
//  run
//
//  Created by Griffin Kelly on 5/3/14.
//  Copyright (c) 2014 Griffin Kelly. All rights reserved.
//
//NSString *url=@"http://localhost:8888/api/sessions/3.json";

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
//#define kLatestKivaLoansURL [NSURL URLWithString:self.urlName] //2
//http://76.12.155.219/trac/json/test.json

#import "FirstViewController.h"
#import "SecondViewController.h"
#import "ThirdViewController.h"
#import "CustomCell.h"
#import "CustomCelliPad.h"
#import "UIView+Toast.h"
#import "TRACDatabase.h"
#import "TRACDoc.h"
#import "Data.h"
#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad
#define UITableViewCellEditingStyleMultiSelect (3)
#import "SSSnackbar.h"
#import "TokenVerification.h"
#import "TrueTime.h"
#import "StopWatchControl.h"

@interface FirstViewController() <UIActionSheetDelegate, CustomCellDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, assign) CFTimeInterval ticks;
@property (nonatomic, getter=isPseudoEditing) BOOL pseudoEdit;

@end



@implementation FirstViewController
{
    
    NSArray *name;
    UIActivityIndicatorView *spinner;
    NSTimer *timer;
    UIToolbar *actionToolbar;
    NSString* elapsedtime;
    NSString *newStartRunningTime;
    NSString *newLastRunningTime;
    BOOL Executed;
    NSUInteger universalIndex;
    NSArray *superlasttime;
    UIBarButtonItem *splitButton;
    UIBarButtonItem *resetButton;
    NSMutableString *countedTime;
    UILabel *toastText;
    UILabel *toastText2;
    UIView *customView;
    //double CurrentTime;
    double tempTime;
    double tempTime2;
    double tempTimeMax;
    NSIndexPath *runningClockIndexPath;
    NSMutableArray *firstSeenTimeArray;
    NSMutableArray *lastSeenTimeArray;
    
}
@synthesize tracDoc = _tracDoc;

- (IBAction)editAction:(id)sender
{
    self.pseudoEdit = YES;
    [self.tableData setEditing:YES animated:YES];
    [self updateButtonsToMatchTableState];
    [self showActionToolbar:YES];
    [self.tableData setAllowsSelection:YES];
    
}

- (IBAction)cancelAction:(id)sender
{
    self.pseudoEdit = NO;
    [self.tableData setEditing:NO animated:YES];
    [self updateButtonsToMatchTableState];
    [self showActionToolbar:NO];
    [self.tableData setAllowsSelection:NO];
}

- (void)updateSplitButtonTitle
{
    // Update the delete button's title, based on how many items are selected
    NSArray *selectedRows = [self.tableData indexPathsForSelectedRows];
    
    BOOL allItemsAreSelected = selectedRows.count == self.athleteDictionaryArray.count;
    BOOL noItemsAreSelected = selectedRows.count == 0;
    
    if (allItemsAreSelected || noItemsAreSelected)
    {
        splitButton.title = NSLocalizedString(@"Split All", @"");
        resetButton.title = NSLocalizedString(@"Reset All", @"");
    }
    else
    {
        NSString *titleFormatString =
        NSLocalizedString(@"Split (%d)", @"Title for delete button with placeholder for number");
        splitButton.title = [NSString stringWithFormat:titleFormatString, selectedRows.count];
        NSString *titleFormatString2 =
        NSLocalizedString(@"Reset (%d)", @"Title for delete button with placeholder for number");
        resetButton.title = [NSString stringWithFormat:titleFormatString2, selectedRows.count];
    }
}
- (void)updateButtonsToMatchTableState
{
    if (self.tableData.editing)
    {
        // Show the option to cancel the edit.
        self.parentViewController.navigationItem.rightBarButtonItem = self.cancelButton;
        
        [self updateSplitButtonTitle];
       
    }
    else
    {
        // Show the edit button, but disable the edit button if there's nothing to edit.
        if (self.runners.count > 0)
        {
            self.editButton.enabled = YES;
        }
        else
        {
            self.editButton.enabled = YES;
        }
        self.parentViewController.navigationItem.rightBarButtonItem = self.editButton;
    }
}

- (void)splitAction:(id)sender
{
    // Delete what the user selected.
    NSArray *selectedRows = [self.tableData indexPathsForSelectedRows];
    //NSLog(@"Selected Rows, %@",selectedRows);
    BOOL splitSpecificRows = selectedRows.count > 0;
    
    //Get current time in UTC
    NSDate *currentDate = [[NSDate alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
    [dateFormatter setTimeZone:timeZone];
    NSString *localDateString = [dateFormatter stringFromDate:currentDate];
    NSMutableArray * s = [NSMutableArray new];
    if (splitSpecificRows)
    {
        // Build an NSIndexSet of all the objects to delete, so they can all be removed at once.
        
        for (NSIndexPath *selectionIndex in selectedRows)
        {
            
            NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:selectionIndex.row];
            NSUInteger indexOfTheObject = [self.selectedRunners indexOfObject:[tempDict valueForKey:@"athleteID"]];
            NSDictionary *tempCreatedDict = @{@"athlete":[tempDict valueForKey:@"athleteID"],@"sessions":@[self.urlID],@"tag":[NSNull null],@"reader":[NSNull null],@"time":[self.selectedRunnersUTC objectAtIndex:indexOfTheObject]};
            [s addObject:tempCreatedDict];
           
            NSLog(@"Value of S: %@",s);
            
            //For the toast to keep time
            NSLog(@"%@, %@", [tempDict valueForKey:@"countStart"], [tempDict valueForKey:@"numberSplits"]);
            double tempHolder =[[tempDict valueForKey:@"numberSplits"] doubleValue];
            //Remove last seen split and add new one in.
            [tempDict removeObjectForKey:@"last_seen"];
            [tempDict setObject:[self.selectedRunnersToast objectAtIndex:indexOfTheObject] forKey:@"last_seen"];
            
            if ([[tempDict valueForKey:@"lastSplit"] isEqualToString:@"DNS"]){
                NSLog(@"Entered DNS?");
                [tempDict removeObjectForKey:@"dateTime"];
                [tempDict setObject:[self.selectedRunnersToast objectAtIndex:indexOfTheObject] forKey:@"dateTime"];
            }
            else if ([[tempDict valueForKey:@"countStart"] doubleValue] == 0) {
                //Do Nothing
            }
            else if ([[tempDict valueForKey:@"countStart"] doubleValue] == tempHolder){
                [tempDict removeObjectForKey:@"dateTime"];
                [tempDict setObject:[self.selectedRunnersToast objectAtIndex:indexOfTheObject] forKey:@"dateTime"];
                NSLog(@"Executed");
            }
            NSLog(@"Selection Index %ld, %ld", (long)selectionIndex.row, (long)runningClockIndexPath.row);
            if (selectionIndex.row == runningClockIndexPath.row){
                NSLog(@"It entered?");
                tempTime = [[tempDict valueForKey:@"dateTime"] doubleValue];
                tempTime2 = [[tempDict valueForKey:@"last_seen"] doubleValue];
            }
            
            
        }
        
    }
    else
    {
        //For Split ALL
        NSArray *selectedRows = [self.tableData indexPathsForVisibleRows];
        for (NSIndexPath *selectionIndex in selectedRows)
        {
            NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:selectionIndex.row];
            NSDictionary *tempCreatedDict = @{@"athlete":[tempDict valueForKey:@"athleteID"],@"sessions":@[self.urlID],@"tag":[NSNull null],@"reader":[NSNull null],@"time":localDateString};
            [s addObject:tempCreatedDict];
            
            NSLog(@"Value of S: %@",s);
            
            //For the toast to keep time
            NSLog(@"%@, %@", [tempDict valueForKey:@"countStart"], [tempDict valueForKey:@"numberSplits"]);
            double tempHolder =[[tempDict valueForKey:@"numberSplits"] doubleValue];
            //For split time, reset and reassign
            [tempDict removeObjectForKey:@"dateTime"];
            [tempDict setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970 ]*1000] forKey:@"dateTime"];
            
            if ([[tempDict valueForKey:@"lastSplit"] isEqualToString:@"DNS"]){
                NSLog(@"Entered DNS?");
                [tempDict removeObjectForKey:@"dateTime"];
                [tempDict setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970 ]*1000] forKey:@"dateTime"];
            }
            else if ([[tempDict valueForKey:@"countStart"] doubleValue] == 0) {
                //Do Nothing
            }
            else if ([[tempDict valueForKey:@"countStart"] doubleValue] == tempHolder){
                [tempDict removeObjectForKey:@"dateTime"];
                [tempDict setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970 ]*1000] forKey:@"dateTime"];
                NSLog(@"Executed");
            }
        }        // Delete everything, delete the objects from our data model.
        //Take every row and put into json. Then Send it
    }
    //Put the reload here to premptively reload, becaues if its filtered, it will crash
    [self.tableData reloadRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationNone];
    [self highlightUpdatedSplits:selectedRows];
    [self updateButtonsToMatchTableState];
    
    //Clear the selection arrays
    [self.selectedRunnersUTC removeAllObjects];
    [self.selectedRunners removeAllObjects];
    [self.selectedRunnersToast removeAllObjects];
    // Exit editing mode after the deletion.
    //async task now.
    
    
    
    NSInteger success = 0;
    
    @try {
        
        NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"token"];
        NSString *idurl2 = [NSString stringWithFormat: @"https://trac-us.appspot.com/api/splits/?access_token=%@",savedToken];
        
        NSURL *url=[NSURL URLWithString:idurl2];
        NSError *error2 = nil;
        
        //NSData *jsonData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:s options:0 error:&error2];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[jsonData length]];
        //NSMutableData *data = [NSMutableData data];
        //[data appendData:[sendThis dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:url];
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:jsonData];
        NSLog(@"JSON Data Format: %@",jsonString);
        
        
        NSError *error = [[NSError alloc] init];
        NSHTTPURLResponse *response = nil;
        NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSLog(@"%ld",(long)[response statusCode]);
        if ([response statusCode] >= 200 && [response statusCode] < 300)
        {
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
            NSLog(@"Response ==> %@", responseData);
            
            NSError *error = nil;
            NSDictionary *jsonData = [NSJSONSerialization
                                      JSONObjectWithData:urlData
                                      options:NSJSONReadingMutableContainers
                                      error:&error];
            
            //success = [jsonData[@"success"] integerValue];
            //NSLog(@"Success: %ld",(long)success);
            
            
        } else {
            //if (error) NSLog(@"Error: %@", error);
            //NSLog(@"Failed");
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
            NSLog(@"Response ==> %@", responseData);
        }
        
    }
    @catch (NSException * e) {
        // NSLog(@"Exception: %@", e);
        
    }
    

    //[self showActionToolbar:NO];
    //[self.tableData setEditing:NO animated:YES];
    //[self updateButtonsToMatchTableState];
    //NSLog(@"Hits Again?");
    [self sendRequest];

    
}


- (void)highlightUpdatedSplits:(NSArray *)indexPaths {
    for (NSIndexPath *indexPath in indexPaths) {
        CustomCell* cell = [self.tableData cellForRowAtIndexPath:indexPath];
        [self fadeCellTextColor:cell toColor:[UIColor colorWithRed:0.82 green:0.94 blue:0.75 alpha:1.0]];
    }
}

- (void)fadeCellTextColor:(CustomCell *)cell toColor:(UIColor *)color {
    UIColor *originalColor = cell.backgroundcell.backgroundColor;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         cell.backgroundcell.backgroundColor = color;
                         cell.backgroundColor = color;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.5
                                               delay:0.3
                                             options:UIViewAnimationOptionTransitionCrossDissolve
                                          animations:^{
                                              cell.backgroundcell.backgroundColor = originalColor;
                                              cell.backgroundColor = originalColor;
                                          }
                                          completion:NULL];
                     }];
    
//    [UIView animateWithDuration:0.5
//                          delay:0.0
//                        options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionTransitionCrossDissolve
//                     animations:^{
//                         cell.backgroundColor = color;
//                     }
//                     completion:NULL];
    
}

- (void)resetAction:(id)sender{
    //[self splitAction:nil];
    // Delete what the user selected.
    NSArray *selectedRows = [self.tableData indexPathsForSelectedRows];
    //NSLog(@"Selected Rows, %@",selectedRows);
    BOOL resetSpecificRows = selectedRows.count > 0;
    //reset counter index and on click of reset button refresh rows to start at 0.
    NSNumber *minutes = @(0);
    NSNumber *seconds = @(0);
    elapsedtime = [NSString stringWithFormat:@"%@:0%@",minutes,seconds];
    
    
    if (resetSpecificRows)
    {
        // Build an NSIndexSet of all the objects to delete, so they can all be removed at once.
        
        for (NSIndexPath *selectionIndex in selectedRows)
        {
            NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:selectionIndex.row];
            [tempDict removeObjectForKey:@"countStart"];
            [tempDict setObject:[tempDict valueForKey:@"numberSplits"] forKey:@"countStart"];
            //NSLog(@"Updated Reset");
            [tempDict removeObjectForKey:@"totalTime"];
            [tempDict setObject:elapsedtime forKey:@"totalTime"];
            [tempDict removeObjectForKey:@"dateTime"];
            [tempDict setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970 ]*1000] forKey:@"dateTime"];
            NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:selectionIndex.row inSection:0];
            NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
            [self.tableData reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
            [self updateButtonsToMatchTableState];
        }

    }
    else
    {
        NSArray *selectedRows = [self.tableData indexPathsForVisibleRows];
        for (NSIndexPath *selectionIndex in selectedRows)
        {
            NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:selectionIndex.row];
            [tempDict removeObjectForKey:@"countStart"];
            [tempDict setObject:[tempDict valueForKey:@"numberSplits"] forKey:@"countStart"];
            //NSLog(@"Updated Reset");
            [tempDict removeObjectForKey:@"totalTime"];
            [tempDict setObject:elapsedtime forKey:@"totalTime"];
            [tempDict removeObjectForKey:@"dateTime"];
            [tempDict setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970 ]*1000] forKey:@"dateTime"];
            NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:selectionIndex.row inSection:0];
            NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
            [self.tableData reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
            [self updateButtonsToMatchTableState];
            
        }
       
    }

    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.resetValueArray removeAllObjects];
    [self.athleteIDArray removeAllObjects];
    [self.utcTimeArray removeAllObjects];
    NSLog(@"Trying to save");
    for (NSMutableDictionary *tempDict in self.athleteDictionaryArray) {
        NSLog(@"Something is null %@, %@, %@",[tempDict valueForKey:@"countStart"], [tempDict valueForKey:@"athleteID"], [tempDict valueForKey:@"dateTime"]);

        [self.resetValueArray addObject:[tempDict valueForKey:@"countStart"]];
        [self.athleteIDArray addObject: [tempDict valueForKey:@"athleteID"]];
        [self.utcTimeArray addObject:[tempDict valueForKey:@"dateTime"]];
    }
    NSLog(@"Data in here? %@, %@, %@",self.resetValueArray, self.athleteIDArray, self.utcTimeArray);
    
    TRACDoc *newDoc = [[TRACDoc alloc] initWithTitle:self.athleteIDArray toast:self.utcTimeArray reset:self.resetValueArray];
    [newDoc saveData:self.urlID];
    
    [timer invalidate];
    [actionToolbar removeFromSuperview];
    self.parentViewController.navigationItem.rightBarButtonItem = nil;

}
- (void)viewWillAppear:(BOOL)animated{
    //Initialize arrays, out load data and load into rows. Delete saved data
    
    self.selectedRunners = [[NSMutableArray alloc] init];
    self.selectedRunnersUTC = [[NSMutableArray alloc] init];
    self.selectedRunnersToast = [[NSMutableArray alloc] init];
    
    
    NSMutableArray *loadDocs = [TRACDatabase loadDocs:self.urlID];
//    for (TRACDoc* doc in loadDocs)
//    {
//        TRACDoc* datatoLoad = doc;
//        self.athleteIDArray = [[NSMutableArray alloc] initWithArray:datatoLoad.data.storedIDs];
//        self.utcTimeArray = [[NSMutableArray alloc] initWithArray:datatoLoad.data.storedToast];
//        self.resetValueArray = [[NSMutableArray alloc] initWithArray:datatoLoad.data.storedReset];
//        NSLog(@"Stored Array Values %@,%@,%@",datatoLoad.data.storedIDs,datatoLoad.data.storedToast,datatoLoad.data.storedReset);
//        
//    }
//    [TRACDatabase deletePath:self.urlID];
    
    if([loadDocs count]== 0 || loadDocs == nil){
        NSLog(@"Init Arrays as doc is null");
        self.resetValueArray = [[NSMutableArray alloc] init];
        self.athleteIDArray = [[NSMutableArray alloc] init];
        self.utcTimeArray = [[NSMutableArray alloc] init];
    }
    
    self.parentViewController.navigationItem.rightBarButtonItem = self.editButton;
    self.tableData.contentInset = UIEdgeInsetsMake(0,0,44,0);
//NSLog(@"Reappear");
    dispatch_async(kBgQueue, ^{
        
        NSData* data = [NSData dataWithContentsOfURL:
                        [NSURL URLWithString:self.urlName]];
        
        dispatch_async(dispatch_get_main_queue() ,^{
            
            [self fetchedData:data];
            [self.tableData reloadData];
            [spinner removeFromSuperview];
        });});

    
    // call timer on launch and call sendRequest every 5 seconds
    timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(sendRequest) userInfo:nil repeats:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //CurrentTime = [TrueTime uptime];

    BOOL redirect = [TokenVerification findToken];
    if (!redirect) {
        [self performSegueWithIdentifier:@"logout_exception" sender:self];
    }
    
    

    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //seconds
    [self.tableData addGestureRecognizer:lpgr];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"myNotification"
                                               object:nil];
    
    self.athleteDictionaryArray = [[NSMutableArray alloc] init];
    Executed = TRUE;
    self.tableData.allowsMultipleSelectionDuringEditing = YES;
    
    [self.editButton setTitle:@"Splits"];
    [self.cancelButton setTitle:@"Done"];
    self.navigationItem.rightBarButtonItem = self.editButton;
    
    [self.tabBarController.navigationItem setTitle:self.workoutName];
    //initilize spinner
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    float navigationBarHeight = [[self.navigationController navigationBar] frame].size.height;

    float tabBarHeight = [[[super tabBarController] tabBar] frame].size.height;
    spinner.center = CGPointMake(self.view.frame.size.width / 2.0, (self.view.frame.size.height  - navigationBarHeight - tabBarHeight) / 4.0);
    [spinner startAnimating];
    [self.view addSubview:spinner];
    
    //Async Task Called
    SecondViewController *svc = [self.tabBarController.viewControllers objectAtIndex:1];
    svc.urlName_VC2 = self.urlName;
    
    ThirdViewController *tvc = [self.tabBarController.viewControllers objectAtIndex:2];
    tvc.urlID = self.urlID;
    
    if (IDIOM ==IPAD) {
        actionToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 416, self.view.frame.size.width, 44)];
    }
    else{
        actionToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 416, 320, 44)];
    }
    splitButton =[[UIBarButtonItem alloc]initWithTitle:@"Split All" style:UIBarButtonItemStyleDone target:self action:@selector(splitAction:)];
    resetButton = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetAction:)];
    splitButton.width = [[UIScreen mainScreen] bounds].size.width/2;
    [actionToolbar setItems:@[splitButton,resetButton]];
    [self updateButtonsToMatchTableState];
    [self showActionToolbar:NO];
    
    [self.tableData setAllowsSelection:NO];
        
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
     CGPoint location = [gestureRecognizer locationInView:self.tableData];
    
    NSIndexPath *indexPath = [self.tableData indexPathForRowAtPoint:location];
    if (indexPath == nil) {
        //NSLog(@"long press on table view but not on a row");
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if([self.timer isValid])
        {
            NSLog(@"If Clock is running, invalidate it");
            [self.timer invalidate];
            self.timer = nil;
        }
        
        
        NSLog(@"long press on table view at row %ld", (long)indexPath.row);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(refreshTimeLabel:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
        });
        
        
        
        tempTime = [[[self.athleteDictionaryArray objectAtIndex:indexPath.row] valueForKey:@"dateTime"] doubleValue];
        tempTime2 = [[[self.athleteDictionaryArray objectAtIndex:indexPath.row] valueForKey:@"last_seen"] doubleValue];
        //store the index path to later do update if updated...
        runningClockIndexPath = indexPath;
        if (tempTime != 0){
            tempTimeMax = 99999999;
            }
        else{
            tempTimeMax = 99999999;
        }
        
        customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];
        [customView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)]; // autoresizing masks are respected on custom views
        toastText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
        toastText.adjustsFontSizeToFitWidth = true;
        toastText.textAlignment = NSTextAlignmentCenter;
        [toastText setTextColor:[UIColor whiteColor]];
        [toastText setCenter:customView.center];
        
        toastText2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
        toastText2.adjustsFontSizeToFitWidth = true;
        toastText2.textAlignment = NSTextAlignmentCenter;
        [toastText2 setTextColor:[UIColor whiteColor]];
        [toastText2 setCenter:customView.center];
        
        SSSnackbar *snackbar;
        snackbar = [self snackbarForQuickRunningItem:toastText snackbarForQuickRunningItemTwo:toastText2 atIndexPath:indexPath];
        [snackbar show];
       
    } else {
       // NSLog(@"gestureRecognizer.state = %ld", gestureRecognizer.state);
    }
    
    // More coming soon...
}

- (SSSnackbar *)snackbarForQuickRunningItem:(UILabel *)itemView snackbarForQuickRunningItemTwo:(UILabel *)itemViewTwo atIndexPath:(NSIndexPath *)indexPath {
    
    SSSnackbar *snackbar = [SSSnackbar snackbarWithMessage:itemView
                                        initWithSecondMessage: itemViewTwo
                                                actionText:@"Hide"
                                                  duration:99999999
                                               actionBlock:^(SSSnackbar *sender){[self.timer invalidate];
                                               }
                                            dismissalBlock:^(SSSnackbar *sender){[self.timer invalidate];
                                            }];
    return snackbar;
}


-(void)refreshTimeLabel:(id)sender
{
    //NSLog(@"Hit the time label");
    // Timers are not guaranteed to tick at the nominal rate specified, so this isn't technically accurate.
    // However, this is just an example to demonstrate how to stop some ongoing activity, so we can live with that inaccuracy.
    _ticks = 0.1;
    double time = 0;
    double time_split = 0;
    //time += _ticks;
    
    if (tempTime != 0)
    {
        //NSLog(@"Temp Time: %f, True Time: %f",tempTime,[[NSDate date] timeIntervalSince1970 ]*1000);
        time = [[NSDate date] timeIntervalSince1970 ]*1000 - tempTime;
        NSLog(@"Write Date Time %f , %f",tempTime, tempTime2);
        NSLog(@"Diff Arrays? %@, %@", lastSeenTimeArray, firstSeenTimeArray);
        
        time_split = [[NSDate date] timeIntervalSince1970 ]*1000 - tempTime2;
    }

        //NSLog(@"Time Current:  %f",time);
        double hours = trunc(time / 3600000.0);
        double remainder = fmod(time, 3600000.0);
        double minutes = trunc(remainder / 60000.0);
        remainder = fmod(remainder, 60000.0);
        double seconds = trunc(remainder/1000.0);
        double milli = fmod(time,1000.0)/100;
        toastText.text = [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f.%01.0f", hours, minutes, seconds,milli];
    
        double hours_split = trunc(time_split / 3600000.0);
        double remainder_split = fmod(time_split, 3600000.0);
        double minutes_split = trunc(remainder_split / 60000.0);
        remainder_split = fmod(remainder_split, 60000.0);
        double seconds_split = trunc(remainder_split/1000.0);
        double milli_split = fmod(time_split,1000.0)/100;
        toastText2.text = [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f.%01.0f", hours_split, minutes_split, seconds_split, milli_split];

}


- (void)receiveNotification:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"myNotification"]) {
        //NSLog(@"Hello its me : %@",notification.object);
        self.storeDelete = notification.object;
        //doSomething here.
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.view.superview addSubview:actionToolbar];
}

- (void)showActionToolbar:(BOOL)show
{
    //NSLog(@"Entered it again");
    CGRect toolbarFrame = actionToolbar.frame;
	CGRect tableViewFrame = self.tableData.frame;
    UITabBarController *tabBarController = [UITabBarController new];
    CGFloat tabBarHeight = tabBarController.tabBar.frame.size.height;
	if (show)
	{
		toolbarFrame.origin.y = actionToolbar.superview.frame.size.height - toolbarFrame.size.height-tabBarHeight;
		tableViewFrame.size.height -= toolbarFrame.size.height;
	}
	else
	{
		toolbarFrame.origin.y = actionToolbar.superview.frame.size.height-tabBarHeight;
		tableViewFrame.size.height += toolbarFrame.size.height;
	}
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
    //NSLog(@"Toolbar Frame, TableView Frame %f,%f",toolbarFrame.origin.y,tableViewFrame.size.height);
	actionToolbar.frame = toolbarFrame;
	self.tableData.frame = tableViewFrame;
	
	[UIView commitAnimations];
}

- (void) sendRequest
{
   // NSLog(@"Send Request Called");
    //Async Task Called
    dispatch_async(kBgQueue, ^{
        
        NSData* data = [NSData dataWithContentsOfURL:
                        [NSURL URLWithString:self.urlName]];
        
        dispatch_async(dispatch_get_main_queue() ,^{
            
            [self fetchedData:data];
            
            [spinner removeFromSuperview];
        });});

    SecondViewController *svc = [self.tabBarController.viewControllers objectAtIndex:1];
    svc.urlName_VC2 = self.urlName;
}

- (NSArray *)fetchedData:(NSData *)responseData {
    //NSLog(@"Fetched Data called? ");
    if (self.storeDelete)
    {
       // NSLog(@"Enters the if");
        Executed = TRUE;
        [self.athleteDictionaryArray removeAllObjects];
        [self.tableData reloadData];
        self.storeDelete = NULL;
    }
    //parse out the json data
    
    //NSLog(@"Enters Fetched Data Again");
   @try {
        NSError* error;
        NSDictionary* json= [NSJSONSerialization
                             JSONObjectWithData:responseData //1
                             
                             options:kNilOptions
                             error:&error];

        NSString* results = [json valueForKey:@"results"];

        self.runners= [results valueForKey:@"name"];
        self.runnerID = [results valueForKey:@"id"];
        self.interval = [results valueForKey:@"splits"];
        self.has_split = [results valueForKey:@"has_split"];
        self.first_seen = [results valueForKey:@"first_seen"];
        self.last_seen = [results valueForKey:@"last_seen"];
       
       if(Executed == TRUE){
           //Download the times for first seen.
           firstSeenTimeArray = [[NSMutableArray alloc] init];
           lastSeenTimeArray = [[NSMutableArray alloc] init];
           for (int jj=0; jj<[self.first_seen count]; jj++){
               
               if ([self.first_seen objectAtIndex:jj] == [NSNull null]){
                   
                   [firstSeenTimeArray addObject:[NSNumber numberWithDouble:0]];
                   [lastSeenTimeArray addObject:[NSNumber numberWithDouble:0]];
               }
               else{
                   //Math to convert str to usable timestamp for First Seen
                   NSString *split = [self.first_seen objectAtIndex:jj];
                   NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                   [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
                   NSDate *dateFromString = [[NSDate alloc] init];
                   NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                   [dateFormatter setTimeZone:timeZone];
                   dateFromString = [dateFormatter dateFromString:split];
                   NSLog(@"The Date From String is = %@",dateFromString);
                   NSTimeInterval timeInMiliseconds = [dateFromString timeIntervalSince1970]*1000;
                   
                   NSString *strTimeStamp = [NSString stringWithFormat:@"%f",timeInMiliseconds];
                   NSLog(@"The Date is = %@",split);
                   NSLog(@"The Timestamp is = %@",strTimeStamp);
                   [firstSeenTimeArray addObject:strTimeStamp];
                   
                   //Math for Last Seen
                   NSString *split2 = [self.last_seen objectAtIndex:jj];
                   NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
                   [dateFormatter2 setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
                   NSDate *dateFromString2 = [[NSDate alloc] init];
                   NSTimeZone *timeZone2 = [NSTimeZone timeZoneWithName:@"UTC"];
                   [dateFormatter2 setTimeZone:timeZone2];
                   dateFromString2 = [dateFormatter2 dateFromString:split2];
                   NSLog(@"The Date From String is = %@",dateFromString2);
                   NSTimeInterval timeInMiliseconds2 = [dateFromString2 timeIntervalSince1970]*1000;
                   
                   NSString *strTimeStamp2 = [NSString stringWithFormat:@"%f",timeInMiliseconds2];
                   NSLog(@"The Last Date is = %@",split2);
                   NSLog(@"The Last Timestamp is = %@",strTimeStamp2);
                   [lastSeenTimeArray addObject:strTimeStamp2];
                   
                   
               }
               
           }
       }

       self.summationTimeArray = [[NSMutableArray alloc] init];
       self.lasttimearray = [[NSMutableArray alloc] init];
       
        //Iterate through most recent JSON request
        NSUInteger index = 0;
       
        for (NSArray *personalinterval in self.interval) {
           
            if(Executed == TRUE){
                 NSLog(@"Looping again ");
                if(![[self.has_split objectAtIndex:index] boolValue]){
                    elapsedtime = [NSString stringWithFormat:@"DNS"];
                    superlasttime = [NSString stringWithFormat:@"DNS"];
                    universalIndex = NULL;
                }
                else if(!personalinterval || !personalinterval.count){
                    elapsedtime = [NSString stringWithFormat:@"NT"];
                    superlasttime = [NSString stringWithFormat:@"NT"];
                    universalIndex = 0;
                }
                else{
                   
                    //adds all intervals together to give cumulative time
                    NSArray *tempArray = [self.interval objectAtIndex:index];
                    
                    //adds all intervals together to give cumulative time
                    NSMutableArray *finaltimeArray=[[NSMutableArray alloc] init];
                    NSInteger rangeVar;
                    NSUInteger indexOfAthlete;
                    
                    if (self.utcTimeArray == nil || [self.utcTimeArray count] == 0)
                    {
                        //NSLog(@"Setting Zero");
                        rangeVar = [[NSNumber numberWithInt:0] integerValue];
                    }
                    else{
                        
                        //if runner index is in the array, find it
                        if ([self.athleteIDArray containsObject:[self.runnerID objectAtIndex:index]])
                        {
                            indexOfAthlete = [self.athleteIDArray indexOfObject:[self.runnerID objectAtIndex:index]];
                            rangeVar = [[self.resetValueArray objectAtIndex:indexOfAthlete] integerValue];
                        }
                        else
                            rangeVar = 0;
                        
                       
                    }
                    
                   
                    if(rangeVar == 0){
                        //do nothing because you want the 0 to be counted in the elapsed time.
                    }
                    else
                    {
                        //Dont count the rest period so skip 1.
                        rangeVar = rangeVar + 1;
                    }
                    NSArray *resetViewCount = [tempArray subarrayWithRange: NSMakeRange(rangeVar, [tempArray count]-rangeVar)];
                    NSLog(@"Reset View Count: %@",resetViewCount);
                    
                    for (NSArray *subinterval in resetViewCount){
                        NSArray* subs=[subinterval lastObject];
                        finaltimeArray =[finaltimeArray arrayByAddingObject:subs];
                        
                    }
                    universalIndex = [tempArray count];

                    
                    NSNumber *sum = [finaltimeArray valueForKeyPath:@"@sum.floatValue"];
                    
                    NSArray* lastsettime=[personalinterval lastObject];
                    NSNumber *lastsplit = [lastsettime valueForKeyPath:@"@sum.floatValue"];
                    NSNumber *sumInt =@([lastsplit integerValue]);
                    NSNumber *ninty = [NSNumber numberWithInt:90];
                    NSNumber*decimal =[NSNumber numberWithFloat:(([lastsplit floatValue]-[sumInt floatValue])*1000)];
                    NSNumber *decimalInt = @([decimal integerValue]);
                    
                    
                    //to do add decimal to string, round to 3 digits
                    NSNumber *lastsplitminutes = @([lastsplit integerValue] / 60);
                    NSNumber *lastsplitseconds = @([lastsplit integerValue] % 60);
                    NSMutableArray *lasttime = [[NSMutableArray alloc] init];
                    if ([lastsplit intValue]<[ninty intValue]){
                        //if less than 90 display in seconds
                        lasttime=[personalinterval lastObject];
                        //NSLog(@"Last Time %@",lasttime);
                    }
                    else{
                        //If greater than 90 seconds display in minute format
                        //If less than 10 format with additional 0
                        if ([lastsplitseconds intValue]<10) {
                            NSString* elapsedtime = [NSString stringWithFormat:@"%@:0%@.%@",lastsplitminutes,lastsplitseconds,decimalInt];
                            [lasttime addObject:elapsedtime];
                            //NSLog(@"Last Time %@",lasttime);
                            //self.personalSplits=[self.personalSplits arrayByAddingObject:elapsedtime];
                            
                        }
                        //If greater than 10 seconds, dont use the preceding 0
                        else{
                            NSString* elapsedtime = [NSString stringWithFormat:@"%@:%@.%@",lastsplitminutes,lastsplitseconds,decimalInt];
                            [lasttime addObject:elapsedtime];
                            //NSLog(@"Last Time %@",lasttime);
                        }
                    }
                    
                    
                    //NSArray* lasttime=[lastsettime lastObject];
                    superlasttime = [lasttime lastObject];
                    
                    NSNumber *minutes = @([sum integerValue] / 60);
                    NSNumber *seconds = @([sum integerValue] % 60);
                    
                    //format total time in minute second format
                    if ([seconds intValue]<10) {
                        elapsedtime = [NSString stringWithFormat:@"%@:0%@",minutes,seconds];
                        [self.summationTimeArray addObject:elapsedtime];
                        
                    }
                    else{
                        elapsedtime = [NSString stringWithFormat:@"%@:%@",minutes,seconds];
                        [self.summationTimeArray addObject:elapsedtime];
                        
                    }
                    
                    [self.lasttimearray addObject:superlasttime];
                    NSLog(@"Array, %@",self.lasttimearray);
                    
                    
                    
                }
                NSLog(@"Find Match");
                NSUInteger indexOfAthlete = [self.athleteIDArray indexOfObject:[self.runnerID objectAtIndex:index]];

                
                NSMutableDictionary *athleteDictionary = [NSMutableDictionary new];
                [athleteDictionary setObject:[self.runners objectAtIndex:index] forKey:@"name"];
                [athleteDictionary setObject:[self.runnerID objectAtIndex:index] forKey:@"athleteID"];
                [athleteDictionary setObject:superlasttime forKey:@"lastSplit"];
                
                
                if (self.utcTimeArray == nil || [self.utcTimeArray count] == 0)
                {
                    NSLog(@"Setting Zero");
                    [athleteDictionary setObject:[NSNumber numberWithInt:0] forKey:@"countStart"];
                    [athleteDictionary setObject:[firstSeenTimeArray objectAtIndex:index] forKey:@"dateTime"];
                    [athleteDictionary setObject:[lastSeenTimeArray objectAtIndex:index] forKey:@"last_seen"];
                }
                else{
                    NSLog(@"Varying Time");
                    if ([self.resetValueArray count] < indexOfAthlete) {
                        NSLog(@"Write Zero");
                        [athleteDictionary setObject:[NSNumber numberWithInt:0] forKey:@"countStart"];
                        [athleteDictionary setObject:[firstSeenTimeArray objectAtIndex:index] forKey:@"dateTime"];
                        [athleteDictionary setObject:[lastSeenTimeArray objectAtIndex:index] forKey:@"last_seen"];
                    }
                    else{
                        NSLog(@"Try to write value?");
                        
                        
                        //input the more recent value, either the firstseentime or a locally stored utc time
                        //prevent loading a zero out of storage
                        NSLog(@"%@, %@", [self.utcTimeArray objectAtIndex:indexOfAthlete], [firstSeenTimeArray objectAtIndex:index]);
                        if ([[self.utcTimeArray objectAtIndex:indexOfAthlete] integerValue] > [[firstSeenTimeArray objectAtIndex:index] integerValue] && [[firstSeenTimeArray objectAtIndex:index] integerValue] != 0) {
                            
                            [athleteDictionary setObject:[self.utcTimeArray objectAtIndex:indexOfAthlete] forKey:@"dateTime"];
                            [athleteDictionary setObject:[lastSeenTimeArray objectAtIndex:index] forKey:@"last_seen"];
                            [athleteDictionary setObject:[self.resetValueArray objectAtIndex:indexOfAthlete] forKey:@"countStart"];
                        }
                        else if ([[firstSeenTimeArray objectAtIndex:index] integerValue] == 0){
                            [athleteDictionary setObject:[NSNumber numberWithInt:0] forKey:@"countStart"];
                            [athleteDictionary setObject:[firstSeenTimeArray objectAtIndex:index] forKey:@"dateTime"];
                            [athleteDictionary setObject:[lastSeenTimeArray objectAtIndex:index] forKey:@"last_seen"];
                        }
                        else{
                            NSLog(@"read to firstseen, idex %lu, index of athlete %lu", index, indexOfAthlete);
                            [athleteDictionary setObject:[firstSeenTimeArray objectAtIndex:index] forKey:@"dateTime"];
                            [athleteDictionary setObject:[lastSeenTimeArray objectAtIndex:index] forKey:@"last_seen"];
                            [athleteDictionary setObject:[self.resetValueArray objectAtIndex:indexOfAthlete] forKey:@"countStart"];
                            NSLog(@"Gets here??");
                        }
                        
                    }
                   
                }
                NSLog(@"Helo?");
                
                [athleteDictionary setObject:[NSNumber numberWithInt:universalIndex] forKey:@"numberSplits"];
                NSLog(@"Helo? one more");
                [athleteDictionary setObject:elapsedtime forKey:@"totalTime"];
                NSLog(@"Helo? third ");
                [self.athleteDictionaryArray addObject:athleteDictionary];
                NSLog(@"Helo? fourth ");
            }
            
            else{
                NSLog(@"Helo2 ?");
                //Does the row exist from a previous polling. Check Athlete IDs versus stored dictionary.
                NSMutableArray *tempArray = [self.athleteDictionaryArray valueForKey:@"athleteID"];
                BOOL found = CFArrayContainsValue ( (__bridge CFArrayRef)tempArray, CFRangeMake(0, tempArray.count), (CFNumberRef) [self.runnerID objectAtIndex:index]);
                NSUInteger closestIndex = [tempArray indexOfObject:[self.runnerID objectAtIndex:index]];
                //NSLog(@"Index %lu", (unsigned long)closestIndex);
                //If the new index is in the dictionary, and if it hasnt loaded all the splits update them and reload.
                if (found){
                    //NSLog(@"Index Found:  %lu",(unsigned long)index);
                    if ([[self.has_split objectAtIndex:index] boolValue]) {
                       // NSLog(@"Last Split String: %@", [[self.athleteDictionaryArray objectAtIndex:closestIndex] valueForKey:@"lastSplit"]);
                        if ( [[[self.athleteDictionaryArray objectAtIndex:closestIndex] valueForKey:@"lastSplit"] isEqualToString:@"DNS"])
                        {
                            NSLog(@"Moved Into NT Area Index : %lu", (unsigned long)index);
                            elapsedtime = [NSString stringWithFormat:@"NT"];
                            superlasttime = [NSString stringWithFormat:@"NT"];
                            
                            universalIndex = 0;
                            
                            NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:closestIndex inSection:0];
                            NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
                            NSArray *tempArray= [self.interval objectAtIndex:index];
                            //update the dictionary here for that index
                            NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:closestIndex];
                            [tempDict removeObjectForKey:@"dateTime"];
                            [tempDict removeObjectForKey:@"last_seen"];
                            
                            
                            //Add in running clock time for when started
                            if ([self.first_seen objectAtIndex:index] == [NSNull null]){
                                
                                [tempDict setObject:[NSNumber numberWithDouble:0] forKey:@"dateTime"];
                                [tempDict setObject:[NSNumber numberWithDouble:0] forKey:@"last_seen"];
                            }
                            else{
                                newStartRunningTime =[self.first_seen objectAtIndex:index];
                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
                                NSDate *dateFromString = [[NSDate alloc] init];
                                NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                                [dateFormatter setTimeZone:timeZone];
                                dateFromString = [dateFormatter dateFromString:newStartRunningTime];
                                NSTimeInterval timeInMiliseconds = [dateFromString timeIntervalSince1970]*1000;
                                
                                NSString *strTimeStamp = [NSString stringWithFormat:@"%f",timeInMiliseconds];
                                [tempDict setObject:strTimeStamp forKey:@"dateTime"];
                                
                                newLastRunningTime =[self.last_seen objectAtIndex:index];
                                NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
                                [dateFormatter2 setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
                                NSDate *dateFromString2 = [[NSDate alloc] init];
                                NSTimeZone *timeZone2 = [NSTimeZone timeZoneWithName:@"UTC"];
                                [dateFormatter2 setTimeZone:timeZone2];
                                dateFromString2 = [dateFormatter2 dateFromString:newLastRunningTime];
                                NSTimeInterval timeInMiliseconds2 = [dateFromString2 timeIntervalSince1970]*1000;
                                
                                NSString *strTimeStamp2 = [NSString stringWithFormat:@"%f",timeInMiliseconds2];
                                [tempDict setObject:strTimeStamp2 forKey:@"last_seen"];
                            }

                            
                            [tempDict removeObjectForKey:@"lastSplit"];
                            [tempDict removeObjectForKey:@"numberSplits"];
                            [tempDict removeObjectForKey:@"totalTime"];
                            [tempDict setObject:superlasttime forKey:@"lastSplit"];
                            [tempDict setObject:[NSNumber numberWithInt:universalIndex] forKey:@"numberSplits"];
                            [tempDict setObject:elapsedtime forKey:@"totalTime"];
                            
                            NSLog(@"Running Clock %ld %lu",(long)runningClockIndexPath.row,(unsigned long)closestIndex);
                            if (runningClockIndexPath.row == closestIndex){
                                tempTime = [[tempDict valueForKey:@"dateTime"] doubleValue];
                                tempTime2 = [[tempDict valueForKey:@"last_seen"] doubleValue];
                                NSLog(@"Time %f", tempTime);
                            }
                            
                            [self.tableData reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
                        }
                        else if ((unsigned long)[personalinterval count] > (long)[[[self.athleteDictionaryArray objectAtIndex:closestIndex] valueForKey:@"numberSplits"] integerValue]) {
                            
                            NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:closestIndex inSection:0];
                            NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
                            NSArray *tempArray= [self.interval objectAtIndex:index];
                        
                        //adds all intervals together to give cumulative time
                        NSMutableArray *finaltimeArray=[[NSMutableArray alloc] init];
                        NSMutableDictionary *tempDictIndex = [self.athleteDictionaryArray objectAtIndex:closestIndex];
                        NSInteger rangeVar = [[tempDictIndex valueForKey:@"countStart"] integerValue];
                        if(rangeVar == 0){
                            //do nothing because you want the 0 to be counted in the elapsed time.
                        }
                        else
                        {
                            //Dont count the rest period so skip 1.
                            rangeVar = rangeVar + 1;
                        }
                        NSArray *resetViewCount = [tempArray subarrayWithRange: NSMakeRange(rangeVar, [tempArray count]-rangeVar)];
                            NSLog(@"Reset View Count: %@",resetViewCount);

                        for (NSArray *subinterval in resetViewCount){
                            NSArray* subs=[subinterval lastObject];
                            finaltimeArray =[finaltimeArray arrayByAddingObject:subs];
                            
                        }
                        universalIndex = [tempArray count];
                        
                        NSNumber *sum = [finaltimeArray valueForKeyPath:@"@sum.floatValue"];
                        
                        NSArray* lastsettime=[tempArray lastObject];
                        NSNumber *lastsplit = [lastsettime valueForKeyPath:@"@sum.floatValue"];
                        NSNumber *sumInt =@([lastsplit integerValue]);
                        NSNumber *ninty = [NSNumber numberWithInt:90];
                        NSNumber*decimal =[NSNumber numberWithFloat:(([lastsplit floatValue]-[sumInt floatValue])*1000)];
                        NSNumber *decimalInt = @([decimal integerValue]);
                        
                        
                        //to do add decimal to string, round to 3 digits
                        NSNumber *lastsplitminutes = @([lastsplit integerValue] / 60);
                        NSNumber *lastsplitseconds = @([lastsplit integerValue] % 60);
                        NSMutableArray *lasttime = [[NSMutableArray alloc] init];
                        if ([lastsplit intValue]<[ninty intValue]){
                            //if less than 90 display in seconds
                            lasttime=[tempArray lastObject];
                        }
                        else{
                            //If greater than 90 seconds display in minute format
                            //If less than 10 format with additional 0
                            if ([lastsplitseconds intValue]<10) {
                                NSString* elapsedtime = [NSString stringWithFormat:@"%@:0%@.%@",lastsplitminutes,lastsplitseconds,decimalInt];
                                [lasttime addObject:elapsedtime];
                                
                                //self.personalSplits=[self.personalSplits arrayByAddingObject:elapsedtime];
                                
                            }
                            //If greater than 10 seconds, dont use the preceding 0
                            else{
                                NSString* elapsedtime = [NSString stringWithFormat:@"%@:%@.%@",lastsplitminutes,lastsplitseconds,decimalInt];
                                [lasttime addObject:elapsedtime];
                               
                            }
                        }
                        
                        
                        //NSArray* lasttime=[lastsettime lastObject];
                        superlasttime = [lasttime lastObject];
                        
                        NSNumber *minutes = @([sum integerValue] / 60);
                        NSNumber *seconds = @([sum integerValue] % 60);
                        
                        //format total time in minute second format
                        if ([seconds intValue]<10) {
                            elapsedtime = [NSString stringWithFormat:@"%@:0%@",minutes,seconds];

                        }
                        else{
                            elapsedtime = [NSString stringWithFormat:@"%@:%@",minutes,seconds];

                        }
                        
                            
                        //Update latest split time
                        newLastRunningTime =[self.last_seen objectAtIndex:index];
                        NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
                        [dateFormatter2 setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
                        NSDate *dateFromString2 = [[NSDate alloc] init];
                        NSTimeZone *timeZone2 = [NSTimeZone timeZoneWithName:@"UTC"];
                        [dateFormatter2 setTimeZone:timeZone2];
                        dateFromString2 = [dateFormatter2 dateFromString:newLastRunningTime];
                        NSTimeInterval timeInMiliseconds2 = [dateFromString2 timeIntervalSince1970]*1000;
                        
                        NSString *strTimeStamp2 = [NSString stringWithFormat:@"%f",timeInMiliseconds2];
                        
                        
                        
                        //update the dictionary here for that index
                        NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:closestIndex];
                        [tempDict removeObjectForKey:@"lastSplit"];
                        [tempDict setObject:strTimeStamp2 forKey:@"last_seen"];
                        [tempDict removeObjectForKey:@"numberSplits"];
                        [tempDict removeObjectForKey:@"totalTime"];
                        [tempDict setObject:superlasttime forKey:@"lastSplit"];
                        [tempDict setObject:[NSNumber numberWithInt:universalIndex] forKey:@"numberSplits"];
                        [tempDict setObject:elapsedtime forKey:@"totalTime"];
                            
                        if (runningClockIndexPath.row == closestIndex){
                            tempTime = [[tempDict valueForKey:@"dateTime"] doubleValue];
                            tempTime2 = [[tempDict valueForKey:@"last_seen"] doubleValue];
                            NSLog(@"Time %f", tempTime);
                        }
                        
                        [self.tableData reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
                        }
                    }
                }
                //Otherwise load and append to bottom.
                else{
                    //NSLog(@"In Else Statement2 ");
                    NSIndexPath* rowToAdd = [NSIndexPath indexPathForRow:[tempArray count] inSection:0];
                    NSArray* rowsToAdd = [NSArray arrayWithObjects:rowToAdd, nil];
                    NSArray *tempArray= [self.interval objectAtIndex:index];
                    NSMutableDictionary *athleteDictionary = [NSMutableDictionary new];
                    //NSLog(@" Has Split: %@",[self.has_split objectAtIndex:index]);
                    if(![[self.has_split objectAtIndex:index] boolValue]){
                        elapsedtime = [NSString stringWithFormat:@"DNS"];
                        superlasttime = [NSString stringWithFormat:@"DNS"];
                        universalIndex = NULL;
                        
                    }
                    else if(!tempArray || !tempArray.count){
                        elapsedtime = [NSString stringWithFormat:@"NT"];
                        superlasttime = [NSString stringWithFormat:@"NT"];
                        universalIndex = 0;
                        //append to first seen
                        
                    }
                    else{
                        //adds all intervals together to give cumulative time
                        NSMutableArray *finaltimeArray=[[NSMutableArray alloc] init];
                        NSMutableDictionary *tempDictIndex = [self.athleteDictionaryArray objectAtIndex:closestIndex];
                        NSInteger rangeVar = [[tempDictIndex valueForKey:@"countStart"] integerValue]+1;
                        NSArray *resetViewCount = [tempArray subarrayWithRange: NSMakeRange(rangeVar, [tempArray count]-rangeVar)];
                        for (NSArray *subinterval in resetViewCount){
                            NSArray* subs=[subinterval lastObject];
                            finaltimeArray =[finaltimeArray arrayByAddingObject:subs];
                            
                        }
                        universalIndex = [tempArray count];
                        
                        NSNumber *sum = [finaltimeArray valueForKeyPath:@"@sum.floatValue"];
                        
                        NSArray* lastsettime=[tempArray lastObject];
                        NSNumber *lastsplit = [lastsettime valueForKeyPath:@"@sum.floatValue"];
                        NSNumber *sumInt =@([lastsplit integerValue]);
                        NSNumber *ninty = [NSNumber numberWithInt:90];
                        NSNumber*decimal =[NSNumber numberWithFloat:(([lastsplit floatValue]-[sumInt floatValue])*1000)];
                        NSNumber *decimalInt = @([decimal integerValue]);
                        
                        
                        //to do add decimal to string, round to 3 digits
                        NSNumber *lastsplitminutes = @([lastsplit integerValue] / 60);
                        NSNumber *lastsplitseconds = @([lastsplit integerValue] % 60);
                        NSMutableArray *lasttime = [[NSMutableArray alloc] init];
                        if ([lastsplit intValue]<[ninty intValue]){
                            //if less than 90 display in seconds
                            lasttime=[tempArray lastObject];
                            //NSLog(@"Last Time %@",lasttime);
                        }
                        else{
                            //If greater than 90 seconds display in minute format
                            //If less than 10 format with additional 0
                            if ([lastsplitseconds intValue]<10) {
                                NSString* elapsedtime = [NSString stringWithFormat:@"%@:0%@.%@",lastsplitminutes,lastsplitseconds,decimalInt];
                                [lasttime addObject:elapsedtime];
                               // NSLog(@"Last Time %@",lasttime);
                                //self.personalSplits=[self.personalSplits arrayByAddingObject:elapsedtime];
                                
                            }
                            //If greater than 10 seconds, dont use the preceding 0
                            else{
                                NSString* elapsedtime = [NSString stringWithFormat:@"%@:%@.%@",lastsplitminutes,lastsplitseconds,decimalInt];
                                [lasttime addObject:elapsedtime];
                               // NSLog(@"Last Time %@",lasttime);
                            }
                        }
                        
                        
                        //NSArray* lasttime=[lastsettime lastObject];
                        NSArray *superlasttime = [lasttime lastObject];
                        
                        NSNumber *minutes = @([sum integerValue] / 60);
                        NSNumber *seconds = @([sum integerValue] % 60);
                        
                        //format total time in minute second format
                        if ([seconds intValue]<10) {
                            elapsedtime = [NSString stringWithFormat:@"%@:0%@",minutes,seconds];
                            
                        }
                        else{
                            elapsedtime = [NSString stringWithFormat:@"%@:%@",minutes,seconds];
                            
                        }
                    }
                    //insert first seen time into running time
                    if ([self.first_seen objectAtIndex:index] == [NSNull null]){
                        NSLog(@"First seen here");
                        [athleteDictionary setObject:[NSNumber numberWithDouble:0] forKey:@"dateTime"];
                        [athleteDictionary setObject:[NSNumber numberWithDouble:0] forKey:@"last_seen"];
                    }
                    else{
                        NSLog(@"Second seen here");
                        newStartRunningTime =[self.first_seen objectAtIndex:index];
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
                        NSDate *dateFromString = [[NSDate alloc] init];
                        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                        [dateFormatter setTimeZone:timeZone];
                        dateFromString = [dateFormatter dateFromString:newStartRunningTime];
                        NSTimeInterval timeInMiliseconds = [dateFromString timeIntervalSince1970]*1000;
                        
                        NSString *strTimeStamp = [NSString stringWithFormat:@"%f",timeInMiliseconds];
                        NSLog(@"%@",strTimeStamp);
                        [athleteDictionary setObject:strTimeStamp forKey:@"dateTime"];
                        

                        newLastRunningTime =[self.last_seen objectAtIndex:index];
                        NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
                        [dateFormatter2 setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
                        NSDate *dateFromString2 = [[NSDate alloc] init];
                        NSTimeZone *timeZone2 = [NSTimeZone timeZoneWithName:@"UTC"];
                        [dateFormatter2 setTimeZone:timeZone2];
                        dateFromString2 = [dateFormatter dateFromString:newLastRunningTime];
                        NSTimeInterval timeInMiliseconds2 = [dateFromString timeIntervalSince1970]*1000;
                        
                        NSString *strTimeStamp2 = [NSString stringWithFormat:@"%f",timeInMiliseconds2];
                        NSLog(@"%@",strTimeStamp2);
                        [athleteDictionary setObject:strTimeStamp2 forKey:@"last_seen"];
                    }

                    
                   
                    [athleteDictionary setObject:[self.runners objectAtIndex:index] forKey:@"name"];
                    [athleteDictionary setObject:[self.runnerID objectAtIndex:index] forKey:@"athleteID"];
                    [athleteDictionary setObject:superlasttime forKey:@"lastSplit"];
                    [athleteDictionary setObject:[NSNumber numberWithInt:universalIndex] forKey:@"numberSplits"];
                    [athleteDictionary setObject:elapsedtime forKey:@"totalTime"];
                    
                    //Introduce first_seen here
                    [athleteDictionary setObject:[NSNumber numberWithDouble:0] forKey:@"countStart"];
                    [self.athleteDictionaryArray addObject:athleteDictionary];
                    [self.tableData beginUpdates];
                    [self.tableData insertRowsAtIndexPaths:rowsToAdd withRowAnimation:UITableViewRowAnimationBottom];
                    [self.tableData endUpdates];
                    
                }

            }
            
            index++;
           
        }
       //Only load the full table the first time, after that append it.
       if(Executed ==TRUE){
           [self.tableData reloadData];
       }
       Executed = FALSE;
      [self updateButtonsToMatchTableState];

        self.humanReadble.text = [NSString stringWithFormat:@"Date: %@", self.workoutDate];

        return self.runners;
  }
    @catch (NSException *exception) {
        NSLog(@"An exception occurred: %@", exception.name);
        NSLog(@"Here are some details: %@", exception.reason);
        return self.runners;
    }

   
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [((CustomCell *)[self.tableData cellForRowAtIndexPath:indexPath]).sw startWatch];
    [((CustomCell *)[self.tableData cellForRowAtIndexPath:indexPath]).sw setHighlighted:NO];
     NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:indexPath.row];
    // Update the delete button's title based on how many items are selected.
    NSLog(@"Dictionary %@",[tempDict valueForKey:@"athleteID"]);
    NSLog(@"Indecies %@", self.selectedRunners);
    NSUInteger indexOfTheObject = [self.selectedRunners indexOfObject:[tempDict valueForKey:@"athleteID"]];
    [self.selectedRunners removeObjectAtIndex:indexOfTheObject];
    [self.selectedRunnersUTC removeObjectAtIndex:indexOfTheObject];
    [self.selectedRunnersToast removeObjectAtIndex:indexOfTheObject];
    
    [self updateSplitButtonTitle];
}

- (void)selectCell:(CustomCell *)cell {
    NSIndexPath *indexPath =  [self.tableData indexPathForCell:cell];
    UITableView *tableView = self.tableData;
    
    if (!!cell.selected) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
        // Above method will not call the below delegate methods
        if ([tableView.delegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) {
            [tableView.delegate tableView:tableView willSelectRowAtIndexPath:indexPath];
        }
        if ([tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            [tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
        }
    } else {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        // Above method will not call the below delegate methods
        if ([tableView.delegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)]) {
            [tableView.delegate tableView:tableView willDeselectRowAtIndexPath:indexPath];
        }
        if ([tableView.delegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)]) {
            [tableView.delegate tableView:tableView didDeselectRowAtIndexPath:indexPath];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:indexPath.row];
    NSDate *currentDate = [[NSDate alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
    [dateFormatter setTimeZone:timeZone];
    NSString *localDateString = [dateFormatter stringFromDate:currentDate];
    
    [self.selectedRunners addObject:[tempDict valueForKey:@"athleteID"]];
    [self.selectedRunnersUTC addObject:localDateString];
    [self.selectedRunnersToast addObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970 ]*1000]];
    NSLog(@"UTC %@",self.selectedRunnersUTC);
    NSLog(@"Indecies %@",self.selectedRunners);
    // Update the delete button's title based on how many items are selected.
    [self updateButtonsToMatchTableState];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.athleteDictionaryArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //depending on ipad or phone use different custom cell spacing, and fill in cell data
    if (IDIOM ==IPAD) {
        static NSString *simpleTableIdentifier = @"myCell";
        CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            
            [tableView registerNib:[UINib nibWithNibName:@"CustomCell" bundle:nil] forCellReuseIdentifier:@"myCell"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"myCell"];
        }
        
        NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:indexPath.row];
        
        cell.Name.text = [tempDict valueForKey:@"name"];
        cell.Split.text= [tempDict valueForKey:@"lastSplit"];
        cell.Total.text= [tempDict valueForKey:@"totalTime"];
        
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:0.80 alpha:1.0];
        [cell setSelectedBackgroundView:bgColorView];
        
        
        cell.delegate = self;
        [cell configureCell];
        [cell setEditing:self.isEditing];
        
        return cell;
    }
    else{
        static NSString *simpleTableIdentifier = @"myCell";
        CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        //NSLog(@"Fails nil?");
        [tableView registerNib:[UINib nibWithNibName:@"CustomCell" bundle:nil] forCellReuseIdentifier:@"myCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"myCell"];
    }
        NSMutableDictionary *tempDict = [self.athleteDictionaryArray objectAtIndex:indexPath.row];
       
        cell.Name.text = [tempDict valueForKey:@"name"];
        cell.Split.text= [tempDict valueForKey:@"lastSplit"];
        cell.Total.text= [tempDict valueForKey:@"totalTime"];

        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:0.80 alpha:1.0];
        [cell setSelectedBackgroundView:bgColorView];
        
        
        cell.delegate = self;
        [cell configureCell];
        [cell setEditing:self.isEditing];
        //CGFloat swDim = CGRectGetHeight(cell.frame) - 16;
        //cell.sw = [[StopWatchControl alloc] initWithFrame:CGRectMake(8, 8, swDim, swDim)];
        //[cell.customEditControl addSubview:cell.sw];
        

        return cell;
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}



@end
