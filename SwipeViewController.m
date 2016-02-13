//
//  SwipeViewController.m
//  Food Swipe
//
//  Created by JS-K on 1/23/16.
//  Copyright © 2016 JS-K. All rights reserved.
//
#import "RevmobAd.h"
#import "SwipeViewController.h"
#import "YelpYapper.h"
#import <AFNetworking.h>
#import "AppDelegate.h"
#import <MDCSwipeToChoose/MDCSwipeToChoose.h>
#import "Restaurant.h"
#import "RestaurantDetailViewController.h"
#import "GluttonNavigationController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <pop/POP.h>
#import "PhotosViewController.h"

// KKK
#import "CategoryViewController.h"

bool IsFromDetailView;

static const CGFloat ChooseRestaurantButtonHorizontalPadding = 80.f;
static const CGFloat ChooseRestaurantButtonVerticalPadding = 20.f;

@interface SwipeViewController () <UIGestureRecognizerDelegate, UIViewControllerPreviewingDelegate>{
    
}
@property (strong, nonatomic) NSMutableArray *restaurants;
@property (strong, nonatomic) MBProgressHUD *loader;
@property (nonatomic) CLLocationCoordinate2D currentLocation;
@property (nonatomic) double furthestDistanceOfLastRestaurant;
@property (strong, nonatomic) UIButton *like;//yes
@property (strong, nonatomic) UIButton *nope;//no


// KKK
@property (strong, nonatomic) NSString *curZipcode;
@property (strong, nonatomic) NSString *curCategoryKey;
@property (strong, nonatomic) NSString *curCategoryTitle;
@property (strong, nonatomic) NSString *curDishe;

@property (strong, nonatomic) NSString *fromCategory;

//@property (strong, nonatomic) UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *lblMatches;
@property (weak, nonatomic) IBOutlet UIImageView *imgBlankCard;
@property (weak, nonatomic) IBOutlet UILabel *lblDistance;

@end

@implementation SwipeViewController

#pragma mark - UIViewController Overrides

