//
//  SwipeViewController.h
//  Food Swipe
//
//  Created by JS-K on 1/23/16.
//  Copyright © 2016 JS-K. All rights reserved.


#import <UIKit/UIKit.h>
#import "ChooseRestaurantView.h"
#import <MDCSwipeToChoose/MDCSwipeToChooseDelegate.h>
#import <CoreLocation/CoreLocation.h>

@interface SwipeViewController : UIViewController <MDCSwipeToChooseDelegate, CLLocationManagerDelegate> {
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) Restaurant *currentRestaurant;
@property (strong, nonatomic) ChooseRestaurantView *frontCardView;
@property (strong, nonatomic) ChooseRestaurantView *backCardView;


- (IBAction)OnMyFoodZone:(id)sender;

extern bool IsFromDetailView;
@end
