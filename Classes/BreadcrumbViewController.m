

#import "CrumbPath.h"
#import "CrumbPathView.h"
#import "BreadcrumbViewController.h"
#import "DrawLinesView.h"
#import "MKMapView+ZoomLevel.h"
#import "BigMapAnnotation.h"
#import "UIUtil.h"
#import "CommViewController.h"

@interface BreadcrumbViewController()

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) IBOutlet MKMapView *map;

@property (nonatomic, strong) UIBarButtonItem *flipButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) IBOutlet UIView *instructionsView;

@property (nonatomic, strong) CrumbPath *crumbs;
@property (nonatomic, strong) CrumbPathView *crumbView;

@property (nonatomic, strong) IBOutlet UISwitch *toggleBackgroundButton;
@property (nonatomic, strong) IBOutlet UISwitch *toggleNavigationAccuracyButton;
@property (nonatomic, strong) IBOutlet UISwitch *toggleAudioButton;
@property (nonatomic, strong) IBOutlet UISwitch *trackUserButton;
@property (nonatomic, strong) IBOutlet UILabel *trackUserLabel;

@property (atomic, assign) BOOL okToPlaySound;

@property (nonatomic, strong) DrawLinesView *imageView;//绘画层
@property (nonatomic, assign) CGMutablePathRef pathRef;//手指画线的Path
@property (nonatomic, assign) CGPoint locationConverToImage;//存储转换测试位置的CGPoint
@property (strong, nonatomic) NSMutableArray *mutableArraryLat;
@property (strong, nonatomic) NSMutableArray *mutableArraryLog;
@property (strong, nonatomic) CLLocation *loction;
@property (strong, nonatomic) UIButton *leftButton;

@property (nonatomic, assign) BOOL drawEnable;
@property (strong, nonatomic) IBOutlet UIView *downView;
@property (nonatomic, strong) MKPolygon *polygon;
@property (nonatomic, strong) MKPolyline *polyline;

@property (nonatomic, assign) float min_lat;
@property (nonatomic, assign) float max_lat;
@property (nonatomic, assign) float min_lng;
@property (nonatomic, assign) float max_lng;

- (IBAction)toggleBestAccuracy:(id)sender;
- (IBAction)tanchu:(id)sender;
@end