//- (void) viewWillDisappear:(BOOL)animated{
//    // swipedRestaurants save to seenRestaurantDic
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    NSMutableArray *restaruantDict = [[defaults objectForKey:@"seendictionary"] mutableCopy];
//    
//    if (_swipedRestaurants) {
//        for (NSDictionary *swiped_one in _swipedRestaurants) {
//            if (restaruantDict) {
//                [restaruantDict addObject:swiped_one];
//            }else{
//                restaruantDict = [NSMutableArray arrayWithObject:swiped_one];
//            }
//        }
//        [defaults setObject:restaruantDict forKey:@"seendictionary"];
//        [defaults synchronize];
//        if (_swipedRestaurants) {
//            [_swipedRestaurants removeAllObjects];
//            _swipedRestaurants = nil;
//        }
//    }
//    sleep(2);
//    [super viewWillDisappear:YES];
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.lblMatches.hidden = YES;
    self.imgBlankCard.hidden = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //this window do not refresh when returned from detail window
    if (IsFromDetailView) {
        IsFromDetailView = false;
        return;
    }
   
    if (self.frontCardView) {
        [self.frontCardView removeFromSuperview];
    }
    if (self.backCardView) {
        [self.backCardView removeFromSuperview];
    }


   
    NSString *categoryTitle = [defaults objectForKey:@"categoryTitle"];
    NSString *categoryKey = [defaults objectForKey:@"categoryKey"];
    NSString *zipCode = [defaults objectForKey:@"default_zipcode"];
    NSString *sel_Dishe = [defaults objectForKey:@"sel_dishi"];
    
    // zipCode and category get
    _curZipcode = [defaults objectForKey:@"currentzipcode"];
    _curCategoryKey = [defaults objectForKey:@"currentcategoryKey"];
    _curCategoryTitle = [defaults objectForKey:@"currentcategoryTitle"];
    _curDishe = [defaults objectForKey:@"currentdishi"];
  
    _fromCategory = [defaults objectForKey:@"from_category"];
    
    self.loader = [MBProgressHUD showHUDAddedTo:self.navigationController.view  animated:YES];
    self.loader.labelText = @"Please wait a moment to gather data";
    self.loader.labelFont = [UIFont fontWithName:@"Bariol-Bold" size:[UIFont systemFontSize]];
    
    if ([_fromCategory isEqualToString:@"1"]) { // from category window
        
        if ([zipCode isEqualToString:_curZipcode] && [categoryKey isEqualToString:_curCategoryKey]) {
            // Old Data
            NSArray *potentialUnswiped = [defaults objectForKey:@"unswiped"];
            NSArray *alreadySwiped = [defaults objectForKey:@"swiped"];
            
            
            if (potentialUnswiped) {
                self.restaurants = [[NSMutableArray alloc] init];
                for (NSDictionary *r in potentialUnswiped) {
                    if (!alreadySwiped || [alreadySwiped indexOfObject:[r objectForKey:@"id"]] == NSNotFound){
                        [self.restaurants addObject:[Restaurant deserialize:r]];
                    }
                }
                [self presentInitialCards];
            }
            [self.loader hide:YES];
            self.title = categoryTitle;
        }else{
            // New data (Search)
            _curZipcode = zipCode;
            
            if (categoryKey == nil) { //clicked category no
                NSDictionary *categoryDic = [defaults objectForKey:@"default_categorys"];
                NSArray *orderedKeys = [categoryDic keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2){
                    return [obj1 compare:obj2];
                }];
                if(orderedKeys == nil){ // No category, current data display
                    NSArray *potentialUnswiped = [defaults objectForKey:@"unswiped"];
                    NSArray *alreadySwiped = [defaults objectForKey:@"swiped"];
                    
                    if (potentialUnswiped) {
                        self.restaurants = [[NSMutableArray alloc] init];
                        for (NSDictionary *r in potentialUnswiped) {
                            if (!alreadySwiped || [alreadySwiped indexOfObject:[r objectForKey:@"id"]] == NSNotFound){
                                [self.restaurants addObject:[Restaurant deserialize:r]];
                            }
                        }
                        [self presentInitialCards];
                    }
                    self.title = _curCategoryTitle;
                }
                [self.loader hide:YES];
            }else{
                _curCategoryKey = categoryKey;
                _curCategoryTitle = categoryTitle;
                
                // save
                [defaults setObject:_curCategoryKey forKey:@"currentcategoryKey"];
                [defaults setObject:_curCategoryTitle forKey:@"currentcategoryTitle"];
                [defaults setObject:_curZipcode forKey:@"currentzipcode"];
                
                self.title = _curCategoryTitle;
                [self getBusinesses]; // data search
            }
        }
    }else{ // from dishi window
        if ([zipCode isEqualToString:_curZipcode] && [sel_Dishe isEqualToString:_curDishe]) {
            // Old Data
            NSArray *potentialUnswiped = [defaults objectForKey:@"unswiped"];
            NSArray *alreadySwiped = [defaults objectForKey:@"swiped"];
            
            
            if (potentialUnswiped) {
                self.restaurants = [[NSMutableArray alloc] init];
                for (NSDictionary *r in potentialUnswiped) {
                    if (!alreadySwiped || [alreadySwiped indexOfObject:[r objectForKey:@"id"]] == NSNotFound){
                        [self.restaurants addObject:[Restaurant deserialize:r]];
                    }
                }
                [self presentInitialCards];
            }
            [self.loader hide:YES];
            self.title = sel_Dishe;
        }else{
            // New data (Search)
            _curZipcode = zipCode;
            
            if (sel_Dishe == nil) { //clicked sel_Dishe no
                sel_Dishe = @"BURGERS";
            }
            _curDishe = sel_Dishe;
            
            // save
            [defaults setObject:_curDishe forKey:@"currentdishi"];
            [defaults setObject:_curZipcode forKey:@"currentzipcode"];
                
            self.title = _curDishe;
            
            [self getBusinesses]; // data search
            
        }
    }

    [self check3DTouch];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [MyRevMobAds ShowRevmobAd:self.view hFromBottom: self.tabBarController.tabBar.frame.size.height];

    self.imgBlankCard.layer.masksToBounds = YES;
    self.imgBlankCard.layer.cornerRadius = 15.0;
    self.imgBlankCard.clipsToBounds = YES;
    
    IsFromDetailView = false;
    
    self->locationManager = [[CLLocationManager alloc] init];
    self->locationManager.delegate = self;
    self->locationManager.distanceFilter = kCLDistanceFilterNone;
    self->locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self->locationManager startUpdatingLocation];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [self->locationManager requestWhenInUseAuthorization];
    }
    
    self.currentLocation = [self->locationManager location].coordinate;
    
    [self->locationManager stopUpdatingLocation];
    
   
    [self constructNopeButton];
    [self constructLikedButton];
    [self.view bringSubviewToFront:self.frontCardView];
}


#pragma mark - MDCSwipeToChooseDelegate Protocol Methods

