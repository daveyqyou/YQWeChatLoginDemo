//
//  ViewController.m
//  YQWeChatLoginDemo
//
//  Created by DaveYou on 2018/9/6.
//  Copyright © 2018年 DaveYou. All rights reserved.
//

#import "ViewController.h"

#import "weixinInfo.h"
#import "WXApi.h"
#import "AFNetworking.h"
#import "AppDelegate.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *userInfoLabel;

@end

@implementation ViewController
- (IBAction)loginAction:(UIButton *)sender {
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:WX_ACCESS_TOKEN];
    NSString *openID = [[NSUserDefaults standardUserDefaults] objectForKey:WX_OPEN_ID];
    // 如果已经请求过微信授权登录，那么考虑用已经得到的access_token
    if (![accessToken isEqualToString:@"access_token"]|| ![openID isEqualToString:@"openid"]) {
        [self isLoginedAlertController];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
        NSString *refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:WX_REFRESH_TOKEN];
        NSString *refreshUrlStr = [NSString stringWithFormat:@"%@/oauth2/refresh_token?appid=%@&grant_type=refresh_token&refresh_token=%@", WX_BASE_URL, WXPatient_App_ID, refreshToken];
        [manager GET:refreshUrlStr parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"请求reAccess的response = %@", responseObject);
            //对数据进行转码
            // ASCII to NSString
            NSString * refreshDictStr = [[NSString alloc] initWithData: responseObject encoding: NSUTF8StringEncoding];
            NSLog(@"\n\n refreshDict = %@",refreshDictStr);
            //字符串再生成NSData
            NSData * data = [refreshDictStr dataUsingEncoding:NSUTF8StringEncoding];
            //再解析
            NSDictionary *refreshDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            NSString *reAccessToken = [refreshDict objectForKey:WX_ACCESS_TOKEN];
            // 如果reAccessToken为空,说明reAccessToken也过期了,反之则没有过期
            if (reAccessToken) {
                // 更新access_token、refresh_token、open_id
                [[NSUserDefaults standardUserDefaults] setObject:reAccessToken forKey:WX_ACCESS_TOKEN];
                [[NSUserDefaults standardUserDefaults] setObject:[refreshDict objectForKey:WX_OPEN_ID] forKey:WX_OPEN_ID];
                [[NSUserDefaults standardUserDefaults] setObject:[refreshDict objectForKey:WX_REFRESH_TOKEN] forKey:WX_REFRESH_TOKEN];
                [[NSUserDefaults standardUserDefaults] synchronize];
                // 当存在reAccessToken不为空时直接执行AppDelegate中的weixinLoginByRequestForUserInfo方法
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate weixinLoginByRequestForUserInfo];
                
            }
            else {
                [self weixinLogin];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"用refresh_token来更新accessToken时出错 = %@", error);
        }];
    }
    else {
        [self weixinLogin];
    }
}

-(void)weixinLogin{
    if([WXApi isWXAppInstalled]){
        SendAuthReq *req = [[SendAuthReq alloc]init];
        req.scope = WX_SCOPE;
        req.state = WX_STATE; //可省，不影响功能
        [WXApi sendReq:req];
    }else{
        [self noLoginAlertController];
    }
}

#pragma mark - 设置弹出提示语
- (void)noLoginAlertController {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"请先安装微信客户端" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:actionConfirm];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)isLoginedAlertController{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"您已经登陆了，请先退出登录" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:actionConfirm];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)resetAction:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@"access_token" forKey:WX_ACCESS_TOKEN];
    [[NSUserDefaults standardUserDefaults] setObject:@"openid" forKey:WX_OPEN_ID];
    _userInfoLabel.text = @"";
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.userInfo = nil;
}
- (IBAction)getUserInfo:(UIButton *)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if([appDelegate.userInfo count] != 0){  //判断userInfo中是否有值
        NSString *nickname = [appDelegate.userInfo objectForKey:@"nickname"];
        NSString *city = [appDelegate.userInfo objectForKey:@"city"];
        NSString *openid = [appDelegate.userInfo objectForKey:@"openid"];
        NSString *unionid = [appDelegate.userInfo objectForKey:@"unionid"];
        
        NSString *userStr = [[NSString alloc]init];
        userStr = [userStr stringByAppendingFormat:@" nickname = %@ \n city = %@ \n openid = %@ \n unionid = %@",nickname,city,openid,unionid];
        //view中label的属性
        _userInfoLabel.text = userStr;
        _userInfoLabel.numberOfLines = 7; //用于设置UILabel中文本的行数
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"请先登录" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:actionConfirm];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
