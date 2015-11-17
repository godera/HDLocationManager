//
//  HDLocationManager.m
//  kissme
//
//  Created by Dawn on 2014/5/28.
//  Copyright (c) 2013 RocMD Information Technology Co.,Ltd. All rights reserved.
//

#import "HDLocationManager.h"

@interface HDLocationManager ()<CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) BOOL isLocationValid; // 定位一次会收到数次定位信息，只取第一次的数据，随后的丢掉
// output
@property (assign, nonatomic) HDLocationStatus locationStatus;
@property (strong, nonatomic) HDPlacemark *placemark;
@end


@implementation HDLocationManager

+ (HDLocationManager *)singleton{
    static HDLocationManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        CLLocationManager* locationManager = [[CLLocationManager alloc] init];
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = 10.0f;
        locationManager.delegate = self;
        _locationManager = locationManager;
        
        _isLocationValid = YES;
        
        _placemark = [[HDPlacemark alloc] init];
        
    }
    return self;
}

+ (HDLocationStatus)locationStatus{
    return [self singleton].locationStatus;
}

+ (HDPlacemark *)placemark{
    return [self singleton].placemark;
}

+ (void)showOpenLocationMessage {
    UIColor *color = [UIColor whiteColor];
    if ([HDCoreData currentUser].userInfo.userMood.color) {
        color = [UIColor getColor:[HDCoreData currentUser].userInfo.userMood.color];
    }
    [JKAlertView showSQAlertWithTitle:nil message:@"请在‘设置－隐私－定位服务’选项中，允许奢圈访问你的手机定位服务" cancelButtonTitle:@"好" okButtonTitle:nil TiniColor:[CoreDataUpdateMethod sharedMethod].currentMoodColor];
}

// 定位分两种，一种是用户要求的定位，一种是APP私自的定位
+ (void)startUpdatingLocationByTheUser:(BOOL)byTheUser
{
    switch ([CLLocationManager authorizationStatus]) {
        // User has not yet made a choice with regards to this application
        // Ask the user for permission to use location.
        case kCLAuthorizationStatusNotDetermined:
        {
            if ([[self singleton].locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [[self singleton].locationManager requestWhenInUseAuthorization]; // 重复的请求 系统会自动忽略
                return;
            }
            break;
        }
        // This app is not authorized to use location services. The user cannot change this app’s status,
        // possibly due to active restrictions such as parental controls being in place.
        case kCLAuthorizationStatusRestricted: // 不能够授权，例如家长控制等
        {
            if (byTheUser) {
                [self showOpenLocationMessage];
            }
            ErrorLog(@"用户无法授权 APP 使用定位，貌似被家长限制了");
            return;
        }
        // User has explicitly denied authorization for this application, or
        // location services are disabled in Settings.
        case kCLAuthorizationStatusDenied:
        {
            if (byTheUser) {
                [self showOpenLocationMessage];
            }
            ErrorLog(@"用户拒绝 APP 使用定位");
            return;
        }
        // User has granted authorization to use their location at any time,
        // including monitoring for regions, visits, or significant location changes.
        case kCLAuthorizationStatusAuthorizedAlways: // equal to kCLAuthorizationStatusAuthorized
        {
            break;
        }
        // User has granted authorization to use their location only when your app
        // is visible to them (it will be made visible to them if you continue to
        // receive location updates while in the background).  Authorization to use
        // launch APIs has not been granted.
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            // Nothing to do.
            break;
        }
        default:
        break;
    }
    
    // output 1
    [self singleton].locationStatus = HDLocationStatus_Locating;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTE_LOCATE_STATUS_CHANGED object:nil];
    
    [self singleton].isLocationValid = YES;
    [[self singleton].locationManager startUpdatingLocation];
}

+ (void)stopUpdatingLocation{
    [self singleton].isLocationValid = NO;
    [[self singleton].locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate
// 当用户授权之后，APP 会再次 DidBecomeActive，如果在 DidBecomeActive 里调用了 +startUpdatingLocationByTheUser: 方法，
// 此时 didChangeAuthorizationStatus 方法就不需要了
//-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
//    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
//        [HDLocationManager startUpdatingLocationByTheUser:NO];
//    }
//}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    if (_isLocationValid == NO) {
        return;
    }
    [HDLocationManager stopUpdatingLocation];
    
    // output 2
    self.locationStatus = HDLocationStatus_LocateFailed;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTE_LOCATE_STATUS_CHANGED object:nil];
    
    ErrorLog(@"locate error = %@",error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (_isLocationValid == NO) {
        return;
    }
    [HDLocationManager stopUpdatingLocation];
    
    CLLocation* location = [locations firstObject];
    
    // output 3
    self.placemark.location = location;
    self.locationStatus = HDLocationStatus_LocateSuccessAndReversing;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTE_LOCATE_STATUS_CHANGED object:nil];

//    [NetLayer reportUserLocation:location complete:nil];
    
    [[CLGeocoder new] reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error) {
            // output 4
            self.locationStatus = HDLocationStatus_LocateSuccessButReverseFailed;
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTE_LOCATE_STATUS_CHANGED object:nil];
            
            ErrorLog(@"ReverseGeocodeLocation error = %@",error);
            return;
        }
        // output 5
        CLPlacemark* aPlacemark = [placemarks firstObject];
        
        self.placemark.address = [aPlacemark.name deleteSubString:@"中国"];
        
        self.placemark.country = aPlacemark.country;
        
        if (aPlacemark.locality.length > 0) {
            self.placemark.locality = aPlacemark.locality;
        }else{
            self.placemark.locality = aPlacemark.administrativeArea;
        }
        
        if (aPlacemark.subLocality.length > 0) {
            self.placemark.locality = aPlacemark.subLocality;
        }else{
            self.placemark.locality = aPlacemark.subAdministrativeArea;
        }
        
        self.locationStatus = HDLocationStatus_LocateSuccessAndReverseSuccess;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTE_LOCATE_STATUS_CHANGED object:nil];
    }];


}


#pragma mark -

@end