- (void)viewDidCancelSwipe:(UIView *)view {
}



- (void)view:(UIView *)view wasChosenWithDirection:(MDCSwipeDirection)direction {
 
    

        if (direction == MDCSwipeDirectionLeft) {
            
        } else {
            
            AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableArray *array = [NSMutableArray arrayWithArray:delegate.toRate];
            if ([array count]) {
                [array insertObject:self.currentRestaurant atIndex:0];
                [delegate setToRate:array];
            }
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *seen = [NSMutableArray arrayWithArray:[defaults objectForKey:@"swiped"]];
            if (self.currentRestaurant.id &&(!seen || [seen indexOfObject:self.currentRestaurant.id] == NSNotFound)){
                [defaults setInteger:[defaults integerForKey:@"swipeCount"] + 1 forKey:@"swipeCount"];
               // potential issue here
                 if (seen) {
                    [seen addObject:self.currentRestaurant.id];
                } else {
                    seen = [NSMutableArray arrayWithObject:self.currentRestaurant.id];
                }
                [defaults setObject:seen forKey:@"swiped"];
                [defaults synchronize];
                

                UITabBarItem *collectionTab = [self.tabBarController.tabBar.items objectAtIndex:2];
                if (!collectionTab.badgeValue) {
                    [collectionTab setBadgeValue:@"1"];
                } else {
                    long badgeValue = [[collectionTab badgeValue] integerValue];
                    [collectionTab setBadgeValue:[NSString stringWithFormat:@"%lu", badgeValue+1]];
                }
                //==========================================================================================
                NSMutableArray *restaruantDict = [[defaults objectForKey:@"seendictionary"] mutableCopy];
                // Have to do this for NSUserDefaults 🙍🏾
                self.currentRestaurant.curDate = [NSDate date]; // date Set
                if (restaruantDict) {
                    [restaruantDict addObject:[Restaurant serialize:self.currentRestaurant]];
                } else {
                    restaruantDict = [NSMutableArray arrayWithObject:[Restaurant serialize:self.currentRestaurant]];
                }
                [defaults setObject:restaruantDict forKey:@"seendictionary"];
                [defaults synchronize];
            }
                
        }
    if (!self.backCardView) {
        self.lblMatches.hidden = NO;
        self.imgBlankCard.hidden = NO;
    }
    self.frontCardView = self.backCardView;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentDetail:)];
    tap.delegate = self;
    [self.frontCardView addGestureRecognizer:tap];
    [self.frontCardView setUserInteractionEnabled:YES];
    [self.view bringSubviewToFront:self.frontCardView];
    [self check3DTouch];
    if ((self.backCardView = [self popPersonViewWithFrame:[self backCardViewFrame]])) {
        self.backCardView.alpha = 0.f;
        [self.view insertSubview:self.backCardView belowSubview:self.frontCardView];
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.backCardView.alpha = 1.f;
        } completion:nil];
        [self.backCardView setUserInteractionEnabled:NO];
    }
    
    
}

#pragma mark - Internal Methods

- (void)setFrontCardView:(ChooseRestaurantView *)frontCardView {
    _frontCardView = frontCardView;
    self.currentRestaurant = frontCardView.restaurant;
    
    NSDictionary *coordinate = [self.currentRestaurant.location objectForKey:@"coordinate"];
//    CLLocationCoordinate2D posRestaurant = CLLocationCoordinate2DMake([[coordinate objectForKey:@"latitude"] floatValue], [[coordinate objectForKey:@"longitude"] floatValue]);
    //    CLLocationCoordinate2D posMyPhone = self.currentLocation;
    
    CLLocation *A = [[CLLocation alloc] initWithLatitude:[[coordinate objectForKey:@"latitude"] floatValue] longitude:[[coordinate objectForKey:@"longitude"] floatValue]];
    CLLocation *B;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *curZipcode = [defaults objectForKey:@"currentzipcode"];
    if (![curZipcode isEqualToString:@"local"]) {
        CLLocationCoordinate2D zipLocation = [self getLocationFromAddressString:curZipcode];
        B = [[CLLocation alloc] initWithLatitude:zipLocation.latitude longitude:zipLocation.longitude];
    }
    else{
        B = [[CLLocation alloc] initWithLatitude:self.currentLocation.latitude longitude:self.currentLocation.longitude];
    }
    CLLocationDistance distance = [A distanceFromLocation:B];

    if(frontCardView)
    {
        self.lblDistance.text = [[NSString alloc]initWithFormat:@"%.1f \r\nMiles", distance*0.000621371] ;  //miles
    }else
        self.lblDistance.text = @"";
}


