//
//  Location+UpdateDistance.h
//  PinballMap
//
//  Created by Frank Michael on 4/27/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "Location.h"

@interface Location (UpdateDistance)

- (void)updateDistance;
- (NSNumber *)currentDistance;

@end
