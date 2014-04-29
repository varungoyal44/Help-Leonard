//
//  ASMyTeamViewController.m
//  ApplicoESPNSample
//
//  Created by Varun Goyal on 4/29/14.
//  Copyright (c) 2014 Karma. All rights reserved.
//

#import "ASMyTeamViewController.h"
#import "DataFile.h"
#import "WebServiceManager.h"
#import <QuartzCore/QuartzCore.h>
#import "ASHeadLinesTableViewCell.h"

@interface ASMyTeamViewController ()
@property (strong, nonatomic) IBOutlet UILabel *lbTitle;
@property (strong, nonatomic) IBOutlet UIButton *btnBack;
@property (strong, nonatomic) IBOutlet UIButton *btnReset;
@property (strong, nonatomic) IBOutlet UITableView *tableViewSelectTeam;
@property (strong, nonatomic) IBOutlet UITableView *tableViewNews;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSMutableDictionary *teams;
@property (strong, nonatomic) NSMutableArray *headlines;
@property (strong, nonatomic) NSMutableArray *description;
@end


@implementation ASMyTeamViewController
@synthesize lbTitle = _lbTitle;
@synthesize btnBack = _btnBack;
@synthesize btnReset = _btnReset;
@synthesize tableViewSelectTeam = _tableViewSelectTeam;
@synthesize tableViewNews = _tableViewNews;
@synthesize activityIndicator = _activityIndicator;
@synthesize teams = _teams;
@synthesize headlines = _headlines;
@synthesize description = _description;

#pragma mark- LIFECYCLE
-(void) viewDidLoad
{
    [super viewDidLoad];
    
    // To display activity indicator
    [self.tableViewSelectTeam setHidden:YES];
    [self.tableViewNews setHidden:YES];
    [self.activityIndicator setHidesWhenStopped:YES];
    
    // To set button border
    [self.btnBack.layer setBorderWidth:1.0];
    [self.btnBack.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.btnReset.layer setBorderWidth:1.0];
    [self.btnReset.layer setBorderColor:[UIColor blackColor].CGColor];
    
    // To see if user's default favourite team is selected
    NSString *selectedTeamURL = [[NSUserDefaults standardUserDefaults] valueForKey:keyUserDefaults_SelectedTeamURL];
    if (!selectedTeamURL)
    {
        [self displayListOfTeams];
    }
    else
    {
        [self getNewsForTeam:selectedTeamURL];
    }
}

#pragma mark- Actions
- (IBAction)btnResetPressed:(id)sender
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:keyUserDefaults_SelectedTeamURL];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:keyUserDefaults_SelectedTeamName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self displayListOfTeams];
}

- (IBAction)btnBackPressed:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark- Utilities
-(void) displayListOfTeams
{
    // To display activity indicator
    [self.activityIndicator startAnimating];
    
    // To reset the title
    [self.lbTitle setText:@"My Team"];
    
    // To get the list of teams
    NSString *url = [NSString stringWithFormat:@"%@%@", apiESPN_AllTeams, keyESPN];
    NSLog(@"url:%@", url);
    
    WebServiceCallbackBlock completionBlock = ^(id data,NSURLResponse *response,NSError *error) {
        if (error) {
            NSLog(@"Error:%@", error);
            
            // To display error
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
            [self extractTeamList:dataJSON];
        }
    };
    NSMutableURLRequest *urlReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    WebServiceRequest *req = [[WebServiceRequest alloc] initWithURLRequest:urlReq
                                                                  progress:nil
                                                                completion:completionBlock];
    [[WebServiceManager sharedManager] startAsync:req];
    
}

-(void) extractTeamList: (NSDictionary *) dataJSON
{
    // To initialize arrays
    int numberOfTeams = [[dataJSON valueForKey:@"resultsCount"] intValue];
    self.teams = [NSMutableDictionary dictionaryWithCapacity:numberOfTeams];
    
    // To extract team names and links
    id allTeams = [[[dataJSON valueForKey:@"sports"] valueForKey:@"leagues"] valueForKey:@"teams"][0][0];
    for (NSDictionary *thisTeam in allTeams)
    {
        [self.teams setObject:
         [[[[thisTeam valueForKey:@"links"] valueForKey:@"api"] valueForKey:@"news"] valueForKey:@"href"]
                       forKey:
         [NSString stringWithFormat:@"%@, %@", [thisTeam valueForKey:@"name"], [thisTeam valueForKey:@"location"]]];
    }
    
    // To display the data
    [self.activityIndicator stopAnimating];
    [self.tableViewNews setHidden:YES];
    [self.tableViewSelectTeam setHidden:NO];
    [self.tableViewSelectTeam scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self.tableViewSelectTeam reloadData];
}

- (void) getNewsForTeam: (NSString *) teamAPIString
{
    [self.tableViewSelectTeam setHidden:YES];
    [self.activityIndicator startAnimating];
    
    // To get the list of teams
    NSString *url = [NSString stringWithFormat:@"%@%@", teamAPIString, keyESPN];
    NSLog(@"url:%@", url);
    
    WebServiceCallbackBlock completionBlock = ^(id data,NSURLResponse *response,NSError *error) {
        if (error) {
            NSLog(@"Error:%@", error);
            
            // To display error
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
            [self displayTeamNews:dataJSON];
        }
    };
    NSMutableURLRequest *urlReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    WebServiceRequest *req = [[WebServiceRequest alloc] initWithURLRequest:urlReq
                                                                  progress:nil
                                                                completion:completionBlock];
    [[WebServiceManager sharedManager] startAsync:req];
}


-(void) displayTeamNews: (NSDictionary *) dataJSON
{
    // To initialize the arrays
    int resultCount = [[dataJSON valueForKey:@"resultsCount"] intValue];
    self.headlines = [NSMutableArray arrayWithCapacity:resultCount];
    self.description = [NSMutableArray arrayWithCapacity:resultCount];
    
    // To enumerate through JSON
    for(NSDictionary *thisHeadline in [dataJSON valueForKey:@"headlines"])
    {
        [self.headlines addObject:[thisHeadline valueForKey:@"headline"]];
        [self.description addObject:[thisHeadline valueForKey:@"description"]];
    }
    
    // To reset title
    NSString *selectedTeamName = [[NSUserDefaults standardUserDefaults] valueForKey:keyUserDefaults_SelectedTeamName];
    [self.lbTitle setText:selectedTeamName];
    
    // To display the data
    [self.activityIndicator setHidden:YES];
    [self.activityIndicator stopAnimating];
    [self.tableViewSelectTeam setHidden:YES];
    [self.tableViewNews scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self.tableViewNews setHidden:NO];
    [self.tableViewNews reloadData];
}



#pragma mark- UITableViewDelegate
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.tableViewSelectTeam)
        return self.teams.count;
    else
        return self.headlines.count;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableViewSelectTeam)
    {
        static NSString *MyIdentifier = @"selectMyTeamCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
        }
        
        NSArray *teamNames = [self.teams allKeys];
        cell.textLabel.text = [teamNames objectAtIndex:indexPath.row];
        
        return cell;
    }
    else
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
    
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableViewSelectTeam)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSString *selectedTeamName = cell.textLabel.text;
        NSString *selectedTeamURL = [self.teams valueForKey:selectedTeamName];
        
        [[NSUserDefaults standardUserDefaults] setObject:selectedTeamURL forKey:keyUserDefaults_SelectedTeamURL];
        [[NSUserDefaults standardUserDefaults] setObject:selectedTeamName forKey:keyUserDefaults_SelectedTeamName];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self getNewsForTeam:selectedTeamURL];
    }
}
@end
