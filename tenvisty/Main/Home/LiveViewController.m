//
//  LiveViewController.m
//  tenvisty
//
//  Created by lu yi on 12/3/17.
//  Copyright © 2017 Tenvis. All rights reserved.
//

#define ISFULLSCREEN self.view.bounds.size.width > self.view.bounds.size.height
#define ZOOM_MAX_SCALE 5.0
#define ZOOM_MIN_SCALE 1.0
#define RECORD_TIMEOUT (5)
#define DEFAULT_VIDEO_RATIO 16/9

#import "LiveViewController.h"
#import <IOTCamera/Monitor.h>
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"
#import "UIDevice+TFDevice.h"
#import "SwitchVideoQualityDialog.h"
#import "MyCamera.h"

@interface LiveViewController ()<MyCameraDelegate,MonitorTouchDelegate>{
    BOOL isTalking;
    BOOL isListening;
    BOOL isRecording;
    NSTimer *recordTimer;
    BOOL isShowingToolBtnsLand;
    NSDate *switchTime;
    double ptz_ctrl_time;
    double receiveVideoTime;
    double lostVideoTime;
    NSInteger videoFps;
}
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *labResolution;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollviewVideo;
@property (weak, nonatomic) IBOutlet UIView *viewSwitchVideoQuality_port;
//@property (weak, nonatomic) IBOutlet SwitchVideoQualityDialog *viewSwitchVideoQuality_land;
@property (weak, nonatomic) IBOutlet UIImageView *viewPopDown_port;
@property (weak, nonatomic) IBOutlet UIView *connectStatus_port;
@property (weak, nonatomic) IBOutlet UIView *toolbtns_portrait;
@property (weak, nonatomic) IBOutlet UIView *video_wrapper;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_status_height;
@property (nonatomic,assign) Boolean isFullscreen;
@property (weak, nonatomic) IBOutlet UILabel *labConnectState;
@property (weak, nonatomic) IBOutlet Monitor *videoMonitor;
@property (weak, nonatomic) IBOutlet UIButton *btnListen_port;
@property (weak, nonatomic) IBOutlet UIButton *btnListen_land;
@property (weak, nonatomic) IBOutlet UIButton *btnRecord_port;
@property (weak, nonatomic) IBOutlet UIButton *btnRecord_land;
@property (weak, nonatomic) IBOutlet UIView *viewRecordTime;
@property (weak, nonatomic) IBOutlet UILabel *labRecordTime;
@property (weak, nonatomic) IBOutlet UIView *viewLoading;
@property (weak, nonatomic) IBOutlet UIButton *btnTalk_land;
@property (weak, nonatomic) IBOutlet UIButton *btnShowSwitchQuality_port;
@property (weak, nonatomic) IBOutlet UIButton *btnShowSwitchQuality_land;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_width_viewSwitchVideoQuality_land;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_x_viewSwitchVideoQuality_land;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_top_viewSwitchVideoQuality_land;
@property (weak, nonatomic) IBOutlet UIView *viewPreset;
@property (weak, nonatomic) IBOutlet UIView *viewToolbarTop;
@property (weak, nonatomic) IBOutlet UIView *viewToolbarBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_bottom_viewtoolbarbottom;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *constraint_xcenter_videowrapper;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *constraint_leading_videowrapper;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *constraint_trailing_videowrapper;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *constraint_ycenter_videowrapper;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *constraint_top_videowrapper;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *constraint_bottom_videowrapper;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_toolbar_portrait_height;

@property (weak, nonatomic) IBOutlet UIButton *btnPreset;
@property (weak, nonatomic) IBOutlet UIButton *btnTalk_port;

@end

