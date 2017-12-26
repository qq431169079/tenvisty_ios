//
//  ModifyCameraNameTableViewController.m
//  tenvisty
//
//  Created by Tenvis on 17/11/30.
//  Copyright © 2017年 Tenvis. All rights reserved.
//

#import "ModifyCameraNameTableViewController.h"

@interface ModifyCameraNameTableViewController ()

@end

@implementation ModifyCameraNameTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:  (NSIndexPath*)indexPath
{
    NSString *id = nil;
    TwsTableViewCell *cell = nil;
    
    if(indexPath.row == 0){
        id = TableViewCell_TextField_Disable;
       cell = [tableView dequeueReusableCellWithIdentifier:id forIndexPath:indexPath];
        cell.title = LOCALSTR(@"UID");
        cell.value = self.camera.uid;
    }
    else if(indexPath.row == 1){
        id = TableViewCell_TextField_Normal;
        cell = [tableView dequeueReusableCellWithIdentifier:id forIndexPath:indexPath];
        cell.title = LOCALSTR(@"Name");
        cell.value = self.camera.nickName;
    }
    
    return cell;
}
- (IBAction)save:(id)sender {
    NSString *nickName = [self getRowCell:1].value;
    // 用于过滤空格和Tab换行符
    NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    nickName = [nickName stringByTrimmingCharactersInSet:characterSet];
    if(nickName.length ==0){
        [TwsTools presentAlertMsg:self message:LOCALSTR(@"[Camera name] must be entered.")];
        return;
    }
    self.camera.nickName = nickName;
    [GBase editCamera:self.camera];
    [self.navigationController popViewControllerAnimated:YES];
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
