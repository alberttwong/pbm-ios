//
//  RegionsView.m
//  PinballMap
//
//  Created by Frank Michael on 4/14/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "RegionsView.h"
@import MessageUI;
#import "UIAlertView+Application.h"
#import "GAAppHelper.h"
#import <ReuseWebView.h>

@interface RegionsView () <NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,MFMailComposeViewControllerDelegate,UIAlertViewDelegate> {
    NSFetchedResultsController *fetchedResults;
    NSMutableArray *searchResults;
}
- (IBAction)cancelRegion:(id)sender;    // iPad only.
- (IBAction)requestRegion:(id)sender;

@end

@implementation RegionsView

- (id)initWithStyle:(UITableViewStyle)style{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"Regions";

    searchResults = [NSMutableArray new];
    [[PinballMapManager sharedInstance] refreshAllRegions];
    NSFetchRequest *regionsFetch = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
    regionsFetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES]];
    
    fetchedResults = [[NSFetchedResultsController alloc] initWithFetchRequest:regionsFetch
                                                         managedObjectContext:[[CoreDataManager sharedInstance] managedObjectContext]
                                                           sectionNameKeyPath:nil
                                                                    cacheName:nil];
    fetchedResults.delegate = self;
    [fetchedResults performFetch:nil];
    [self.tableView reloadData];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [GAAppHelper sendAnalyticsDataWithScreen:@"Region Select View"];
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Class actions
- (IBAction)requestRegion:(id)sender{

    UIAlertView *regionAlert = [[UIAlertView alloc] initWithTitle:@"Pinball Map" message:@"When requesting that a map for your area be added, please describe WHY one should be added. Does your region have an active pinball scene? Leagues? How many locations have pinball machines? Are you keeping track of them already? Would you be willing to act as the regional administrator, to help curate your map's data? The more details you give us, the better your request sounds!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"More Information",@"Request Region",nil];
    [regionAlert show];
    
}
- (IBAction)cancelRegion:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - SearchDisplayController
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
    request.predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[cd] %@",searchString];
    
    [searchResults removeAllObjects];
    NSManagedObjectContext *context = [[CoreDataManager sharedInstance] managedObjectContext];
    
    [searchResults addObjectsFromArray:[context executeFetchRequest:request error:nil]];
    return YES;
}
#pragma mark - MFMailComposeDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result == MFMailComposeResultFailed){
        [UIAlertView simpleApplicationAlertWithMessage:@"Message failed to send." cancelButton:@"Ok"];
    }else if (result == MFMailComposeResultSent){
        [UIAlertView simpleApplicationAlertWithMessage:@"Message sent. Thank You!" cancelButton:@"Ok"];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex != alertView.cancelButtonIndex){
        if (buttonIndex == 1){
            ReuseWebView *webView = [[ReuseWebView alloc] initWithURL:[NSURL URLWithString:@"http://blog.pinballmap.com/2014/07/21/criteria-for-adding-a-new-pinball-map"]];
            webView.webTitle = @"Pinball Map";
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webView];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self.navigationController presentViewController:navController animated:YES completion:nil];
        }else if (buttonIndex == 2){
            if ([MFMailComposeViewController canSendMail]){
                MFMailComposeViewController *requestMessage = [[MFMailComposeViewController alloc] init];
                requestMessage.mailComposeDelegate = self;
                [requestMessage setSubject:@"Adding my region to PinballMap.com"];
                [requestMessage setToRecipients:@[@"pinballmap@outlook.com"]];
                [self presentViewController:requestMessage animated:YES completion:nil];
            }
        }
    }
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger rows = 0;
    if (tableView == self.tableView){
        if ([[fetchedResults sections] count] > 0) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResults sections] objectAtIndex:section];
            rows = [sectionInfo numberOfObjects];
        }
    }else{
        rows = searchResults.count;
    }
    return rows;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    
    if (self.tableView == tableView){
        cell = [tableView dequeueReusableCellWithIdentifier:@"RegionCell" forIndexPath:indexPath];
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"RegionCell"];
        if (!cell){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RegionCell"];
        }
    }
    
    Region *region;
    if (self.tableView == tableView){
        region = [fetchedResults objectAtIndexPath:indexPath];
    }else{
        region = searchResults[indexPath.row];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    Region *selectedRegion = [[PinballMapManager sharedInstance] currentRegion];
    if ([region.name isEqualToString:selectedRegion.name]){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
    }
    
    cell.textLabel.text = region.fullName;
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Region *region;
    if (self.tableView == tableView){
        region = [fetchedResults objectAtIndexPath:indexPath];
    }else{
        region = searchResults[indexPath.row];
    }
    
    [[PinballMapManager sharedInstance] loadRegionData:region];
    [self.tableView reloadData];
    [self.searchDisplayController setActive:NO animated:YES];
    if (_isSelecting){
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if ([self.parentViewController isKindOfClass:[UINavigationController class]]){
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}
#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex
	 forChangeType:(NSFetchedResultsChangeType)type{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}

@end