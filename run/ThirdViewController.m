//
//  ThirdViewController.m
//  TRAC
//
//  Created by Griffin Kelly on 4/16/15.
//  Copyright (c) 2015 Griffin Kelly. All rights reserved.
//
#import "TRACDatabase.h"
#import "TRACDoc.h"
#import "ThirdViewController.h"
#import "FirstViewController.h"
#import "RosterTableViewController.h"
#define TRACQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1

@interface ThirdViewController ()

@end

@implementation ThirdViewController
@synthesize sensorSwitch;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        //NSLog(@"URL ID: %@", self.urlID);
    [self.sensorTextField setEnabled:NO];
     NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"token"];
     NSString *url = [NSString stringWithFormat: @"https://trac-us.appspot.com/api/sessions/%@/?access_token=%@", self.urlID,savedToken];
    dispatch_async(TRACQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:
                        [NSURL URLWithString:url]];
        
        dispatch_async(dispatch_get_main_queue() ,^{
            [self fetchedData:data];
           // [self.tableData reloadData];
            NSDictionary* id_num = [self.jsonData valueForKey:@"id"];
             //NSLog(@"URL ID IN VIew did load: %@", id_num);
        });
        
        
    });

}

- (IBAction)switchPressed:(id)sender
{
    if(sensorSwitch.on)
    {
         self.sensorTextField.text = @"The Sensor is On for this Session";
         [self calibrateWorkout];
    }
    else
        
    {
        self.sensorTextField.text = @"The Sensor is Off for this Session";
        [self endWorkout];
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)logoutClicked:(id)sender {
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
    NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"token"];
    
    //NSLog(@"Secutiy Token: %@",savedToken);
    [self performSegueWithIdentifier:@"logout" sender:self];

}
- (void)endWorkout{
   
    NSInteger success = 0;
    
    @try {
        
        NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"token"];
        NSString *idurl2 = [NSString stringWithFormat: @"https://trac-us.appspot.com/api/sessions/%@/close/?access_token=%@", self.urlID ,savedToken];
        
        NSURL *url=[NSURL URLWithString:idurl2];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:url];
        [request setHTTPMethod:@"POST"];
        
        
        NSError *error = [[NSError alloc] init];
        NSHTTPURLResponse *response = nil;
        NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if ([response statusCode] >= 200 && [response statusCode] < 300)
        {
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
           // NSLog(@"Response ==> %@", responseData);
            
            NSError *error = nil;
            NSDictionary *jsonData = [NSJSONSerialization
                                      JSONObjectWithData:urlData
                                      options:NSJSONReadingMutableContainers
                                      error:&error];
            
            success = [jsonData[@"success"] integerValue];
            //NSLog(@"Success: %ld",(long)success);
            
            if(success == 0)
            {
                NSLog(@"changed");
                //UIAlertView *alert =[[UIAlertView alloc]initWithTitle:@"Success!" message:@"Successfully changed end time of workout" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                //[alert show];
                //return self.access_token;
            } else {
                
                //NSLog(@"Failed");
                
            }
            
        } else {
            //if (error) NSLog(@"Error: %@", error);
            //NSLog(@"Failed");
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
            [self performSegueWithIdentifier:@"logout" sender:self];
           
        }
        
    }
    @catch (NSException * e) {
        //NSLog(@"Exception: %@", e);
        
    }


}
- (IBAction)resetWorkout:(id)sender{
    //NSLog(@"ID Number, %@",self.urlID);
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Reset Workout?"
                                                       message:@"These results will be permanently deleted."
                                                      delegate:self
                             
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:@"Cancel",nil];
    [theAlert show];

}