@implementation LiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _isFullscreen = self.view.bounds.size.width > self.view.bounds.size.height;// self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight;
    [self rotateOrientation:_isFullscreen?UIInterfaceOrientationLandscapeLeft:UIInterfaceOrientationPortrait];
    [self setup];
    // Do any additional setup after loading the view.
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    //允许转成横屏
    appDelegate.allowRotation = YES;
    _viewPopDown_port.tintColor = Color_Primary;
    if(zkDevice_IsiPhoneXOrBigger){
        _constraint_bottom_viewtoolbarbottom.constant = 30;
    }
    if(self.camera.remoteNotifications > 1){
        [self.camera clearRemoteNotifications];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.camera.isPlaying = YES;
    
}

-(void)doChangeVideoQuality:(NSInteger)index t:(NSString*)title{
    
}

-(void)setup{
    self.title = self.camera.nickName;
    [_btnShowSwitchQuality_land setTitle:self.camera.videoQuality == 0?LOCALSTR(@"SD"):LOCALSTR(@"HD") forState:UIControlStateNormal];
    [_btnShowSwitchQuality_port setTitle:self.camera.videoQuality == 0?LOCALSTR(@"SD"):LOCALSTR(@"HD") forState:UIControlStateNormal];
   // [self getPresetList];
    [self.videoMonitor setMinimumGestureLength:100 MaximumVariance:50];
    [self.videoMonitor setUserInteractionEnabled:YES];
    self.videoMonitor.contentMode = UIViewContentModeScaleToFill;
    self.videoMonitor.backgroundColor = [UIColor blackColor];
    self.videoMonitor.delegate = self;
    
    self.scrollviewVideo.minimumZoomScale = ZOOM_MIN_SCALE;
    self.scrollviewVideo.maximumZoomScale = ZOOM_MAX_SCALE;
    self.scrollviewVideo.contentMode = UIViewContentModeScaleAspectFit;
    self.scrollviewVideo.contentSize = self.videoMonitor.frame.size;
    [self resizeMonitor:self.camera.videoRatio];
    [self checkFunction];
}

#pragma mark - ScrollView Delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
        return self.videoMonitor;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(float)scale
{
    if (scale == ZOOM_MIN_SCALE) {
         self.scrollviewVideo.contentSize = CGSizeMake(320, 240);
    }
}

- (IBAction)toggleBtnsLand:(UITapGestureRecognizer *)sender {
    [_viewSwitchVideoQuality_port setHidden:YES];
    [_viewPreset setHidden:YES];
    if(ISFULLSCREEN){
        [self toggleTools:isShowingToolBtnsLand];
    }
}
- (IBAction)selectPreset:(UIButton *)sender {
    [sender setBackgroundColor:Color_GrayDark];
    _viewPreset.tag = sender.tag;
    for(UIButton *btn in [sender.superview subviews]){
        if(sender != btn){
           [btn setBackgroundColor:Color_Gray];
        }
    }
    
}

- (IBAction)doPreset:(UIButton *)sender {
    //set
    if(sender.tag == 0){
        if(_viewPreset.tag > 0){
            SMsgAVIoctrlSetPointReq *req = malloc(sizeof(SMsgAVIoctrlSetPointReq));
            NSString *desc = [NSString stringWithFormat:@"preset%d",(int)_viewPreset.tag];
            memset(req, 0, sizeof(SMsgAVIoctrlSetPointReq));
            memcpy(req->Desc,[desc UTF8String], desc.length);
            req->BitID = (int)_viewPreset.tag;
            [self.camera sendIOCtrlToChannel:0 Type:IOTYPE_USER_IPCAM_SET_PRESET_POINT_REQ Data:(char*)req DataSize:sizeof(SMsgAVIoctrlSetPointReq)];
            free(req);
            req = nil;
        }
    }
    //call
    else if(sender.tag == 1){
        if(_viewPreset.tag >= 0){
            SMsgAVIoctrlPointOprReq *req = malloc(sizeof(SMsgAVIoctrlPointOprReq));
            req->Type = 0;
            req->BitID = (int)_viewPreset.tag;
            [self.camera sendIOCtrlToChannel:0 Type:IOTYPE_USER_IPCAM_OPR_PRESET_POINT_REQ Data:(char*)req DataSize:sizeof(SMsgAVIoctrlPointOprReq)];
            free(req);
            req = nil;
        }
    }
    //clear
    else if(sender.tag == 2){
        if(_viewPreset.tag > 0){
            SMsgAVIoctrlPointOprReq *req = malloc(sizeof(SMsgAVIoctrlPointOprReq));
            req->Type = 1;
            req->BitID = (int)_viewPreset.tag;
            [self.camera sendIOCtrlToChannel:0 Type:IOTYPE_USER_IPCAM_OPR_PRESET_POINT_REQ Data:(char*)req DataSize:sizeof(SMsgAVIoctrlPointOprReq)];
            free(req);
            req = nil;
        }
    }
}




