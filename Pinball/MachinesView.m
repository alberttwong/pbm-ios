//
//  MachinesView.m
//  PinballMap
//
//  Created by Frank Michael on 4/12/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "MachinesView.h"
#import "MachineLocation.h"
#import "MachineProfileView.h"
#import "GAAppHelper.h"

@interface MachinesView () <NSFetchedResultsControllerDelegate,UISearchBarDelegate>{
    NSFetchedResultsController *fetchedResults;
    NSManagedObjectContext *managedContext;
    BOOL isSearching;
    NSMutableArray *searchResults;
}
- (IBAction)addMachine:(id)sender;

@end

@implementation MachinesView

- (id)initWithStyle:(UITableViewStyle)style{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRegion) name:@"RegionUpdate" object:nil];
    [self updateRegion];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [GAAppHelper sendAnalyticsDataWithScreen:@"Machines View"];
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ProfileView"]){
        Machine *currentMachine;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (!isSearching){
            currentMachine = [fetchedResults objectAtIndexPath:indexPath];
        }else{
            currentMachine = searchResults[indexPath.row];
        }
        MachineProfileView *profileView = segue.destinationViewController;
        profileView.currentMachine = currentMachine;
    }
}
#pragma mark - Class Actions
- (IBAction)addMachine:(id)sender{
    UINavigationController *newMachine = [self.storyboard instantiateViewControllerWithIdentifier:@"NewMachineView"];
    if ([UIDevice iPad]){
        newMachine.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self.navigationController presentViewController:newMachine animated:YES completion:nil];
}
#pragma mark - Region Update
- (void)updateRegion{
    self.navigationItem.title = [NSString stringWithFormat:@"%@ Machines",[[[PinballMapManager sharedInstance] currentRegion] fullName]];
    managedContext = [[CoreDataManager sharedInstance] managedObjectContext];
    NSFetchRequest *stackRequest = [NSFetchRequest fetchRequestWithEntityName:@"Machine"];
    stackRequest.predicate = [NSPredicate predicateWithFormat:@"machineLocations.location.region CONTAINS %@" argumentArray:@[[[PinballMapManager sharedInstance] currentRegion]]];
    stackRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    fetchedResults = [[NSFetchedResultsController alloc] initWithFetchRequest:stackRequest
                                                         managedObjectContext:managedContext
                                                           sectionNameKeyPath:@"name"
                                                                    cacheName:nil];
    fetchedResults.delegate = self;
    [fetchedResults performFetch:nil];
    [self.tableView reloadData];
}
#pragma mark - Searchbar Delegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    isSearching = YES;
    searchBar.showsCancelButton = YES;
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    NSFetchRequest *searchrequest = [NSFetchRequest fetchRequestWithEntityName:@"Machine"];
    searchrequest.predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@",searchText];
    [searchResults removeAllObjects];
    searchResults = nil;
    searchResults = [NSMutableArray new];
    NSError *error = nil;
    [searchResults addObjectsFromArray:[managedContext executeFetchRequest:searchrequest error:&error]];
    [self.tableView reloadData];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    isSearching = NO;
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    searchBar.showsCancelButton = NO;
    [self.tableView reloadData];
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (!isSearching){
        return [[fetchedResults sections] count];
    }else{
        return 1;
    }
}
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    if (!isSearching){
        return [fetchedResults sectionIndexTitles];
    }
    return @[];
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    return [fetchedResults sectionForSectionIndexTitle:title atIndex:index];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger rows = 0;
    if (!isSearching){
        if ([[fetchedResults sections] count] > 0) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResults sections] objectAtIndex:section];
            rows = [sectionInfo numberOfObjects];
        }
    }else{
        rows = searchResults.count;
    }
    return rows;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    float defaultWidth = 255;
    
    Machine *currentMachine;
    if (!isSearching){
        currentMachine = [fetchedResults objectAtIndexPath:indexPath];
    }else{
        currentMachine = searchResults[indexPath.row];
    }
    
    NSString *detailString = [NSString stringWithFormat:@"%@, %@",currentMachine.manufacturer,currentMachine.year];
    
    CGRect titleLabel = [currentMachine.name boundingRectWithSize:CGSizeMake(defaultWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:18]} context:nil];//boundingRectWithSize:CGSizeMake(defaultWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    CGRect detailLabel = [detailString boundingRectWithSize:CGSizeMake(defaultWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]} context:nil];
    // Add 6 pixel padding present in subtitle style.
    CGRect stringSize = CGRectMake(0, 0, defaultWidth, titleLabel.size.height+detailLabel.size.height+6);
    return stringSize.size.height;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MachineCell" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    Machine *currentMachine;
    if (!isSearching){
        currentMachine = [fetchedResults objectAtIndexPath:indexPath];
    }else{
        currentMachine = searchResults[indexPath.row];
    }

    cell.textLabel.text = currentMachine.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",currentMachine.manufacturer,currentMachine.year];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Machine *currentMachine;
    if (!isSearching){
        currentMachine = [fetchedResults objectAtIndexPath:indexPath];
    }else{
        currentMachine = searchResults[indexPath.row];
    }
    if ([UIDevice iPad]){
        MachineProfileView *profileView = (MachineProfileView *)[[self.splitViewController detailViewForSplitView] navigationRootViewController];
        [profileView setCurrentMachine:currentMachine];
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