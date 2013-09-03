//
//  BigMapAnnotation.h
//  HaoZu
//
//  Created by zhengpeng on 11-9-2.
//  Copyright 2011年 anjuke. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface BigMapAnnotation : NSObject <MKAnnotation>
{
    CLLocationCoordinate2D _coordinate;
}
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *commId;
@property (nonatomic, copy) NSString *commName;
@property (nonatomic, copy) NSString *propCount;
@property (nonatomic, copy) NSString *commPrice;
@property (nonatomic) BOOL iskeywordLocated;
@property (nonatomic) BOOL isSelected;
@property (nonatomic, copy) NSString *commAddress;
@property (nonatomic) BOOL isOldSelected;

-(id)initWithCoor:(CLLocationCoordinate2D)coor;
@end
