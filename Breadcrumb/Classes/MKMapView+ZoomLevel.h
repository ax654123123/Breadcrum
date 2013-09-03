//
// http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/
//

#import <MapKit/MapKit.h>
#define MAP_LEVEL_EXCHANGE 3

@interface MKMapView (ZoomLevel)

@property (nonatomic, assign) NSUInteger zoomLevel;
@property (nonatomic, assign) NSUInteger baiduZoomLevel;

- (void)setZoomLevel:(NSUInteger)zoomLevel
            animated:(BOOL)animated;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;

- (CLLocationDistance)distanceBetweenCGPointA:(CGPoint)a CGPointB:(CGPoint)b;
- (CLLocationDistance)distanceOfCurrentViewFromTopToEnd;

@end