-(CLLocationCoordinate2D) getLocationFromAddressString:(NSString*) addressStr {
    
    double latitude = 0, longitude = 0;
    NSString *esc_addr =  [addressStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *req = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?sensor=false&address=%@", esc_addr];
    NSString *result = [NSString stringWithContentsOfURL:[NSURL URLWithString:req] encoding:NSUTF8StringEncoding error:NULL];
    if (result) {
        NSScanner *scanner = [NSScanner scannerWithString:result];
        if ([scanner scanUpToString:@"\"lat\" :" intoString:nil] && [scanner scanString:@"\"lat\" :" intoString:nil]) {
            [scanner scanDouble:&latitude];
            if ([scanner scanUpToString:@"\"lng\" :" intoString:nil] && [scanner scanString:@"\"lng\" :" intoString:nil]) {
                [scanner scanDouble:&longitude];
            }
        }
    }
    CLLocationCoordinate2D center;
    center.latitude = latitude;
    center.longitude = longitude;
    return center;
    
}
//====================================================================================

- (ChooseRestaurantView *)popPersonViewWithFrame:(CGRect)frame {
    //AAAHAHAAHAHAAAAAAAA
    if (![self.restaurants count]) {
        return nil;
    }
    MDCSwipeToChooseViewOptions *options = [MDCSwipeToChooseViewOptions new];
    //options.likedText = @"Rate";
    //options.nopeText = @"Nah";
    options.likedText = @"Yes";
    options.nopeText = @"No";
    options.delegate = self;
    options.threshold = 160.f;
    options.onPan = ^(MDCPanState *state) {
        CGRect frame = [self backCardViewFrame];
        self.backCardView.frame = CGRectMake(frame.origin.x, frame.origin.y - (state.thresholdRatio * 10.f), CGRectGetWidth(frame), CGRectGetHeight(frame));
    };
    
    ChooseRestaurantView *restaurantView = [[ChooseRestaurantView alloc] initWithFrame:frame restaurant:self.restaurants[0] options:options];
    [self.restaurants removeObjectAtIndex:0];
    return restaurantView;
    
}

#pragma mark - View Construction

- (CGRect)frontCardViewFrame {
    CGFloat horizontalPadding = 20.f;
    CGFloat topPadding = 80.f;
    CGFloat bottomPadding = 280.f;
    return CGRectMake(horizontalPadding, topPadding, CGRectGetWidth(self.view.frame) - (horizontalPadding * 2), CGRectGetHeight(self.view.frame) - bottomPadding);
}

- (CGRect)backCardViewFrame {
    CGRect frontFrame = [self frontCardViewFrame];
    return CGRectMake(frontFrame.origin.x, frontFrame.origin.y + 10.f, CGRectGetWidth(frontFrame), CGRectGetHeight(frontFrame));
}

- (void)constructNopeButton {
    self.nope = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIImage *image = [UIImage imageNamed:@"nope2"];
    self.nope.frame = CGRectMake(ChooseRestaurantButtonHorizontalPadding,
                              CGRectGetMaxY([self backCardViewFrame]) + ChooseRestaurantButtonVerticalPadding,
                              image.size.width,
                              image.size.height);
    [self.nope setImage:image forState:UIControlStateNormal];
    [self.nope setTintColor:[UIColor colorWithRed:247.f/255.f
                                         green:91.f/255.f
                                          blue:37.f/255.f
                                         alpha:1.f]];
    [self.nope addTarget:self
               action:@selector(nopeFrontCardView)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nope];
}



- (void)constructLikedButton {
    self.like = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIImage *image = [UIImage imageNamed:@"like2"];
    self.like.frame = CGRectMake(CGRectGetMaxX(self.view.frame) - image.size.width - ChooseRestaurantButtonHorizontalPadding, CGRectGetMaxY([self backCardViewFrame]) + ChooseRestaurantButtonVerticalPadding, image.size.width, image.size.height);
    [self.like setImage:image forState:UIControlStateNormal];
    [self.like setTintColor:[UIColor colorWithRed:29.f/255.f green:245.f/255.f blue:106.f/255.f alpha:1.f]];
    [self.like addTarget:self action:@selector(likeFrontCardView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.like];
}

#pragma mark Control Events

- (void)nopeFrontCardView {
    POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
    spring.velocity = [NSValue valueWithCGPoint:CGPointMake(3, 3)];
    spring.springBounciness = 30.f;
    [self.nope pop_addAnimation:spring forKey:@"springNope"];
    [self.frontCardView mdc_swipe:MDCSwipeDirectionLeft];
}

- (void)likeFrontCardView {
    POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
    spring.velocity = [NSValue valueWithCGPoint:CGPointMake(3, 3)];
    spring.springBounciness = 30.f;
    [self.like pop_addAnimation:spring forKey:@"springLike"];
    [self.frontCardView mdc_swipe:MDCSwipeDirectionRight];
}

#pragma mark Network Calls and Objectification

- (void)presentInitialCards {
    self.frontCardView = [self popPersonViewWithFrame:[self frontCardViewFrame]];
    self.frontCardView.alpha = 0.0;
    [self.view addSubview:self.frontCardView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentDetail:)];
    tap.delegate = self;
    [self.frontCardView addGestureRecognizer:tap];
    
    
    
    self.backCardView = [self popPersonViewWithFrame:[self backCardViewFrame]];
    self.backCardView.alpha = 0.0;
    [self.view insertSubview:self.backCardView belowSubview:self.frontCardView];
    
    // Don't let the user mess with this card!
    [self.backCardView setUserInteractionEnabled:NO];
    
    [UIView animateWithDuration:1.0 animations:^{
        self.frontCardView.alpha = 1.0;
    }];
    
    [UIView animateWithDuration:1.0
                          delay:1.0
                        options:0
                     animations:^{
                         self.backCardView.alpha = 1.0;
                     }
                     completion:nil];
    
    
    if(!self.frontCardView)
    {
        self.lblMatches.hidden = NO;
        self.imgBlankCard.hidden = NO;
    }
}

- (void)presentDetail:(UITapGestureRecognizer *)gestureRecognizer {

    PhotosViewController *detail = [self.storyboard instantiateViewControllerWithIdentifier:@"photos"];
    [detail setRestaurant:self.currentRestaurant];
//    [detail setSegueIdentifierUsed:@"cardDetail"];
    [self.navigationController pushViewController:detail animated:YES];
}

static int iGetObjects = 0;
static int iGetMaxSwipeResults = 20;
- (void)getBusinesses {
    
    iGetObjects = 0;
    
    NSNumber *swipeResults = [searchOptions objectForKey:@"swiperesults"];
    iGetMaxSwipeResults = swipeResults.intValue;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[manager HTTPRequestOperationWithRequest:[YelpYapper searchRequest:self.currentLocation withOffset:0] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([[responseObject objectForKey:@"total"] unsignedLongValue] < iGetMaxSwipeResults) {
            iGetMaxSwipeResults = (int) [[responseObject objectForKey:@"total"] unsignedLongValue];
        }
        
        NSMutableArray *array = [[NSMutableArray alloc] init];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *alreadySwiped = [defaults objectForKey:@"swiped"];
        iGetObjects = 0;
        for(NSDictionary *r in [responseObject objectForKey:@"businesses"]) {
            iGetObjects++;
            if (!alreadySwiped || [alreadySwiped indexOfObject:[r objectForKey:@"id"]] == NSNotFound) {
                Restaurant *temp = [[Restaurant alloc] initWithId:[r objectForKey:@"id"]
                                                             name:[r objectForKey:@"name"]
                                                       categories:[r objectForKey:@"categories"]
                                                            phone:[r objectForKey:@"phone"]
                                                         imageURL:[r objectForKey:@"image_url"]
                                                         location:[r objectForKey:@"location"]
                                                           rating:[[r objectForKey:@"rating"] stringValue]
                                                        ratingURL:[r objectForKey:@"rating_img_url_large"]
                                                      reviewCount:[r objectForKey:@"review_count"]
                                                  snippetImageURL:[r objectForKey:@"snippet_image_url"]
                                                          snippet:[r objectForKey:@"snippet_text"]
                                                          curDate:nil
                                                        isSeenDic:@0
                                                        isChecked:@0];
                [array addObject:temp];
            }
        }
        if (self.restaurants) {
            [self.restaurants removeAllObjects];
            self.restaurants = nil;
        }
        self.restaurants = [[NSMutableArray alloc] initWithArray:array];
        
        if (iGetMaxSwipeResults > iGetObjects) {
            [self getRestOfBusinesses:[self.restaurants count]];
        } else {
            [self saveState];
            [self presentInitialCards];
            [self.loader hide:YES];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        [self.loader hide:YES];
        //UIAlertView to let them know that something happened with the network connection...
    }] start];
}

