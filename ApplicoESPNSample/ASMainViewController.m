//
//  ASMainViewController.m
//  ApplicoESPNSample
//
//  Created by Varun Goyal on 4/28/14.
//  Copyright (c) 2014 Karma. All rights reserved.
//

#import "ASMainViewController.h"
#import "WebServiceManager.h"
#import "DataFile.h"
#import "ASHeadLinesTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>

#define numberOfHeadlines 30
#define cellMargin 5
#define cellLabelTitleHeight 21

@interface ASMainViewController ()
@property (strong, nonatomic) NSMutableArray *headlines;
@property (strong, nonatomic) NSMutableArray *description;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIButton *btnMyTeam;

@end

@implementation ASMainViewController
@synthesize headlines = _headlines;
@synthesize description = _description;
@synthesize tableView = _tableView;
@synthesize activityIndicator = _activityIndicator;
@synthesize btnMyTeam = _btnMyTeam;

#pragma mark- LIFECYCLE
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // To hide status bar
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationNone];
    // To display activity indicator
    [self.activityIndicator setHidesWhenStopped:YES];
    [self.activityIndicator startAnimating];
    [self.tableView setHidden:YES];
    
    // To set button border
    [self.btnMyTeam.layer setBorderWidth:1.0];
    [self.btnMyTeam.layer setBorderColor:[UIColor blackColor].CGColor];
    
    // To load the top news headline
    NSString *url = [NSString stringWithFormat:@"%@%@&limit=%d", apiESPN_Headlines, keyESPN, numberOfHeadlines];
    
    NSLog(@"url:%@", url);
    
    WebServiceCallbackBlock completionBlock = ^(id data,NSURLResponse *response,NSError *error) {
        if (error) {
            NSLog(@"Error:%@", error);
            
            // To display error...
            [self.activityIndicator stopAnimating];
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Oh no!"
                                  message:@"Something went wrong please try again later"
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
            
        } else {
            NSDictionary *dataJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            [self extractData:dataJSON];
        }
    };
    NSMutableURLRequest *urlReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    WebServiceRequest *req = [[WebServiceRequest alloc] initWithURLRequest:urlReq
                                                                  progress:nil
                                                                completion:completionBlock];
    [[WebServiceManager sharedManager] startAsync:req];
    
}

#pragma mark- Utilities
/*
 There are much better way to extract data from JSON stream,
 however this is the fastest and easiest so i'll be going with this.
 */
- (void) extractData: (NSDictionary *) dataJSON
{
    // To initialize the arrays
    self.headlines = [NSMutableArray arrayWithCapacity:numberOfHeadlines];
    self.description = [NSMutableArray arrayWithCapacity:numberOfHeadlines];
    
    // To enumerate through JSON
    for(NSDictionary *thisHeadline in [dataJSON valueForKey:@"headlines"])
    {
        [self.headlines addObject:[thisHeadline valueForKey:@"headline"]];
        [self.description addObject:[thisHeadline valueForKey:@"description"]];
    }
    
    // To display the data
    [self.activityIndicator setHidden:YES];
    [self.activityIndicator stopAnimating];
    [self.tableView setHidden:NO];
    [self.tableView reloadData];
}


#pragma mark- UITableViewDelegate Methods
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.headlines.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"headlineCellIdentifier";
    ASHeadLinesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[ASHeadLinesTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
    
    cell.lbTitle.text = [self.headlines objectAtIndex:indexPath.row];
    cell.lbDescription.text = [self.description objectAtIndex:indexPath.row];
    [cell.lbDescription sizeToFit];
    return cell;
}


#pragma mark- Twitter
- (IBAction)btnTwitterPressed:(id)sender
{
    SLComposeViewController *twitterController=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
            
            [twitterController dismissViewControllerAnimated:YES completion:nil];
            
            switch(result){
                case SLComposeViewControllerResultCancelled:
                default:
                {
                    NSLog(@"Cancelled.....");
                    
                }
                    break;
                case SLComposeViewControllerResultDone:
                {
                    NSLog(@"Posted....");
                }
                    break;
            }};
        
        
        [twitterController setInitialText:@"I am using Applico ESPN App developed by Varun Goyal"];
        [twitterController addURL:[NSURL URLWithString:@"http://www.applicoinc.com/"]];
        [twitterController setCompletionHandler:completionHandler];
        [self presentViewController:twitterController animated:YES completion:nil];
    }
    
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Twitter"
                              message:@"Please enable download Twitter app and sign in via settings."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}


@end