-(void)toggleTools:(BOOL)hide{
    isShowingToolBtnsLand = !hide;
    [_viewToolbarTop setHidden:!isShowingToolBtnsLand];
    [_viewToolbarBottom setHidden:!isShowingToolBtnsLand];
    if(isShowingToolBtnsLand){
        [_btnTalk_land setHidden:!isListening];
    }
    else{
        [_btnTalk_land setHidden:YES];
    }
    if(isShowingToolBtnsLand){
        [self.scrollviewVideo setZoomScale:1.0];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.allowRotation = YES;
    _labConnectState.text = self.camera.cameraStateDesc;
    [_videoMonitor attachCamera:(MyCamera*)self.camera.orginCamera];
    [_viewLoading setHidden:NO];
    //[self changeStream:self.camera.videoQuality];
    [self.camera startVideo];
    if(isListening){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.camera startAudio];
        });
    }
    
    videoFps = 0;
    //注册通知，进入后台时退回主界面
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_videoMonitor deattachCamera];
    [self stopRecord];
    [self.camera stopVideoAsync:^{
        [self.camera stopSpeak];
        [self.camera stopAudio];
    }];
    if(_videoMonitor.image){
        [self.camera saveImage:_videoMonitor.image];
    }
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.allowRotation = NO;
    self.camera.isPlaying = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)changeStream:(NSInteger)stream{
    SMsgAVIoctrlSetStreamCtrlReq *req = malloc(sizeof(SMsgAVIoctrlSetStreamCtrlReq));
    req->channel = 0;
    req->quality = stream == 0?5:1;
    [self.camera sendIOCtrlToChannel:0 Type:IOTYPE_USER_IPCAM_SETSTREAMCTRL_REQ Data:(char*)req DataSize:sizeof(SMsgAVIoctrlSetStreamCtrlReq)];
    free(req);
    req = nil;
}
- (IBAction)doSwitchVideoToHD:(UIButton *)sender {
    [_btnShowSwitchQuality_land setTitle:[sender currentTitle] forState:UIControlStateNormal];
    [_btnShowSwitchQuality_port setTitle:[sender currentTitle] forState:UIControlStateNormal];
    if(self.camera.videoQuality != 1){
        switchTime = [NSDate date];
        self.camera.videoQuality = 1;
        [GBase editCamera:self.camera];
        [self changeStream:1];
//        [self.camera stopVideoAsync:^{
//            [self changeStream:1];
//        }];
    }
    [_viewSwitchVideoQuality_port setHidden:YES];
}
- (IBAction)doSwitchVideoToSD:(UIButton *)sender {
    [_btnShowSwitchQuality_land setTitle:[sender currentTitle] forState:UIControlStateNormal];
    [_btnShowSwitchQuality_port setTitle:[sender currentTitle] forState:UIControlStateNormal];
    if(self.camera.videoQuality != 0){
        switchTime = [NSDate date];
        self.camera.videoQuality = 0;
        [GBase editCamera:self.camera];
        [self changeStream:0];
//        [self.camera stopVideoAsync:^{
//            [self changeStream:0];
//        }];
    }
    [_viewSwitchVideoQuality_port setHidden:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||

            interfaceOrientation == UIInterfaceOrientationLandscapeRight );
}