- (void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //NSLog(@"The %@ button was tapped.", [theAlert buttonTitleAtIndex:buttonIndex]);
    if (buttonIndex == 0)
    {
        //NSLog(@"Data in here? %@, %@, %@",self.resetValueArray, self.athleteIDArray, self.utcTimeArray);
        NSLog(@"Deleting Stored Data?");
        [TRACDatabase deletePath:self.urlID];
        TRACDoc *newDoc = [[TRACDoc alloc] initWithTitle:nil toast:nil reset:nil];
        [newDoc saveData:self.urlID];
        NSLog(@"Delete stuff end");
        
        //if signin button clicked query server with credentials
        NSInteger success = 0;
        @try {
            
            
            //if success
            
            NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"token"];
            NSString *idurl2 = [NSString stringWithFormat: @"https://trac-us.appspot.com/api/sessions/%@/reset/?access_token=%@", self.urlID ,savedToken];
            
            NSURL *url=[NSURL URLWithString:idurl2];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:url];
            [request setHTTPMethod:@"POST"];

            
            //[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
            
            NSError *error = [[NSError alloc] init];
            NSHTTPURLResponse *response = nil;
            NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            //NSLog(@"Response code: %ld", (long)[response statusCode]);
            // NSLog(@"Error Code: %@", [error localizedDescription]);
            
            if ([response statusCode] >= 200 && [response statusCode] < 300)
            {
                NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
                //NSLog(@"Response ==> %@", responseData);
                
                NSError *error = nil;
                NSDictionary *jsonData = [NSJSONSerialization
                                          JSONObjectWithData:urlData
                                          options:NSJSONReadingMutableContainers
                                          error:&error];
                
                success = [jsonData[@"success"] integerValue];
                //NSLog(@"Success: %ld",(long)success);
                
                if(success == 0)
                {
                    //NSLog(@"SUCCESS");
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"myNotification" object:@"Pass this variable!!"];


                    //return self.access_token;
                } else {
                    
                    //NSLog(@"Failed");
                    
                }
                
            } else {
                [self performSegueWithIdentifier:@"logout" sender:self];
                //if (error) NSLog(@"Error: %@", error);
                //NSLog(@"Failed");
                
            }
            
        }
        @catch (NSException * e) {
            //NSLog(@"Exception: %@", e);
            
        }
        
    }
    
    
}

- (IBAction)goButton:(id)sender{

    NSInteger success = 0;
    @try {
        
    
        //if success
        NSString *post =[[NSString alloc] initWithFormat:@"id=%@",self.urlID];
        //NSLog(@"Post: %@",post);
        
        NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"token"];
        NSString *idurl2 = [NSString stringWithFormat: @"https://trac-us.appspot.com/api/sessions/%@/start_timer/?access_token=%@", self.urlID ,savedToken];
        
        NSURL *url=[NSURL URLWithString:idurl2];
        
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        //NSLog(@"Post Data:%@", postData);
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
        
        
        //[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
        
        NSError *error = [[NSError alloc] init];
        NSHTTPURLResponse *response = nil;
        NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //NSLog(@"Response code: %ld", (long)[response statusCode]);
        // NSLog(@"Error Code: %@", [error localizedDescription]);
        
        if ([response statusCode] >= 200 && [response statusCode] < 300)
        {
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
            //NSLog(@"Response ==> %@", responseData);
            
            NSError *error = nil;
            NSDictionary *jsonData = [NSJSONSerialization
                                      JSONObjectWithData:urlData
                                      options:NSJSONReadingMutableContainers
                                      error:&error];
            
            success = [jsonData[@"success"] integerValue];
            //NSLog(@"Success: %ld",(long)success);
            
            if(success == 0)
            {
                //NSLog(@"SUCCESS");
                UIAlertView *alert =[[UIAlertView alloc]initWithTitle:@"Success!" message:@"Successfully started race!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                
                //return self.access_token;
            } else {
                
                //NSLog(@"Failed");
                
            }
            
        } else {
            //if (error) NSLog(@"Error: %@", error);
            //NSLog(@"Failed");
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
            //NSLog(@"Response ==> %@", responseData);
            [self performSegueWithIdentifier:@"logout" sender:self];
        }
        
    }
    @catch (NSException * e) {
        //NSLog(@"Exception: %@", e);
        
    }
}