@implementation BreadcrumbViewController
@synthesize imageView = _imageView;
@synthesize pathRef = _pathRef;
@synthesize locationConverToImage = _locationConverToImage;
@synthesize mutableArraryLat = _mutableArraryLat;
@synthesize mutableArraryLog = _mutableArraryLog;
@synthesize polygon = _polygon;
- (UIImageView*)imageView
{
    if (_imageView == nil) {
        _imageView = [[DrawLinesView alloc] initWithFrame:CGRectMake(0, 0, self.map.frame.size.width, self.map.frame.size.height)];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.layer.borderWidth = 4;
        _imageView.layer.borderColor = [UIColor orangeColor].CGColor;
        _imageView.userInteractionEnabled = YES;
        _imageView.delegate =self;
        [self.view addSubview:_imageView];
    }
    return _imageView;
}
- (NSMutableArray*)mutableArraryLat
{
    if (_mutableArraryLat == nil) {
        _mutableArraryLat = [[NSMutableArray alloc] initWithCapacity:0];
        
    }
    return _mutableArraryLat;
}
- (NSMutableArray*)mutableArraryLog
{
    if (_mutableArraryLog == nil) {
        _mutableArraryLog = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _mutableArraryLog;
}
#pragma mark - 开始画线
- (void)loadView
{
    [super loadView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    if (self.leftButton) {
        self.leftButton.hidden = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// initialize our AudioSession -
    // this function has to be called once before calling any other AudioSession functions
	AudioSessionInitialize(NULL, NULL, interruptionListener, NULL);
	
	// set our default audio session state
	[self setSessionActiveWithMixing:NO];
	
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Hero" ofType:@"aiff"]];
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.delegate = self;	// so we know when the sound finishes playing
	
	_okToPlaySound = YES;
	
    // Note: we are using Core Location directly to get the user location updates.
    // We could normally use MKMapView's user location update delegation but this does not work in
    // the background.  Plus we want "kCLLocationAccuracyBestForNavigation" which gives us a better accuracy.
    //
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self; // Tells the location manager to send updates to this object
    
    // By default use the best accuracy setting (kCLLocationAccuracyBest)
	//
	// You mau instead want to use kCLLocationAccuracyBestForNavigation, which is the highest possible
	// accuracy and combine it with additional sensor data.  Note that level of accuracy is intended
	// for use in navigation applications that require precise position information at all times and
	// are intended to be used only while the device is plugged in.
    //
    BOOL navigationAccuracy = [self.toggleNavigationAccuracyButton isOn];
	self.locationManager.desiredAccuracy =
        (navigationAccuracy ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest);
    
    // hide the prefs UI for user tracking mode - if MKMapView is not capable of it
    if (![self.map respondsToSelector:@selector(setUserTrackingMode:animated:)])
    {
        self.trackUserButton.hidden = self.trackUserLabel.hidden = YES;
    }

    [self.locationManager startUpdatingLocation];
    
    // create the container view which we will use for flip animation (centered horizontally)
	_containerView = [[UIView alloc] initWithFrame:self.view.bounds];
	[self.view addSubview:self.containerView];
    CGRect rec = self.map.frame;
    rec.size.height = self.view.frame.size.height - 180;
    self.map.frame = rec;
    [self.containerView addSubview:self.map];
    
    self.downView.frame = CGRectMake(0, self.map.frame.size.height, self.downView.frame.size.width, self.downView.frame.size.height);
    [self.containerView addSubview:self.downView];
    
    // add our custom flip button as the nav bar's custom right view
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    CGRect frame = infoButton.frame;
    frame.size.width = 40.0f;
    infoButton.frame = frame;
	[infoButton addTarget:self action:@selector(flipAction:) forControlEvents:UIControlEventTouchUpInside];
	_flipButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
//	self.navigationItem.rightBarButtonItem = self.flipButton;
	
	// create our done button as the nav bar's custom right view for the flipped view (used later)
	_doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                               target:self
                                                               action:@selector(flipAction:)];
    
    UIButton* lintButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [lintButton setBackgroundImage:[UIImage imageNamed:@"button.png"] forState:UIControlStateNormal];
    [lintButton setTitle:@"画图" forState:UIControlStateNormal];
    [lintButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    lintButton.frame = CGRectMake(0, 20, 60, 40);
    self.leftButton = lintButton;
	[lintButton addTarget:self action:@selector(drawSwitchAction:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:lintButton];
   BreadcrumbAppDelegate* dele = [UIApplication sharedApplication].delegate;
    [dele.window addSubview:lintButton];
//	UIBarButtonItem *lintButtonItem = [[UIBarButtonItem alloc] initWithCustomView:lintButton];
//	self.navigationItem.leftBarButtonItem = lintButtonItem;
    

    
}
- (void)viewDidUnload {
    [self setDownView:nil];
    [self setZuidi:nil];
    [self setZuigui:nil];
    [self setZuiduo:nil];
    [self setZuishao:nil];
    [self setZuilao:nil];
    [self setZuixin:nil];
    [self setPrice:nil];
    [self setLotfangyuan:nil];
    [self setLittlefangyuan:nil];
    [self setGuiprice:nil];
    [self setZhangfuda:nil];
    [self setZhangfuxiao:nil];
    [super viewDidUnload];
}
- (void)dealloc
{
    self.locationManager.delegate = nil;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
#pragma mark - 开始画线
- (void)drawSwitchAction:(id)sender{
    self.drawEnable = !self.drawEnable;
    
    UIButton *button = (UIButton*)sender;
    if (!self.drawEnable) {
        [self.imageView removeFromSuperview];
        self.imageView = nil;
        [button setTitle:@"画图" forState:UIControlStateNormal];
    } else {
        [self imageView];
        [button setTitle:@"地图" forState:UIControlStateNormal];
    }
    if (self.drawEnable) {
        [self.map removeOverlay:self.crumbs];
        [self.map removeOverlay:self.polygon];
        [self.map removeOverlay:self.polyline];
        self.polyline = nil;
        self.polygon = nil;
        NSMutableArray *anns = [self.map.annotations mutableCopy];
        [anns removeObject:self.map.userLocation];
        [self.map removeAnnotations:anns];
        
        //
        [self.mutableArraryLat removeAllObjects];
        [self.mutableArraryLog removeAllObjects];
        
        UIGraphicsBeginImageContext(self.imageView.frame.size);
        
        [self.imageView.image drawInRect:CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height)];
        
        CGContextSetRGBFillColor(UIGraphicsGetCurrentContext(), 50, 79, 133, 1.0); // 设置填充的颜色
        
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor blueColor].CGColor);
        
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 4);

        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 60.0f/255, 130/255.0f, 4/255.0f, 0.55f); //画笔颜色
    }
}
#pragma mark - Actions