-(void) rotateOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    CGFloat height = Screen_Main.width>Screen_Main.height?Screen_Main.height:Screen_Main.width;
    CGFloat width = Screen_Main.width>Screen_Main.height?Screen_Main.width:Screen_Main.height;
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
       
       toInterfaceOrientation == UIInterfaceOrientationLandscapeRight ){
        //[self.toolbtns_land setHidden:NO];
        //[self toggleTools:YES];
        [self.constraint_status_height setConstant:0];
        
        [self.constraint_toolbar_portrait_height setConstant:0];
        [self.toolbtns_portrait setHidden:YES];
        self.navigationController.navigationBar.hidden=YES;
        _isFullscreen = YES;
        [_btnTalk_land setHidden:!isListening];
        [_constraint_width_viewSwitchVideoQuality_land setPriority:UILayoutPriorityDefaultHigh];
        [_constraint_x_viewSwitchVideoQuality_land setPriority:UILayoutPriorityDefaultHigh];
        [_constraint_top_viewSwitchVideoQuality_land setPriority:UILayoutPriorityDefaultHigh];
        [_connectStatus_port setHidden:YES];
        if(width/height < self.camera.videoRatio){
            _constraint_ycenter_videowrapper.priority = 800;
            _constraint_bottom_videowrapper.priority = 700;
            _constraint_top_videowrapper.priority = 700;
            _constraint_leading_videowrapper.priority = 800;
            _constraint_trailing_videowrapper.priority = 800;
            _constraint_xcenter_videowrapper.priority = 700;
        }
        else{
            _constraint_leading_videowrapper.priority = 700;
            _constraint_trailing_videowrapper.priority = 700;
            _constraint_xcenter_videowrapper.priority = 800;
            _constraint_ycenter_videowrapper.priority = 700;
            _constraint_bottom_videowrapper.priority = 800;
            _constraint_top_videowrapper.priority = 800;
        }
    }
    else{
        _constraint_ycenter_videowrapper.priority = 700;
        _constraint_bottom_videowrapper.priority = 800;
        _constraint_top_videowrapper.priority = 800;
        _constraint_leading_videowrapper.priority = 800;
        _constraint_trailing_videowrapper.priority = 800;
        _constraint_xcenter_videowrapper.priority = 700;

        [self toggleTools:YES];
        [self.constraint_status_height setConstant:40];
        [self.constraint_toolbar_portrait_height setConstant:40];
        [self.toolbtns_portrait setHidden:NO];
        self.navigationController.navigationBar.hidden=NO;
        _isFullscreen = NO;
        [_constraint_width_viewSwitchVideoQuality_land setPriority:UILayoutPriorityDefaultLow];
        [_constraint_x_viewSwitchVideoQuality_land setPriority:UILayoutPriorityDefaultLow];
        [_constraint_top_viewSwitchVideoQuality_land setPriority:UILayoutPriorityDefaultLow];
        [_viewPreset setHidden:YES];
        [_connectStatus_port setHidden:NO];
//        for(NSLayoutConstraint *constraint in self.video_wrapper.constraints){
//            if([constraint.identifier isEqualToString:@"videowrapper_ratio"]){
//                existConstraint = constraint;
//                break;
//            }
//        }
      //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
    [_viewSwitchVideoQuality_port setHidden:YES];
}

- (BOOL)prefersStatusBarHidden {
    return _isFullscreen;
}



- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self rotateOrientation:toInterfaceOrientation];
    [self setNeedsStatusBarAppearanceUpdate];
    
}
- (IBAction)doSnapshot:(id)sender {
    BOOL success = [GBase savePictureForCamera:self.camera image:_videoMonitor.image];
    if(success){
        [TwsTools presentMessage:LOCALSTR(@"Snapshot Saved") atDeviceOrientation:DeviceOrientationPortrait];
    }
    else{
        [TwsTools presentMessage:LOCALSTR(@"Snapshot Failed") atDeviceOrientation:DeviceOrientationPortrait];
    }
}
- (IBAction)endTalk:(id)sender {
    [self.camera stopSpeak];
    if(isListening){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.camera startAudio];
        });
        [_btnListen_port setImage:[UIImage imageNamed:@"btnSound_opened_portrait"] forState:UIControlStateNormal];
        [_btnListen_land setImage:[UIImage imageNamed:@"btnSound_opened_portrait"] forState:UIControlStateNormal];
    }
    isTalking = NO;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}
- (IBAction)startTalk:(id)sender {
    //[self.camera stopAudio];
    if([self checkMicroPermission]){
        if(isListening){
            [self.camera stopAudio];
            [_btnListen_port setImage:[UIImage imageNamed:@"btnSound_pause_portrait"] forState:UIControlStateNormal];
            [_btnListen_land setImage:[UIImage imageNamed:@"btnSound_pause_portrait"] forState:UIControlStateNormal];
        }
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [self.camera startSpeak];
        isTalking = YES;
    }
}
- (IBAction)doRecord:(UIButton*)sender {
    if (!sender.selected) {
        if(videoFps <1){
            [[iToast makeText:LOCALSTR(@"Please wait the camera connected")] show];
        }
        else{
            [self startRecord];
        }
    }else{
        [self stopRecord];
    }
}

-(void)startRecord{
    _btnRecord_land.selected = YES;
    _btnRecord_port.selected = YES;
    isRecording = YES;
    NSString *recordNameString =  [GBase saveRecordingForCamera:self.camera thumb:self.videoMonitor.image];
    if(recordNameString != nil){
        [self.camera startRecordVideo:recordNameString];
        [_viewRecordTime setHidden:NO];
        [_labRecordTime setText:@"00:00"];
        _labRecordTime.tag = 0;
        recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshRecordTime) userInfo:NULL repeats:YES];
    }
}

-(void)stopRecord{
    _btnRecord_land.selected = NO;
    _btnRecord_port.selected = NO;
    isRecording = NO;
    [self.camera stopRecordVideo];
    [_viewRecordTime setHidden:YES];
    if(recordTimer){
        [recordTimer invalidate];
        recordTimer = nil;
    }
}

-(void)refreshRecordTime{
    _labRecordTime.tag++;
    int second = _labRecordTime.tag % 60;
    
    int minute = (int)_labRecordTime.tag/60;
    
    [_labRecordTime setText:[NSString stringWithFormat:@"%@:%@",[NSString stringWithFormat:minute>9?@"%d":@"0%d",minute],[NSString stringWithFormat:second>9?@"%d":@"0%d",second]]];
}
-(void)checkFunction{
    [_btnListen_land setHidden:![self.camera hasListen]];
    [_btnListen_port setHidden:![self.camera hasListen]];
    [_btnTalk_port setHidden:![self.camera hasListen]];
    
    [_btnPreset setHidden:![self.camera hasPTZ]];
}
- (IBAction)doFullScreen:(id)sender {
    [self rotateOrientation:UIInterfaceOrientationLandscapeLeft];
    [UIDevice switchNewOrientation:UIInterfaceOrientationLandscapeRight];
}
- (IBAction)doListen:(UIButton*)sender {
    if(!isTalking){
        isListening = !isListening;
        if(isListening){
            
            [_btnListen_port setImage:[UIImage imageNamed:@"btnSound_opened_portrait"] forState:UIControlStateNormal];
            [_btnListen_land setImage:[UIImage imageNamed:@"btnSound_opened_portrait"] forState:UIControlStateNormal];
            [self.camera startAudio];
        }
        else{
            [_btnListen_port setImage:[UIImage imageNamed:@"btnSound_closed_portrait"] forState:UIControlStateNormal];
            [_btnListen_land setImage:[UIImage imageNamed:@"btnSound_closed_land"] forState:UIControlStateNormal];
            [self.camera stopAudio];
        }
    }
    if(_isFullscreen){
        [_btnTalk_land setHidden:!isListening];
    }
}