- (void)calibrateWorkout {
    
    NSInteger success = 0;
    
    @try {
        
        NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"token"];
        NSString *idurl2 = [NSString stringWithFormat: @"https://trac-us.appspot.com/api/sessions/%@/open/?access_token=%@", self.urlID ,savedToken];
        
        NSURL *url=[NSURL URLWithString:idurl2];

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:url];
        [request setHTTPMethod:@"POST"];
        
        
        NSError *error = [[NSError alloc] init];
        NSHTTPURLResponse *response = nil;
        NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if ([response statusCode] >= 200 && [response statusCode] < 300)
        {
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
            //NSLog(@"Response ==> %@", responseData);
            
            NSError *error = nil;
            NSDictionary *jsonData = [NSJSONSerialization
                                      JSONObjectWithData:urlData
                                      options:NSJSONReadingMutableContainers
                                      error:&error];
            
            success = [jsonData[@"success"] integerValue];
            //NSLog(@"Success: %ld",(long)success);
            
            if(success == 0)
            {
                NSLog(@"SUCCESS");
                //UIAlertView *alert =[[UIAlertView alloc]initWithTitle:@"Success!" message:@"Successfully changed start time of workout" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                //[alert show];
                //return self.access_token;
            } else {
                
                //NSLog(@"Failed");
                
            }
            
        } else {
            //if (error) NSLog(@"Error: %@", error);
            //NSLog(@"Failed");
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSASCIIStringEncoding];
            //NSLog(@"Response ==> %@", responseData);
            [self performSegueWithIdentifier:@"logout" sender:self];
        }
        
    }
    @catch (NSException * e) {
       // NSLog(@"Exception: %@", e);
        
    }

    
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (NSDictionary *)fetchedData:(NSData *)responseData {
    @try {
        //parse out the json data
        NSError* error;
       self.jsonData = [NSJSONSerialization
                              JSONObjectWithData:responseData //1
                              
                              options:kNilOptions
                              error:&error];
        
        //NSArray* workoutid = [json valueForKey:@"workoutID"]; //2
        // NSArray* date = [json valueForKey:@"date"];
       
         NSDictionary* id_num = [self.jsonData valueForKey:@"id"];
        NSDictionary* name = [self.jsonData valueForKey:@"name"];
        self.start_time = [self.jsonData valueForKey:@"start_time"];
        self.end_time = [self.jsonData valueForKey:@"stop_time"];
        NSArray *readers = [self.jsonData valueForKey:@"readers"];
//        NSDictionary* rest_time = [json valueForKey:@"rest_time"];
//        NSDictionary* track_size = [json valueForKey:@"track_size"];
//        NSDictionary* interval_distance = [json valueForKey:@"interval_distance"];
//        NSDictionary* interval_number = [json valueForKey:@"interval_number"];
        NSDictionary* filter_choice = [self.jsonData valueForKey:@"filter_choice"];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSDate *startString = [[NSDate alloc] init];
        NSDate *endString = [[NSDate alloc] init];
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [dateFormatter setTimeZone:timeZone];
        startString = [dateFormatter dateFromString:self.start_time];
        endString = [dateFormatter dateFromString:self.end_time];
        
        NSTimeInterval starttimeInMiliseconds = [startString timeIntervalSince1970]*1000;
        NSTimeInterval endtimeInMiliseconds = [endString timeIntervalSince1970]*1000;
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970 ]*1000;
        
        NSLog(@"The Date From String is = %@, %@",startString,self.start_time, starttimeInMiliseconds);
        NSLog(@"The Date From String is = %@, %@",endString,self.end_time, endtimeInMiliseconds);
        
        if(!readers || !readers.count){
            [sensorSwitch setEnabled:NO];
            self.sensorTextField.text = @"No Sensor Enabled";
        }
        else if (currentTime > starttimeInMiliseconds && endtimeInMiliseconds > currentTime){
            NSLog(@"Propery Bounded");
            [sensorSwitch setOn:YES];
            self.sensorTextField.text = @"The Sensor is On for this Session";
        }
        else{
            [sensorSwitch setOn:NO];
            self.sensorTextField.text = @"The Sensor is Off for this Session";
        }
        // NSLog(@"Names fetcheddata: %@", self.runners);
        return self.jsonData;
        
        
    }
    @catch (NSException *exception) {
       // NSLog(@"Exception %s","Except!");

        return self.jsonData;
    }
    
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //on view controller change, move to next page, and pass url to next view
    if ([segue.identifier isEqualToString:@"rosterSegue"]) {
        
        RosterTableViewController *rosterController = segue.destinationViewController;
        rosterController.urlID = self.urlID;

        
    }
}


@end