// called when the app is moved to the background (user presses the home button) or to the foreground 
//


- (void)switchToBackgroundMode:(BOOL)background
{
    if (background)
    {
        if (!self.toggleBackgroundButton.isOn)
        {
            [self.locationManager stopUpdatingLocation];
            self.locationManager.delegate = nil;
        }
    }
    else
    {
        if (!self.toggleBackgroundButton.isOn)
        {
            self.locationManager.delegate = self;
            [self.locationManager startUpdatingLocation];
        }
    }
}

- (IBAction)toggleBestAccuracy:(id)sender
{
    UISwitch *accuracySwitch = (UISwitch *)sender;
    if (accuracySwitch.isOn)
    {
        // better accuracy
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    }
    else
    {
        // normal accuracy
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
}

- (IBAction)toggleTrackUserHeading:(id)sender
{
    UISwitch *trackHeaderSwitch = (UISwitch *)sender;
    if (trackHeaderSwitch.isOn)
    {
        // track the user (the map follows the user's location and heading)
        [self.map setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:NO];
    }
    else
    {
        [self.map setUserTrackingMode:MKUserTrackingModeNone animated:NO];
    }
}

// called when the user presses the 'i' icon to change the app settings
//
- (void)flipAction:(id)sender
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.75];
	
    // since the user can turn off user tracking by simply moving the map,
    // we want to make sure our UISwitch reflects that change.
    [self.trackUserButton setOn:([self.map userTrackingMode] == MKUserTrackingModeFollowWithHeading ? YES : NO)];
    
	[UIView setAnimationTransition:([self.map superview] ?
									UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
                           forView:self.containerView cache:YES];
	if ([self.instructionsView superview])
	{
		[self.instructionsView removeFromSuperview];
		[self.containerView addSubview:self.map];
	}
	else
	{
		[self.map removeFromSuperview];
		[self.containerView addSubview:self.instructionsView];
	}
	
	[UIView commitAnimations];
	
	// adjust our done/info buttons accordingly
	if ([self.instructionsView superview])
		self.navigationItem.rightBarButtonItem = self.doneButton;
	else
		self.navigationItem.rightBarButtonItem = self.flipButton;
}


#pragma mark - MapKit

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if (newLocation)
    {
        if ([self.toggleAudioButton isOn])
		{
			[self setSessionActiveWithMixing:YES]; // YES == duck if other audio is playing
			[self playSound];
		}
		
		// make sure the old and new coordinates are different
        if ((oldLocation.coordinate.latitude != newLocation.coordinate.latitude) &&
            (oldLocation.coordinate.longitude != newLocation.coordinate.longitude))
        {    
            if (!self.crumbs)
            {
                // This is the first time we're getting a location update, so create
                // the CrumbPath and add it to the map.
                //
//                _crumbs = [[CrumbPath alloc] initWithCenterCoordinate:newLocation.coordinate];
//                [self.map addOverlay:self.crumbs];
//                
//                // On the first location update only, zoom map to user location
                MKCoordinateRegion region = 
					MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
                [self.map setRegion:region animated:YES];
            }
            else
            {
                // This is a subsequent location update.
                // If the crumbs MKOverlay model object determines that the current location has moved
                // far enough from the previous location, use the returned updateRect to redraw just
                // the changed area.
                //
                // note: iPhone 3G will locate you using the triangulation of the cell towers.
                // so you may experience spikes in location data (in small time intervals)
                // due to 3G tower triangulation.
                // 
                MKMapRect updateRect = [self.crumbs addCoordinate:newLocation.coordinate];
                
                if (!MKMapRectIsNull(updateRect))
                {
                    // There is a non null update rect.
                    // Compute the currently visible map zoom scale
                    MKZoomScale currentZoomScale = (CGFloat)(self.map.bounds.size.width / self.map.visibleMapRect.size.width);
                    // Find out the line width at this zoom scale and outset the updateRect by that amount
                    CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                    updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
                    // Ask the overlay view to update just the changed area.
//                    [self.crumbView setNeedsDisplayInMapRect:updateRect];
                }
            }
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        
        MKPolylineView *polylineView = [[MKPolylineView alloc] initWithOverlay:overlay];
        //        polygonView.strokeColor = [UIColor magentaColor];
        polylineView.strokeColor = [UIColor colorWithRed:60/255.0f green:130/255.0f blue:4/255.0f alpha:0.35f];

        polylineView.lineWidth = 120;
        return polylineView;
        
    } else if ([overlay isKindOfClass:MKPolygon.class]) {
        MKPolygonView *polygonView = [[MKPolygonView alloc] initWithOverlay:overlay];
        polygonView.strokeColor = [UIColor colorWithRed:60/255.0f green:130/255.0f blue:4/255.0f alpha:0.55f];
        polygonView.lineWidth = 16;
        polygonView.fillColor = [UIColor colorWithRed:60/255.0f green:130/255.0f blue:4/255.0f alpha:0.35f];
        
        return polygonView;
    } else if ([overlay isKindOfClass:[CrumbPath class]]) {
        self.crumbView = [[CrumbPathView alloc] initWithOverlay:overlay];
        return self.crumbView;
    }
    
    return nil;
}
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    


}
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }
    
