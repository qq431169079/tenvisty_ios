//
//  AddDeviceWirelessSettingViewController.m
//  tenvisty
//
//  Created by Tenvis on 2017/12/12.
//  Copyright © 2017年 Tenvis. All rights reserved.
//

#define SMART_WIFI_TIME (60)
#define CONFIG_WIFI_FAIL (0)
#define CONFIG_WIFI_SUCCESS (1)
#define CONFIG_WIFI_WRONG_PWD (2)

#import "AddDeviceWirelessSettingViewController.h"
#import "FLAnimatedImage.h"
#import "WiFiConfigContext.h"

@interface AddDeviceWirelessSettingViewController ()<WiFiConfigDelegate>{
    
}
//@property (weak, nonatomic) IBOutlet FLAnimatedImageView *gifView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_left_pop;
@property (weak, nonatomic) IBOutlet UILabel *labProcess;
@property (nonatomic,strong) NSTimer* pTimer;
@property (nonatomic,assign) NSInteger configWifiResult;
@end

@implementation AddDeviceWirelessSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.configWifiResult = CONFIG_WIFI_FAIL;
//    NSURL *url1 = [[NSBundle mainBundle] URLForResource:@"configwifi_setting" withExtension:@"gif"];
//    NSData *data1 = [NSData dataWithContentsOfURL:url1];
//    FLAnimatedImage *animatedImage1 = [FLAnimatedImage animatedImageWithGIFData:data1];
//    self.gifView.animatedImage = animatedImage1;
    self.progressView.progress = .0;
//    CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 2.0f);
//    self.progressView.transform = transform;
    [[WiFiConfigContext sharedInstance] setData:self.uid ssid:self.wifiSsid password:self.wifiPassword auth:self.wifiAuthMode];
    [[WiFiConfigContext sharedInstance] setReceiveListner:self];
    [self setTimerInterval:SMART_WIFI_TIME/100.0f];
    self.camera = [TwsDataValue getTryConnectCamera];
    
    // Do any additional setup after loading the view.
}

-(void)setTimerInterval:(NSTimeInterval)interval{
    if (self.progressView.progress < 1) {
        if(self.pTimer != nil){
            [self.pTimer invalidate];
        }
        self.pTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(progressMethod:) userInfo:nil repeats:YES];
    }
    else{
        [[WiFiConfigContext sharedInstance] stopConfig];
    }
}

- (void)progressMethod : (id)sender {
    self.progressView.progress += 0.01f;
    self.labProcess.text = [NSString stringWithFormat:@"%d%%",(int)(self.progressView.progress*100)];
    self.constraint_left_pop.constant -= self.progressView.frame.size.width / 100.0f;
    if(self.progressView.progress >= 1){
        [[WiFiConfigContext sharedInstance] stopConfig];
        [self.pTimer invalidate];
        if(self.configWifiResult == CONFIG_WIFI_SUCCESS || self.configWifiResult == CONFIG_WIFI_WRONG_PWD){
            if(!self.camera.isConnecting && !self.camera.isSessionConnected){
                if(self.camera.p2pType ==  P2P_Tutk){
                    [self.camera stop];
                }
                [self.camera start];
            }
            
            [self saveCamera];
            [self go2List];
        }
        else{
            [self performSegueWithIdentifier:@"AddDeviceWirelessSetting2AddDeviceWirelessFail" sender:self];
//            [TwsTools presentAlertTitle:self title:nil message:LOCALSTR(@"Configure Wi-Fi failed, please check your Wi-Fi password") alertStyle:UIAlertControllerStyleAlert actionDefaultTitle:LOCALSTR(@"Retry") actionDefaultBlock:^{
//                [self.navigationController popViewControllerAnimated:YES];
//            } actionCancelTitle:LOCALSTR(@"Help") actionCancelBlock:^{
//                [self go2Help];
//            }];
        }
        
    }
    else{
        if(self.configWifiResult == CONFIG_WIFI_FAIL){
            if(self.camera.isDisconnect){
                [self.camera connect];
            }
            else if(self.camera.isSessionConnected){
                self.configWifiResult = CONFIG_WIFI_SUCCESS;
                [[WiFiConfigContext sharedInstance] stopConfig];
                [self setTimerInterval:0.01f];
            }
        }
    }
}

-(void)saveCamera{
    BOOL isExist = NO;
    for(BaseCamera *c in [GBase sharedInstance].cameras){
        if([c.uid isEqualToString:self.camera.uid]){
            isExist = YES;
            break;
        }
    }
    if(!isExist){
        [GBase addCamera:self.camera];
    }
//    if(!self.camera.isDisconnect){
//        [self.camera start];
//    }
}
- (IBAction)goBack:(id)sender {
    [self stopConfig];
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)onReceived:(NSString *)status ip:(NSString*) ip uid:(NSString*)uid{
    LOG(@"%@ %@ config wifi success",uid,ip);
    if(self.configWifiResult == CONFIG_WIFI_FAIL && [self.uid isEqualToString:uid]){
        self.configWifiResult = CONFIG_WIFI_SUCCESS;
        [[WiFiConfigContext sharedInstance] stopConfig];
        //[self.camera stop];
        self.camera.uid = uid;
        [self setTimerInterval:0.1f];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[WiFiConfigContext sharedInstance] startConfig];
    
}

-(void)go2List{
    [self stopConfig];
    [self.navigationController popToRootViewControllerAnimated:YES];
    //[self performSegueWithIdentifier:@"AddDeviceWirelessSetting2CameraList" sender:self];
}

-(void)go2Help{
    [self stopConfig];
    [self performSegueWithIdentifier:@"AddDeviceWirelessSetting2SearchCamera" sender:self];
}

-(void)go2Search{
    [self stopConfig];
    [self performSegueWithIdentifier:@"AddDeviceWirelessSetting2SearchCamera" sender:self];
}

-(void)stopConfig{
    if([[WiFiConfigContext sharedInstance] isRunning]){
        [[WiFiConfigContext sharedInstance] stopConfig];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopConfig];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
