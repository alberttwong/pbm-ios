//
//  Location+UpdateDistance.m
//  Pinball
//
//  Created by Frank Michael on 4/27/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "Location+UpdateDistance.h"
#import <CoreLocation/CoreLocation.h>

@implementation Location (UpdateDistance)

- (void)updateDistance{
    CLLocation *currentLocation = [[PinballManager sharedInstance] userLocation];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.latitude doubleValue] longitude:[self.longitude doubleValue]];
    self.locationDistance = [NSNumber numberWithDouble:([currentLocation distanceFromLocation:location] * 0.00062137)];
    NSLog(@"%@",self.locationDistance);
}

@end