//    if ([annotation isKindOfClass:[BigMapAnnotation class]]){
//        BigMapAnnotation *annon = (BigMapAnnotation *)annotation;
//        UILabel *lblPropCount;
//        UILabel *lblPrice;
//        
//        static NSString* AID2 = @"AnnotationIdentifier2";
//        MKAnnotationView *annView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AID2];
//        
//        if(annView == nil)
//        {
//            annView = [[MKAnnotationView alloc] initWithAnnotation:annon reuseIdentifier:AID2];
//            lblPropCount = [UIUtil drawLabelInView:annView Frame:CGRectMake(0, 0, 32, 26) Font:[UIFont systemFontOfSize:12] Text:@"" IsCenter:NO Tag:101];
//            lblPropCount.textAlignment = UITextAlignmentCenter;
//            lblPropCount.textColor = [UIColor whiteColor];
//            lblPropCount.shadowColor = [UIColor blackColor];
//            lblPropCount.shadowOffset = CGSizeMake(0, 1);
//            
//            lblPrice = [UIUtil drawLabelInView:annView Frame:CGRectMake(32, 0, 38, 26) Font:[UIFont systemFontOfSize:12] Text:@"" IsCenter:NO Tag:102];
//            lblPrice.textAlignment = UITextAlignmentCenter;
//            lblPrice.textColor = [UIColor whiteColor];
//            lblPrice.shadowColor = [UIColor blackColor];
//            lblPrice.shadowOffset = CGSizeMake(0, 1);
////
//        }
//
//        
//        return annView;
//        
//    }
    MKPinAnnotationView *newAnnotation = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation1"];
	newAnnotation.pinColor = MKPinAnnotationColorGreen;
	newAnnotation.animatesDrop = NO;
	//canShowCallout: to display the callout view by touch the pin
	newAnnotation.canShowCallout=YES;
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	[button addTarget:self action:@selector(checkButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
	newAnnotation.rightCalloutAccessoryView=button;
    
	return newAnnotation;

}

- (IBAction)tanchu:(id)sender
{
    NSString *str;
    UIButton *button = (UIButton*)sender;
    switch (button.tag) {
        case 0:
            str = [self.dic objectForKey:@"min_price"];
            break;
        case 1:
            str = [self.dic objectForKey:@"max_propCount"];
            break;
        case 2:
            str = [self.dic objectForKey:@"max_sale_price_change"];
            break;
        case 3:
            str = [self.dic objectForKey:@"max_price"];
            break;
        case 4:
            str = [self.dic objectForKey:@"min_propCount"];
            break;
        case 5:
            str = [self.dic objectForKey:@"min_sale_price_change"];
            break;
            
        default:
            break;
    }
    for (BigMapAnnotation *ann in self.map.annotations){
        if (![ann isKindOfClass:[MKUserLocation class]]) {
            if ([ann.commId isEqualToString:str]) {
                [self.map selectAnnotation:ann animated:YES];
            }
        }

    }
   
}

- (void)checkButtonTapped:(id)sender  event:(id)event{
    self.leftButton.hidden = YES;
    CommViewController *comm = [[CommViewController alloc] init];
    [self.navigationController pushViewController:comm animated:YES];
    
    
}
#pragma mark - Audio Support

static void interruptionListener(void *inClientData, UInt32 inInterruption)
{
	NSLog(@"Session interrupted: --- %s ---",
		   inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
}

- (void)setSessionActiveWithMixing:(BOOL)duckIfOtherAudioIsPlaying
{
    UInt32 value = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(value), &value);   
    
    // required if using kAudioSessionCategory_MediaPlayback
    value = YES;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(value), &value);
    
    UInt32 isOtherAudioPlaying = 0;
    UInt32 size = sizeof(isOtherAudioPlaying);
    AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &isOtherAudioPlaying);
    
    if (isOtherAudioPlaying && duckIfOtherAudioIsPlaying)
	{
        AudioSessionSetProperty(kAudioSessionProperty_OtherMixableAudioShouldDuck, sizeof(value), &value); 
    }
    AudioSessionSetActive(YES);
}