- (void)getRestOfBusinesses:(long)offset {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[manager HTTPRequestOperationWithRequest:[YelpYapper searchRequest:self.currentLocation withOffset:offset] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%lu more restaurants found!", [[responseObject objectForKey:@"businesses"] count]);
        
        NSMutableArray *array = [[NSMutableArray alloc] init];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *alreadySwiped = [defaults objectForKey:@"swiped"];
        
        for(NSDictionary *r in [responseObject objectForKey:@"businesses"]) {
            iGetObjects++;
            if (!alreadySwiped || [alreadySwiped indexOfObject:[r objectForKey:@"id"]] == NSNotFound) {
                Restaurant *temp = [[Restaurant alloc] initWithId:[r objectForKey:@"id"]
                                                             name:[r objectForKey:@"name"]
                                                       categories:[r objectForKey:@"categories"]
                                                            phone:[r objectForKey:@"phone"]
                                                         imageURL:[r objectForKey:@"image_url"]
                                                         location:[r objectForKey:@"location"]
                                                           rating:[[r objectForKey:@"rating"] stringValue]
                                                        ratingURL:[r objectForKey:@"rating_img_url_large"]
                                                      reviewCount:[r objectForKey:@"review_count"]
                                                  snippetImageURL:[r objectForKey:@"snippet_image_url"]
                                                          snippet:[r objectForKey:@"snippet_text"]
                                                          curDate:nil
                                                        isSeenDic:@0
                                                        isChecked:@0];
                [array addObject:temp];
                if (iGetMaxSwipeResults <= iGetObjects) {
                    break;
                }
            }
        }
        self.restaurants = [[self.restaurants arrayByAddingObjectsFromArray:[array copy]] mutableCopy];
        
        self.furthestDistanceOfLastRestaurant = [[[[responseObject objectForKey:@"businesses"] lastObject] objectForKey:@"distance"] floatValue];
        NSLog(@"Furthest restaurant is %f meters away from current location", self.furthestDistanceOfLastRestaurant);
        
        if (iGetMaxSwipeResults > iGetObjects) {
            [self getRestOfBusinesses:[self.restaurants count]];
        } else {
            [self saveState];
            [self presentInitialCards];
            [self.loader hide:YES];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        [self.loader hide:YES];
        [self saveState];
        //UIAlertView to let them know that something happened with the network connection...
    }] start];
}