-(void)startListen:(BOOL)changeUI{
    if(!isTalking){
        
        [self.camera startAudio];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        if(changeUI){
            [_btnListen_port setImage:[UIImage imageNamed:@"btnSound_opened_portrait"] forState:UIControlStateNormal];
            [_btnListen_land setImage:[UIImage imageNamed:@"btnSound_opened_portrait"] forState:UIControlStateNormal];
             isListening = YES;
        }
         [_btnTalk_land setHidden:!isListening];
    }
}

-(void)stopListen:(BOOL)changeUI{
    [self.camera stopAudio];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    if(changeUI){
        [_btnListen_port setImage:[UIImage imageNamed:@"btnSound_closed_portrait"] forState:UIControlStateNormal];
        [_btnListen_land setImage:[UIImage imageNamed:@"btnSound_closed_land"] forState:UIControlStateNormal];
        isListening = NO;
    }
}



- (IBAction)showSwitchQuality:(UIButton*)sender {
    [_viewSwitchVideoQuality_port setHidden:![_viewSwitchVideoQuality_port isHidden]];
}
- (IBAction)goFolder:(id)sender {
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Image" bundle:nil];
    BaseViewController* test2obj = [secondStoryBoard instantiateViewControllerWithIdentifier:@"storyboard_imagecollection"];  //test2为viewcontroller的StoryboardId
    test2obj.camera = self.camera;
    [self.navigationController pushViewController:test2obj animated:YES];
}
- (IBAction)goEventList:(id)sender {
    if(self.camera.supplier == SUPLLIER_AN){
        [self performSegueWithIdentifier:@"LiveView2EventList_Aoni" sender:self];
    }
    else{
        [self performSegueWithIdentifier:@"LiveView2EventList" sender:self];
    }
}
- (IBAction)showPreset:(id)sender {
    [_viewPreset setHidden:![_viewPreset isHidden]];
}
- (IBAction)doPortraitView:(id)sender {
     [self rotateOrientation:UIInterfaceOrientationPortrait];
    //切换到竖屏
    [UIDevice switchNewOrientation:UIInterfaceOrientationPortrait];
}

- (BOOL)checkMicroPermission{
    BOOL result = NO;
    if(SystemVersion >= 8.0){
        AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
        switch (permissionStatus) {
            case AVAudioSessionRecordPermissionUndetermined:{
                NSLog(@"first use microphone, show distribute permission dialog");
                [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
                    if(granted){
                        
                    }else{
                        
                    }
                    
                }];
            }
                break;
            case AVAudioSessionRecordPermissionDenied:{
                NSLog(@"decline microphone permission");
                NSString *messageString = [NSString stringWithFormat:NSLocalizedString(@"%@ needs microphone permission.Please go to Settings->Privacy->Microphone->%@->re-enable Microphone (in your iphone or ipad).", @""),[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
                [TwsTools presentAlertTitle:self title:nil message:messageString alertStyle:UIAlertControllerStyleAlert actionDefaultTitle:LOCALSTR(@"OK") actionDefaultBlock:^{
                    [TwsTools goPhoneSettingPage:@"microphone permission"];
                } actionCancelTitle:LOCALSTR(@"Cancel") actionCancelBlock:nil];
                
            }
                break;
            case AVAudioSessionRecordPermissionGranted:{
                NSLog(@"has microphone permission");
                result = YES;
            }
                break;
            default:
                
                break;
        }
    }
    else{
        result = YES;
    }
    return result;
}



//在试图将要已将出现的方法中
//- (void)viewDidAppear:(BOOL)animated{
//    
//    [super viewDidAppear:animated];
//    
//    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
//        
//        //调用隐藏方法
//        [self prefersStatusBarHidden];
//        
//        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
//        
//    }
//    
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[BaseViewController class]]){
        BaseViewController *controller= segue.destinationViewController;
        controller.camera =  self.camera;
    }
}
- (void)camera:(BaseCamera *)camera _didChangeSessionStatus:(NSInteger)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        _labConnectState.text = camera.cameraStateDesc;
    });
}

