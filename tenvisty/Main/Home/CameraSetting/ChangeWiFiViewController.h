//
//  ChangeWiFiViewController.h
//  tenvisty
//
//  Created by Tenvis on 17/12/5.
//  Copyright © 2017年 Tenvis. All rights reserved.
//

#import "BaseTableViewController.h"

@interface ChangeWiFiViewController : BaseTableViewController

@property (nonatomic,strong) NSString *wifiSsid;
@property (nonatomic,assign) char wifiEnctype;
@property (nonatomic,assign) char wifiMode;


@end
