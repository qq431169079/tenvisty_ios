//
//  TimeSettingViewController.m
//  tenvisty
//
//  Created by Tenvis on 17/12/6.
//  Copyright © 2017年 Tenvis. All rights reserved.
//

#import "TimeSettingViewController.h"

@interface TimeSettingViewController ()

@end

@implementation TimeSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 1){
        if(indexPath.row == 0){
            [self performSegueWithIdentifier:@"TimeSetting2TimeZoneSetting" sender:self];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//其他界面返回到此界面调用的方法
- (IBAction)TimeSettingViewController1UnwindSegue:(UIStoryboardSegue *)unwindSegue {
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