- (void)camera:(BaseCamera *)camera _didChangeChannelStatus:(NSInteger)channel ChannelStatus:(NSInteger)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        _labConnectState.text = camera.cameraStateDesc;
    });
    if(self.camera.cameraConnectState == CONNECTION_STATE_CONNECTED){
        [self.camera startVideo];
       // [self changeStream:self.camera.videoQuality];
        if(isListening){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.camera startAudio];
            });
        }
    }
}

- (void)camera:(BaseCamera *)camera _didReceiveFrameInfoWithVideoWidth:(NSInteger)videoWidth VideoHeight:(NSInteger)videoHeight VideoFPS:(NSInteger)fps VideoBPS:(NSInteger)videoBps AudioBPS:(NSInteger)audioBps OnlineNm:(NSInteger)onlineNm FrameCount:(unsigned long)frameCount IncompleteFrameCount:(unsigned long)incompleteFrameCount{
    videoFps = fps;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(fps > 0){
            receiveVideoTime = [[NSDate date] timeIntervalSinceReferenceDate];
            [_viewLoading setHidden:YES];
        }
        else{
            lostVideoTime = [[NSDate date] timeIntervalSinceReferenceDate];
            if(!receiveVideoTime || lostVideoTime - receiveVideoTime > RECORD_TIMEOUT){
                if(isRecording){
                    [self stopRecord];
                    [[iToast makeText:LOCALSTR(@"recording stopped")] show];
                }
                [_viewLoading setHidden:NO];
            }
            
        }
    });
}

-(void)resizeMonitor:(CGFloat)ratio{
    NSLayoutConstraint *existConstraint = nil;
    for(NSLayoutConstraint *constraint in self.video_wrapper.constraints){
        if([constraint.identifier isEqualToString:@"videowrapper_ratio"]){
            existConstraint = constraint;
            break;
        }
    }
    
    //if(existConstraint == nil){
    NSLayoutConstraint *myConstraint =[NSLayoutConstraint
                                       constraintWithItem:self.video_wrapper //子试图
                                       attribute:NSLayoutAttributeWidth //子试图的约束属性
                                       relatedBy:0 //属性间的关系
                                       toItem:self.video_wrapper//相对于父试图
                                       attribute:NSLayoutAttributeHeight//父试图的约束属性
                                       multiplier:ratio
                                       constant:0.0];// 固定距离
    myConstraint.identifier = @"videowrapper_ratio";
    [self.video_wrapper removeConstraint:existConstraint];//在父试图上将iSinaButton距离屏幕左边的约束删除
    [self.video_wrapper addConstraint: myConstraint];
}

- (void)camera:(NSCamera *)camera _didReceiveRawDataFrame:(const char *)imgData VideoWidth:(NSInteger)width VideoHeight:(NSInteger)height{
    if(fabs(self.camera.videoRatio-(CGFloat)width/height) > 0.2){
        self.camera.videoRatio = (CGFloat)width/height;
        [self resizeMonitor:self.camera.videoRatio];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.labResolution.text = FORMAT(@"%ld x %ld",width,height);
        if(switchTime == nil ||  [[NSDate date] timeIntervalSinceReferenceDate] -[switchTime timeIntervalSinceReferenceDate] > 5){
            [_btnShowSwitchQuality_port setTitle:height < 700 ? LOCALSTR(@"SD"):LOCALSTR(@"HD") forState:UIControlStateNormal];
            [_btnShowSwitchQuality_land setTitle:height < 700 ? LOCALSTR(@"SD"):LOCALSTR(@"HD") forState:UIControlStateNormal];
            self.camera.videoQuality = height < 700 ? 0 :1;
        }
    });
}

