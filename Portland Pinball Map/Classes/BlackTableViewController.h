//
//  BlackTableViewController.h
//  Portland Pinball Map
//
//  Created by Isaac Ruiz on 11/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LocationObject.h"
#import "Portland_Pinball_MapAppDelegate.h"
#import "PPMTableCell.h"
#import "PPMDoubleTableCell.h"
#import "LocationProfileCell.h"
#import <UIKit/UIKit.h>

//#define ShowNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = YES
//#define HideNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = NO


@interface BlackTableViewController : UITableViewController <NSXMLParserDelegate>
{
	UIActivityIndicatorView *activityView;
	UILabel                 *loadingLabel;
	NSInteger                headerHeight;
	NSArray				    *alphabet;

}

@property (nonatomic,retain) UIActivityIndicatorView *activityView;
@property (nonatomic,retain) UILabel                 *loadingLabel;
@property (nonatomic,retain) NSArray                 *alphabet;
@property (nonatomic,assign) NSInteger                headerHeight;

NSInteger sortOnDistance(id obj1, id obj2, void *context);
NSInteger sortOnName(LocationObject *obj1, LocationObject *obj2, void *context);

-(void)showLoaderIcon;
-(void)hideLoaderIcon;
-(void)showLoaderIconLarge;
-(void)hideLoaderIconLarge;
- (void)refreshPage;

-(PPMTableCell *)getTableCell;
-(PPMDoubleTableCell *)getDoubleCell;
-(void) showLocationProfile:(LocationObject*)location withMapButton:(BOOL)showMapButton;
-(LocationProfileViewController *) getLocationProfile;

@end