- (void)playSound
{
	if (self.audioPlayer && self.okToPlaySound)
    {
        _okToPlaySound = NO;
		[self.audioPlayer prepareToPlay];
		[self.audioPlayer play];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    AudioSessionSetActive(NO);
	_okToPlaySound = YES;
}
#pragma mark - touch事件
- (void)touchBegan:(NSSet *)touches withEvent:(UIEvent *)event
{

    NSLog(@"touchesBegan");
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.imageView];
    
    //创建path
    
    _pathRef=CGPathCreateMutable();
    
    CGPathMoveToPoint(_pathRef, NULL, location.x, location.y);
}
- (void)touchMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesMoved");
    UITouch *touch = [touches anyObject];
    
    CGPoint location = [touch locationInView:self.imageView];
    
    CGPoint pastLocation = [touch previousLocationInView:self.imageView];
    
    //画线
    
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), pastLocation.x, pastLocation.y);
    
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), location.x, location.y);
    
    CGContextDrawPath(UIGraphicsGetCurrentContext(), kCGPathFillStroke);
    
    self.imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    
    //更新Path
    
    CGPathAddLineToPoint(_pathRef, NULL, location.x, location.y);
    
    CLLocationCoordinate2D  ll = [self.map convertPoint:location toCoordinateFromView:self.map];
    NSLog(@"latitude======%f",ll.latitude);
    NSLog(@"longitude======%f",ll.longitude);
    [self.mutableArraryLat addObject:[NSString stringWithFormat:@"%f",ll.latitude]];
    [self.mutableArraryLog addObject:[NSString stringWithFormat:@"%f",ll.longitude]];
    
}
- (void)touchEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesEnded");
    if ([self.mutableArraryLat count] > 0) {
        self.crumbs = nil;
        [self DrawingLineOnMap];
    }else{
        return;
    }

    
    self.drawEnable = NO;
    if (!self.drawEnable) {
        [self.imageView removeFromSuperview];
        self.imageView = nil;
        [self.leftButton setTitle:@"画图" forState:UIControlStateNormal];
    } else {
        [self imageView];
        [self.leftButton setTitle:@"地图" forState:UIControlStateNormal];
    }
    
    [self requestErShouFang];
    
}
#pragma mark - 请求房源数据
- (void)requestErShouFang
{
  
    NSDictionary *params = [self getLatAndLng];

    [[RTRequestProxy sharedInstance] asyncGetWithServiceID:RTAnjukeServiceID methodName:@"community.searchMap" params:params target:self action:@selector(searchXiaoQuFinished:)];
}
- (void)searchXiaoQuFinished:(RTNetworkResponse *)response
{

    if (response.status == RTNetworkResponseStatusSuccess) {
        //DLog(@"searchXiaoQuFinished:%@",response.content);
        
        NSDictionary *resultDic = response.content;
        
        NSLog(@"-%@-", [resultDic objectForKey:@"status"]);
        
        if ([[resultDic objectForKey:@"status"] isEqualToString:@"ok"]) {
            
            if ([[resultDic objectForKey:@"communities"] isKindOfClass:[NSArray class]]) {
                NSArray *xiaoquArray = [resultDic objectForKey:@"communities"];
                if ([xiaoquArray count] == 0) {
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"提示信息"  message:@"所画区域没有小区" delegate:nil cancelButtonTitle:@"确定"  otherButtonTitles:nil,nil];
                    [av show];
                    return;
                }
                NSMutableArray *arrary = [[NSMutableArray alloc] initWithCapacity:0];
                for (NSDictionary *xiaoquInfo in xiaoquArray) {
                    float lat;
                    float lng;
                   lat = [[xiaoquInfo objectForKey:@"lat"] floatValue];
                   lng = [[xiaoquInfo objectForKey:@"lng"] floatValue];
                    if ([self pointInsideOverlay:CLLocationCoordinate2DMake(lat, lng)]) {
                        [arrary addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    [xiaoquInfo objectForKey:@"id"],@"commId",
                                                    [xiaoquInfo objectForKey:@"name"],@"commName",
                                                    [xiaoquInfo objectForKey:@"property_number"],@"propCount",
                                                    [xiaoquInfo objectForKey:@"sale_price"],@"commPrice",
                                                    [xiaoquInfo objectForKey:@"lat"],@"commLat",
                                                    [xiaoquInfo objectForKey:@"lng"],@"commLng",
                                                    [xiaoquInfo objectForKey:@"address"],@"address",
                                                    [xiaoquInfo objectForKey:@"sale_price_change"],@"sale_price_change",
                                                    nil]];
                    }
                }
                
                NSLog(@"--[arrary count]----====%d",[arrary count]);

                if ([arrary count] == 0) {
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"所画区域没有小区" delegate:nil cancelButtonTitle:@"确定"  otherButtonTitles:nil,nil];
                    [av show];
                    return;
                }
                [self tianjiabianzhu:arrary];
                [self shuaixuan:arrary];

                
            }
            else{
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"非常抱歉，获取数据失败" delegate:nil  cancelButtonTitle:@"确定"  otherButtonTitles:nil,nil];
                [av show];
            }
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"非常抱歉，获取数据失败" delegate:nil  cancelButtonTitle:@"确定"  otherButtonTitles:nil,nil];
            [av show];
        }
    }
    else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"网络不给力" delegate:nil  cancelButtonTitle:@"确定"  otherButtonTitles:nil,nil];
        [av show];
    }

}
- (void)tianjiabianzhu:(NSArray*)arrary
{
    //添加标点
    for (NSDictionary *dicCommunity in arrary) {
        NSString *commId = [dicCommunity objectForKey:@"commId"];
        NSString *commName = [dicCommunity objectForKey:@"commName"];
        NSString *commPrice = [dicCommunity objectForKey:@"commPrice"];
        NSString *commProps = [dicCommunity objectForKey:@"propCount"];
        NSString *commAddress = [dicCommunity objectForKey:@"address"];
        CLLocationDegrees commLat = [[dicCommunity objectForKey:@"commLat"] doubleValue];
        CLLocationDegrees commLng = [[dicCommunity objectForKey:@"commLng"] doubleValue];
        CLLocationCoordinate2D location;
        location.latitude = commLat;
        location.longitude = commLng;
        BigMapAnnotation *annotation = [[BigMapAnnotation alloc] initWithCoor:location];
        annotation.title = commName;
        annotation.commId = commId;
        annotation.commName = commName;
        annotation.propCount = commProps;
        annotation.commPrice = commPrice;
        annotation.commAddress = commAddress;
        annotation.isSelected = NO;
        annotation.isOldSelected = NO;
        //添加
        [self.map addAnnotation:annotation];
        
    }
}
- (void)shuaixuan:(NSArray*)arrary
{

    int min_price;
    int max_price;
    int min_propCount;
    int max_propCount;
    float min_sale_price_change;
    float max_sale_price_change;


    for (NSUInteger i = 0; i < [arrary count]; i++) {
        NSDictionary *dicCommunity = [arrary objectAtIndex:i];
            
        NSString *commPrice = [dicCommunity objectForKey:@"commPrice"];
        if (i == 0) {
            min_price = [commPrice intValue];
            max_price = [commPrice intValue];
        }
        
        min_price = [commPrice intValue] < min_price ? [commPrice intValue] : min_price;
        max_price = [commPrice intValue] > max_price ? [commPrice intValue] : max_price;
        
        NSString *commpropCount = [dicCommunity objectForKey:@"propCount"];
        if (i == 0) {
            min_propCount = [commpropCount intValue];
            max_propCount = [commpropCount intValue];
        }
        
        min_propCount = [commpropCount intValue] < min_propCount ? [commpropCount intValue] : min_propCount;
        max_propCount = [commpropCount intValue] > max_propCount ? [commpropCount intValue] : max_propCount;
        NSString *sale_price_change = [dicCommunity objectForKey:@"sale_price_change"];
        if (i == 0) {
            min_sale_price_change = [sale_price_change floatValue];
            max_sale_price_change = [sale_price_change floatValue];
        }
        
        min_sale_price_change = [sale_price_change floatValue] < min_sale_price_change ? [sale_price_change floatValue]: min_sale_price_change;
        max_sale_price_change = [sale_price_change floatValue] > max_sale_price_change ? [sale_price_change floatValue] : max_sale_price_change;
        
        
    }

    

    self.zhangfuda.text = [NSString stringWithFormat:@"%0.3f%@",max_sale_price_change,@"%"];
    self.zhangfuxiao.text = [NSString stringWithFormat:@"%0.3f%@",min_sale_price_change,@"%"];
    

    self.lotfangyuan.text = [NSString stringWithFormat:@"%d套",max_propCount];
    self.littlefangyuan.text = [NSString stringWithFormat:@"%d套",min_propCount];
    

    self.price.text = [NSString stringWithFormat:@"%0.2f万",min_price/10000.0f];
    self.guiprice.text = [NSString stringWithFormat:@"%0.2f万",max_price/10000.0f];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
    for (NSUInteger i = 0; i < [arrary count]; i++) {
        NSDictionary *dicCommunity = [arrary objectAtIndex:i];
                
        NSString *commPrice = [dicCommunity objectForKey:@"commPrice"];
        NSString *commpropCount = [dicCommunity objectForKey:@"propCount"];        
        NSString *sale_price_change = [dicCommunity objectForKey:@"sale_price_change"];
        if ([commPrice intValue] == max_price) {
            [dic setObject:[dicCommunity objectForKey:@"commId"] forKey:@"max_price"];
        }
        if ([commPrice intValue] == min_price) {
            [dic setObject:[dicCommunity objectForKey:@"commId"] forKey:@"min_price"];
        }
        if ([commpropCount intValue] == min_propCount) {
            [dic setObject:[dicCommunity objectForKey:@"commId"] forKey:@"min_propCount"];
        }
        if ([commpropCount intValue] == max_propCount) {
            [dic setObject:[dicCommunity objectForKey:@"commId"] forKey:@"max_propCount"];
        }
        if ([sale_price_change floatValue] == min_sale_price_change) {
            [dic setObject:[dicCommunity objectForKey:@"commId"] forKey:@"min_sale_price_change"];
        }
        if ([sale_price_change floatValue] == max_sale_price_change) {
            [dic setObject:[dicCommunity objectForKey:@"commId"] forKey:@"max_sale_price_change"];
        }
    }
    self.dic = dic;
}
- (NSDictionary *)getLatAndLng
{
    float min_lat;
    float max_lat;
    float min_lng;
    float max_lng;
    
    for (NSUInteger i = 0; i < [self.mutableArraryLat count]; i++) {
        float lat = [[self.mutableArraryLat objectAtIndex:i] floatValue];
        NSLog(@"%f",lat);
        if (i == 0) {
            max_lat = lat;
            min_lat = lat;
        }

        min_lat = lat < min_lat ? lat : min_lat;
        max_lat = lat > max_lat ? lat : max_lat;
    }
    for (NSUInteger i = 0; i < [self.mutableArraryLog count]; i++) {
        
        float lng = [[self.mutableArraryLog objectAtIndex:i] floatValue];
        NSLog(@"%f",lng);
        if (i == 0) {
            min_lng = lng;
            max_lng = lng;
        }
        max_lng = lng > max_lng ? lng : max_lng;
        min_lng = lng < min_lng ? lng : min_lng;
    }
    
    NSLog(@"%f ---------  %f ",min_lat,max_lat);
    NSLog(@"%f ---------  %f ",min_lng,max_lng);

    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%f",min_lat],@"min_lat",
                            [NSString stringWithFormat:@"%f",min_lng],@"min_lng",
                            [NSString stringWithFormat:@"%f",max_lat],@"max_lat",
                            [NSString stringWithFormat:@"%f",max_lng],@"max_lng",
                            @"google",@"map_type",
                            @"1",@"page",
                            @"200",@"page_size",
                            @"11",@"city_id",nil];

    return params;

}