-(void)getPresetList{
    SMsgAVIoctrlGetAudioOutFormatReq *s = (SMsgAVIoctrlGetAudioOutFormatReq *)malloc(sizeof(SMsgAVIoctrlGetAudioOutFormatReq));
    s->channel = 0;
    [self.camera sendIOCtrlToChannel:0 Type:IOTYPE_USER_IPCAM_GET_PRESET_LIST_REQ Data:(char *)s DataSize:sizeof(SMsgAVIoctrlGetAudioOutFormatReq)];
    free(s);
    s = nil;
}

- (void)camera:(NSCamera *)camera _didReceiveIOCtrlWithType:(NSInteger)type Data:(const char*)data DataSize:(NSInteger)size{
    switch (type) {
        case IOTYPE_USER_IPCAM_GET_PRESET_LIST_RESP:{
                SMsgAVIoctrlGetPreListResp *presetList = (SMsgAVIoctrlGetPreListResp*)data;
                for(UIButton* btn in [[[_viewPreset subviews] objectAtIndex:1] subviews]){
                    btn.selected = NO;
                    for(int i = 0; i < presetList->count; i++){
                        if(btn.tag == presetList->stPoint[i].BitID){
                            btn.selected = YES;
                            break;
                        }
                    }
                }
            }
            break;
        case IOTYPE_USER_IPCAM_SET_PRESET_POINT_RESP:
            if(((SMsgAVIoctrlSetPointResp*)data)->result == 0){
                [self getPresetList];
            }
            else{
                [[iToast makeText:LOCALSTR(@" Preset setting failed")] show];
            }
            break;
        case IOTYPE_USER_IPCAM_OPR_PRESET_POINT_RESP:
             if(((SMsgAVIoctrlSetPointResp*)data)->result == 0){
                  [self getPresetList];
            }
            else{
                [[iToast makeText:LOCALSTR(@" Preset calling failed")] show];
            }
            break;
        case IOTYPE_USER_IPCAM_SETSTREAMCTRL_RESP: {
                [self.camera stop];
                [self.camera start];
             }
            break;
        default:
            break;
    }
}


#pragma mark - MonitorTouchDelegate Methods

- (void)monitor:(Monitor *)monitor gesturePinched:(CGFloat)scale
{
    [self.scrollviewVideo setZoomScale:scale animated:YES];
}

- (IBAction)pan:(UIPanGestureRecognizer *)recognizer {
//    UIView *view = recognizer.view;
//    
//    if(view.bounds.size.width - view.frame.size.width == 0)
//    {
//        
//        CGPoint translation = [recognizer translationInView:view.superview];
//        
//        
//        if (recognizer.state == UIGestureRecognizerStateBegan )
//        {
//            
//            //direction = kCameraMoveDirectionNone;
//            NSLog(@"x:%f    y:%f",translation.x,translation.y);
//            
//        }
//        else if (recognizer.state == UIGestureRecognizerStateEnded )
//        {
//            //命令发送间隔为500ms
//            double new_time = ((double)[[NSDate date] timeIntervalSince1970])*1000.0;
//            BOOL isCtrl = NO;
//            
//            if (new_time - ptz_ctrl_time > 500 ) {
//                isCtrl = YES;
//                ptz_ctrl_time = new_time;
//            }
//            
//            if (isCtrl) {
//                NSInteger directon = [self.camera direction:translation];
//                [self.camera PTZ:directon];
//            }
//            
//        }
//        
//    }//@if
}


- (void)didReceiveNotification:(NSNotification *)notification {
    
    LOG(@"LiveView_didReceiveNotification : %@", notification.name);
    if(notification.name == UIApplicationDidBecomeActiveNotification){
        
    }
    else{
        if(isRecording){
            [self stopRecord];
        }
    }
}

@end
