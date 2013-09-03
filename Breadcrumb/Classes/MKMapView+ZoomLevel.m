//
// http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/
//


#import "MKMapView+ZoomLevel.h"

static const double MERCATOR_OFFSET = 268435456;
static const double MERCATOR_RADIUS = 85445659.44705395;

@implementation MKMapView (ZoomLevel)

#pragma mark -
#pragma mark Map conversion methods

- (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

- (double)latitudeToPixelSpaceY:(double)latitude
{
    return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

- (double)pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

- (double)pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}

#pragma mark -
#pragma mark Helper methods

- (MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)mapView
                             centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 andZoomLevel:(NSUInteger)zoomLevel
{
    // convert center coordiate to pixel space
    double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];

    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);

    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = mapView.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;

    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);

    // find delta between left and right longitudes
    CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;

    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);

    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}

#pragma mark -
#pragma mark Properties

- (NSUInteger)zoomLevel {
    return 20 - ceil(log2(self.region.span.latitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * self.bounds.size.width)));
}

- (NSUInteger)baiduZoomLevel{
    return [self zoomLevel] + MAP_LEVEL_EXCHANGE;
}

- (void)setBaiduZoomLevel:(NSUInteger)baiduZoomLevel
{
    [self setZoomLevel:baiduZoomLevel - MAP_LEVEL_EXCHANGE];
}

- (void)setZoomLevel:(NSUInteger)zoomLevel {
    if (self.zoomLevel == zoomLevel) {
        return;
    }
    [self setCenterCoordinate:self.centerCoordinate zoomLevel:zoomLevel animated:NO];
}

#pragma mark -
#pragma mark Public methods

- (CLLocationDistance)distanceBetweenCGPointA:(CGPoint)a CGPointB:(CGPoint)b
{
    CLLocationCoordinate2D coA = [self convertPoint:a toCoordinateFromView:self];
    CLLocationCoordinate2D coB = [self convertPoint:b toCoordinateFromView:self];
    CLLocation *clA = [[CLLocation alloc] initWithLatitude:coA.latitude longitude:coA.longitude];
    CLLocation *clB = [[CLLocation alloc] initWithLatitude:coB.latitude longitude:coB.longitude];
    CLLocationDistance dis = [clA distanceFromLocation:clB];
    return dis;
}

- (CLLocationDistance)distanceOfCurrentViewFromTopToEnd
{
    return [self distanceBetweenCGPointA:CGPointMake(0, 0) CGPointB:CGPointMake(0, self.frame.size.height)];
}


- (void)setZoomLevel:(NSUInteger)zoomLevel
            animated:(BOOL)animated {
    if (self.zoomLevel == zoomLevel) {
        return;
    }
    [self setCenterCoordinate:self.centerCoordinate zoomLevel:zoomLevel animated:animated];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated {
    if (!CLLocationCoordinate2DIsValid(centerCoordinate))
        return;
    
    // clamp large numbers to 28
    zoomLevel = MIN(zoomLevel, 28);

    // use the zoom level to compute the region
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
    if ( span.latitudeDelta >= 180
        || span.latitudeDelta <= 0
        || span.longitudeDelta >= 360
        || span.longitudeDelta <= 0)
        return;

    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    [self setRegion:region animated:animated];
}

@end