#pragma mark - 处理map画线事件
- (CGFloat)CalculatingTheDistance
{
    float min_lat ;
    float min_lng ;
    float max_lat ;
    float max_lng ;
    CLLocationCoordinate2D  min;
    CLLocationCoordinate2D  max;
    float distance;
    
    min_lat = [[self.mutableArraryLat objectAtIndex:0] floatValue];
    min_lng = [[self.mutableArraryLog objectAtIndex:0] floatValue];
    max_lat = [[self.mutableArraryLat lastObject] floatValue];
    max_lng= [[self.mutableArraryLog lastObject] floatValue];
    
    min.latitude = min_lat;
    min.longitude = min_lng;
    
    max.latitude = max_lat;
    max.longitude = max_lng;
    
    
    distance  = [self distanceFromPointX:[self.map convertCoordinate:min toPointToView:self.imageView] distanceToPointY:[self.map convertCoordinate:max toPointToView:self.imageView]];

    NSLog(@"Distance is %f",distance);

    return distance;
    
////    if (distance < 50) {
//        BreadcrumbAppDelegate *delegate = [UIApplication sharedApplication].delegate;
//        delegate.isBiHe = YES;
//        self.crumbs = [[CrumbPath alloc] initWithCenterCoordinate:CLLocationCoordinate2DMake([[self.mutableArraryLat lastObject] floatValue], [[self.mutableArraryLog lastObject] floatValue])];
////    }else{
////        BreadcrumbAppDelegate *delegate = [UIApplication sharedApplication].delegate;
////        delegate.isBiHe = NO;
////        self.crumbs = [[CrumbPath alloc] initWithCenterCoordinate:CLLocationCoordinate2DMake([[self.mutableArraryLat objectAtIndex:0] floatValue], [[self.mutableArraryLog objectAtIndex:0] floatValue])];
////    }
//
}
- (void)DrawingLineOnMap
{
    CGFloat distance = [self CalculatingTheDistance];
    MKMapRect updateRect;
    
    int boundaryPointsCount = self.mutableArraryLat.count;
    CLLocationCoordinate2D *boundary = malloc(sizeof(CLLocationCoordinate2D)*boundaryPointsCount);
    
    self.crumbs = [[CrumbPath alloc] initWithCenterCoordinate:CLLocationCoordinate2DMake([[self.mutableArraryLat objectAtIndex:0] floatValue], [[self.mutableArraryLog objectAtIndex:0] floatValue])];
    for (NSUInteger i = 0; i < [self.mutableArraryLat count]; i++) {
        
        float lat = [[self.mutableArraryLat objectAtIndex:i] floatValue];
        float lng = [[self.mutableArraryLog objectAtIndex:i] floatValue];
        CLLocationCoordinate2D newCoordinate = CLLocationCoordinate2DMake(lat, lng);
        updateRect = [self.crumbs addCoordinate:newCoordinate];
        //        [self.crumbView setNeedsDisplayInMapRect:updateRect];
        boundary[i] = CLLocationCoordinate2DMake(lat,lng);
    }

    if (distance > 70) {    // polyline
        self.polyline = [MKPolyline polylineWithCoordinates:boundary
                                                         count:boundaryPointsCount];
        [self.map addOverlay:self.polyline];
        self.crumbView = nil;
        [self.map addOverlay:self.crumbs];        
    } else {                // polygon
        self.polygon = [MKPolygon polygonWithCoordinates:boundary
                                                         count:boundaryPointsCount];
        [self.map addOverlay:self.polygon];
    }

}

