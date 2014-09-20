//
//  AboutView.m
//  PinballMap
//
//  Created by Frank Michael on 4/20/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "AboutView.h"
#import "GAAppHelper.h"

@interface AboutView ()

@property (nonatomic) NSArray *aboutInfo;

- (IBAction)dismissAbout:(id)sender;
@end

@implementation AboutView

- (id)initWithStyle:(UITableViewStyle)style{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    NSString *aboutFile = [[NSBundle mainBundle] pathForResource:@"AboutInfo" ofType:@"plist"];
    self.aboutInfo = [NSArray arrayWithContentsOfFile:aboutFile];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [GAAppHelper sendAnalyticsDataWithScreen:@"About View"];
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)dismissAbout:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - TableView Datasource/Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.aboutInfo.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return self.aboutInfo[section][@"sectionTitle"];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.aboutInfo[section][@"people"] count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"BasicCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSDictionary *person = self.aboutInfo[indexPath.section][@"people"][indexPath.row];
    cell.textLabel.text = person[@"name"];
    if (!person[@"url"] || [person[@"url"] length] == 0){
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *person = self.aboutInfo[indexPath.section][@"people"][indexPath.row];
    if (person[@"url"] || [person[@"url"] length] > 0){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:person[@"url"]]];
    }
}

@end
