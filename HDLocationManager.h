//
//  HDLocationManager.h
//  kissme
//
//  Created by Dawn on 2014/5/28.
//  Copyright (c) 2013 RocMD Information Technology Co.,Ltd. All rights reserved.
//

// 单次定位，持续定位等需要的时候再说
/**-usage:
 - (void)applicationDidBecomeActive:(UIApplication *)application
 {
 // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
 [HDLocationManager startUpdatingLocationByTheUser:NO];
 }
 
 -(void)viewWillAppear:(BOOL)animated{
 [super viewWillAppear:animated];
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locateStatusChanged) name:NOTE_LOCATE_STATUS_CHANGED object:nil];
 }
 
 -(void)viewWillDisappear:(BOOL)animated{
 [super viewWillDisappear:animated];
 [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTE_LOCATE_STATUS_CHANGED object:nil];
 }
 
 -(void)locateStatusChanged{
 switch ([HDLocationManager locationStatus]) {
 case HDLocationStatus_Locating: case HDLocationStatus_LocateSuccessAndReversing:
 {
 // 定位中
 break;
 }
 case HDLocationStatus_LocateFailed: case HDLocationStatus_LocateSuccessButReverseFailed:
 {
 // 定位失败，可以尝试重新定位
 break;
 }
 case HDLocationStatus_LocateSuccessAndReverseSuccess:
 {
 // 定位成功
 break;
 }
 default:
 break;
 }
 }
 */

#import <CoreLocation/CoreLocation.h>
#import "HDPlacemark.h"

#define NOTE_LOCATE_STATUS_CHANGED @"NOTE_LOCATE_STATUS_CHANGED"

typedef NS_ENUM(NSInteger, HDLocationStatus) {
    HDLocationStatus_Locating = 1,
    HDLocationStatus_LocateFailed,
    HDLocationStatus_LocateSuccessAndReversing,
    HDLocationStatus_LocateSuccessButReverseFailed,
    HDLocationStatus_LocateSuccessAndReverseSuccess,
};

/// a singleton
@interface HDLocationManager : NSObject

// 定位分两种，一种是用户要求的定位，一种是APP私自的定位；定位动作返回结果之后自动关闭定位
+ (void)startUpdatingLocationByTheUser:(BOOL)byTheUser;

+ (HDLocationStatus)locationStatus;

// 保存了用户上一次定位的地标数据（含location）
+ (HDPlacemark *)placemark;

@end
