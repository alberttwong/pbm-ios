#import "Utils.h"
#import "Machine.h"
#import "RecentAddition.h"
#import "LocationMachineXref.h"
#import "RecentlyAddedViewController.h"

@implementation RecentlyAddedViewController
@synthesize sectionData;

Portland_Pinball_MapAppDelegate *appDelegate;

- (void)viewDidLoad {
    appDelegate = (Portland_Pinball_MapAppDelegate *)[[UIApplication sharedApplication] delegate];

    [super viewDidLoad];
}
 
- (void)viewWillAppear:(BOOL)animated {
	[self setTitle:@"Recently Added"];
	[self refreshPage];
    
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    sectionData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[NSMutableArray alloc] init], TODAY, [[NSMutableArray alloc] init], YESTERDAY,[[NSMutableArray alloc] init], THIS_WEEK, [[NSMutableArray alloc] init], THIS_MONTH, [[NSMutableArray alloc] init], THIS_YEAR, nil];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@/location_machine_xrefs.rss", BASE_URL, appDelegate.activeRegion.subdir];
        
    [self showLoaderIconLarge];
    
    @autoreleasepool {
        [self performSelectorInBackground:@selector(parseXMLFileAtURL:) withObject:path];
    }
	
	[self.tableView reloadData];
}

- (void)refreshPage {    
	if (appDelegate.activeRegion.recentAdditions == nil) {
		[self showLoaderIconLarge];
	}
	
	[self.tableView reloadData];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	currentElement = [elementName copy];

	if ([elementName isEqualToString:@"item"]) {
		currentTitle = [[NSMutableString alloc] init];
		currentDesc  = [[NSMutableString alloc] init];
		parsingItemNode = YES;
	}
}

- (NSDate *)getDateFromRegexMatches:(NSArray *)matches {
    NSString *day;
    NSString *year;
    NSString *monthText;
    
    for (NSTextCheckingResult *match in matches) {
        day = [currentDesc substringWithRange:[match rangeAtIndex:1]];
        monthText = [currentDesc substringWithRange:[match rangeAtIndex:2]];
        year = [currentDesc substringWithRange:[match rangeAtIndex:3]];
    }
    
    NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
    [monthFormatter setDateFormat:@"LL"];
    NSDate *formattedMonth = [monthFormatter dateFromString:monthText];
        
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setDateFormat:@"yyyy-MM-dd"];
    
    return [inputFormatter dateFromString:[NSString stringWithFormat:@"%@-%@-%@", year, [monthFormatter stringFromDate:formattedMonth], day]];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	if ([elementName isEqualToString:@"item"]) {
		parsingItemNode = NO;

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d\\d) (\\w\\w\\w) (\\d\\d\\d\\d)" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:currentDesc options:0 range:NSMakeRange(0, [currentDesc length])];
        
        int difference;
		NSDate *dateAdded = nil;
		if ([matches count] > 0) {
            dateAdded = [self getDateFromRegexMatches:matches];
			difference = [Utils differenceInDaysFrom:[NSDate date] to:dateAdded];    
        } else {
			difference = DISTANT_FUTURE;
		}
        
		NSRange range = [currentTitle rangeOfString:@"was added to "];
		NSString *machineName = [[currentTitle substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSString *locationName = [[currentTitle substringFromIndex:range.length + range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
        Machine *machine = (Machine *)[appDelegate fetchObject:@"Machine" where:@"name" equals:[NSString stringWithFormat:@"\"%@\"", machineName]];
        Location *location = (Location *)[appDelegate fetchObject:@"Location" where:@"name" equals:[NSString stringWithFormat:@"\"%@\"", locationName]];
        
        if (location && machine) {
            RecentAddition *recentAddition = [RecentAddition findForLocation:location andMachine:machine];

            if (recentAddition == nil) {
                recentAddition = [NSEntityDescription insertNewObjectForEntityForName:@"RecentAddition" inManagedObjectContext:appDelegate.managedObjectContext];
                [recentAddition setRegion:appDelegate.activeRegion];
                [recentAddition setLocation:location];
                [recentAddition setMachine:machine];
                [recentAddition setDateAdded:dateAdded];
                [location addRecentAdditionsObject:recentAddition];
                [machine addRecentAdditionsObject:recentAddition];
                [appDelegate saveContext];
            }
        
            if(difference <= ONE_YEAR) {
                NSString *index;
                if (difference == 0) {
                    index = TODAY;
                } else if (difference == ONE_DAY) {
                    index = YESTERDAY;
                } else if (difference <=  ONE_WEEK) {
                    index = THIS_WEEK;
                } else if (difference <=  ONE_MONTH) {
                    index = THIS_MONTH;
                } else if (difference <=  ONE_YEAR) {
                    index = THIS_YEAR;
                }
                
                [[sectionData valueForKey:index] addObject:recentAddition];
            }
        }
	}
    
	currentElement = @"";
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if(parsingItemNode == YES) {
		if ([currentElement isEqualToString:@"title"] && ![string isEqualToString:@"\n"]) {
			[currentTitle appendString:string];
		} else if ([currentElement isEqualToString:@"description"] && ![string isEqualToString:@"\n"]) {
			[currentDesc appendString:string];
        }
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {	
	for (NSString *section in sectionData.allKeys) {
        NSMutableArray *data = [sectionData objectForKey:section];
        
        if ([data count] <= 0 || data == nil) {
            [sectionData removeObjectForKey:section];
        } else {
            [sectionData setValue:(NSMutableArray *)[data sortedArrayUsingComparator:^NSComparisonResult(RecentAddition *a, RecentAddition *b) {
                return [b.dateAdded compare:a.dateAdded];
            }]  forKey:section];
        }
	}
		
	[self.tableView reloadData];
	[self hideLoaderIconLarge];
	[super parserDidEndDocument:parser];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sectionData.allKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *index = [sectionData.allKeys objectAtIndex:section];
    
	return [[sectionData valueForKey:index] count];    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger) section {	
	return [sectionData.allKeys objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {	    
    PBMDoubleTableCell *cell = (PBMDoubleTableCell*)[tableView dequeueReusableCellWithIdentifier:@"DoubleTextCellID"];
    if (cell == nil) {
		cell = [self getDoubleCell];
    }
	
    NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    NSString *index = [sectionData.allKeys objectAtIndex:section];
	NSArray *locationGroup = [sectionData valueForKey:index];
	
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];

    RecentAddition *recentAddition = [locationGroup objectAtIndex:row];
	[cell.nameLabel setText:recentAddition.machine.name];
	[cell.subLabel setText:[NSString stringWithFormat:@"@%@ on %@", recentAddition.location.name, [formatter stringFromDate:recentAddition.dateAdded]]];

     return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {		
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    NSString *index = [sectionData.allKeys objectAtIndex:section];
	NSArray *locationGroup = (NSArray *)[sectionData valueForKey:index];
    RecentAddition *recentAddition = [locationGroup objectAtIndex:row];
    
    [self showLocationProfile:recentAddition.location withMapButton:YES];
}

@end