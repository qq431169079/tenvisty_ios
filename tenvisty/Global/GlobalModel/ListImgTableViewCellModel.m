//
//  ListImgTableViewCellModel.m
//  tenvisty
//
//  Created by Tenvis on 17/12/5.
//  Copyright © 2017年 Tenvis. All rights reserved.
//

#import "ListImgTableViewCellModel.h"

@implementation ListImgTableViewCellModel

+(ListImgTableViewCellModel*) initObj:(NSString *)titleImge title:(NSString *)titleTxt loadingTxt:(NSString *)loadingTxt value:(NSString *)value{
    ListImgTableViewCellModel *model = [[ListImgTableViewCellModel alloc] init];
    model.titleImgName = titleImge;
    model.titleText = titleTxt;
    model.loadingText = loadingTxt;
    model.titleValue = value;
    return model;
}


+(ListImgTableViewCellModel*) initObj:(NSString *)titleImge title:(NSString *)titleTxt loadingTxt:(NSString *)loadingTxt value:(NSString *)value viewId:(NSString *)vid{
    ListImgTableViewCellModel *model = [[ListImgTableViewCellModel alloc] init];
    model.titleImgName = titleImge;
    model.titleText = titleTxt;
    model.loadingText = loadingTxt;
    model.titleValue = value;
    model.viewId = vid;
    return model;
}

@end