- (void)saveState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"save state being called");
    if (self.restaurants) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (Restaurant *r in self.restaurants) {
            [array addObject:[Restaurant serialize:r]];
        }
        [defaults setObject:[array copy] forKey:@"unswiped"];
    } else {
        [defaults removeObjectForKey:@"unswiped"];
    }
    [defaults synchronize];
}

//- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
//    if ([self.presentedViewController isKindOfClass:[RestaurantDetailViewController class]]) {
//        return nil;
//    }
//    RestaurantDetailViewController *detail = [self.storyboard instantiateViewControllerWithIdentifier:@"restaurantDetail"];
//    [detail setRestaurant:self.currentRestaurant];
//    [detail setSegueIdentifierUsed:@"cardDetail"];
//    return detail;
//}
//
//- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
//    RestaurantDetailViewController *detail = [self.storyboard instantiateViewControllerWithIdentifier:@"restaurantDetail"];
//    [detail setRestaurant:self.currentRestaurant];
//    [detail setSegueIdentifierUsed:@"cardDetail"];
//    
//    [self showViewController:detail sender:self];
//}

- (void)check3DTouch {
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        [self registerForPreviewingWithDelegate:(id)self sourceView:self.frontCardView];
    }
}

- (IBAction)OnMyFoodZone:(id)sender {
    [self.tabBarController setSelectedIndex:2];
}


- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
 
    
    if ([self.presentedViewController isKindOfClass:[RestaurantDetailViewController class]]) {
        return nil;
    }
    RestaurantDetailViewController *detail = [self.storyboard instantiateViewControllerWithIdentifier:@"restaurantDetail"];
    [detail setRestaurant:self.currentRestaurant];
    [detail setSegueIdentifierUsed:@"cardDetail"];
    
    return self;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    RestaurantDetailViewController *detail = [self.storyboard instantiateViewControllerWithIdentifier:@"restaurantDetail"];
    [detail setRestaurant:self.currentRestaurant];
    [detail setSegueIdentifierUsed:@"cardDetail"];
    
    [self showViewController:detail sender:self];
}
@end
