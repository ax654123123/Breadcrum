//
//  BigMapAnnotation.m
//  HaoZu
//
//  Created by zhengpeng on 11-9-2.
//  Copyright 2011年 anjuke. All rights reserved.
//

#import "BigMapAnnotation.h"

@implementation BigMapAnnotation

-(id)initWithCoor:(CLLocationCoordinate2D)coor
{
	if(self = [super init])
	{
		_coordinate = coor;
	}
	return self;
}


@end
