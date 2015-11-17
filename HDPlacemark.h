//
//  HDLocation.h
//  SheQuan
//
//  Created by Dawn on 2015/11/17.
//  Copyright © 2015年 www.whosv.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface HDPlacemark : NSObject

@property (strong, nonatomic) CLLocation *location; // 坐标最先获得，所以有可能跟地标不一致；地标、坐标不一致时，以坐标为准

@property (copy, nonatomic) NSString *address; // 地址
@property (copy, nonatomic) NSString *country; // 国家
@property (copy, nonatomic) NSString *locality; // 省份 或者 直辖市
@property (copy, nonatomic) NSString *subLocality; // 省份的地级市 或者 直辖市的地区

@end