- (float)distanceFromPointX:(CGPoint)start distanceToPointY:(CGPoint)end
{
    
    float distance;
    
    //下面就是高中的数学，
    
    CGFloat xDist = (end.x - start.x);
    
    CGFloat yDist = (end.y - start.y);
    
    distance = sqrt((xDist * xDist) + (yDist * yDist));
    
    return distance;
    
}

-(BOOL)pointInsideOverlay:(CLLocationCoordinate2D )tapPoint
{
    if (self.polygon) {
        MKPolygonView *polygonView = (MKPolygonView *)[self.map viewForOverlay:self.polygon];
        
        MKMapPoint mapPoint = MKMapPointForCoordinate(tapPoint);    
        CGPoint polygonViewPoint = [polygonView pointForMapPoint:mapPoint];
        
        return CGPathContainsPoint(polygonView.path, NULL, polygonViewPoint, NO);
    } else {
        
        CGPoint newCenter = [self.map convertCoordinate:tapPoint toPointToView:self.map];
        
        for (NSUInteger i = 0; i < [self.mutableArraryLat count]; i++) {
            
            float lat = [[self.mutableArraryLat objectAtIndex:i] floatValue];
            float lng = [[self.mutableArraryLog objectAtIndex:i] floatValue];
            CLLocationCoordinate2D newCoordinate = CLLocationCoordinate2DMake(lat, lng);
            CGPoint newPoint = [self.map convertCoordinate:newCoordinate toPointToView:self.map];
            float distance ;
            distance = [self distanceFromPointX:newCenter distanceToPointY:newPoint];
            if (distance < 60) {
                MKPolylineView *polylineView = (MKPolylineView *)[self.map viewForOverlay:self.polyline];
                
                MKMapPoint mapPoint = MKMapPointForCoordinate(tapPoint);
                CGPoint polylineViewPoint = [polylineView pointForMapPoint:mapPoint];
                
                return CGPathContainsPoint(polylineView.path, NULL, polylineViewPoint, NO);
            }return NO;
        }
        
        return NO;
    }
}

@end
