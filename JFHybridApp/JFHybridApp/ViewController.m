//
//  ViewController.m
//  JFHybridApp
//
//  Created by apple on 16/12/14.
//  Copyright © 2016年 pengjf. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
@interface ViewController ()<WKScriptMessageHandler,WKUIDelegate,WKNavigationDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,strong)WKWebView *web;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self createWeb];
    
    
}

- (void)createWeb{
    WKWebViewConfiguration *configure = [[WKWebViewConfiguration alloc] init];
    [[configure userContentController] addScriptMessageHandler:self name:@"webJsBridge"];
    self.web = [[WKWebView alloc] initWithFrame:[UIScreen mainScreen].bounds configuration:configure];
    //服务器地址：http://pjf_html.w20.guoji.biz/GJshangcheng/gj/html/home.html
    NSURL *URL = [[NSURL alloc] initWithString:@"file:///Users/apple/Desktop/SVN%E9%A1%B9%E7%9B%AE/GJshangcheng/gj/html/home.html"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
    self.web.UIDelegate = self;
    self.web.navigationDelegate = self;
    [self.web loadRequest:request];
    [self.view addSubview:self.web];
    
    //设置web的监听
    [self.web addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    
    
    
}
//监听到新的值的方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"loading"]) {
        
    }
}
//js弹出窗此方法可以捕获到，之后将其转化为系统弹出窗就可以了
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    NSLog(@"%@", message);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //此回调必须要加上，否则就会crash
        completionHandler();
    }]];
    [self presentViewController:alert animated:true completion:nil];
}
//点击h5页面的相机按钮的时候，截获到参数openCamera，执行相应的方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    if([message.name isEqualToString:@"webJsBridge"]){
        if ([message.body[@"option"] isEqualToString:@"openCamera"]) {
           //打开相册
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController *pick = [[UIImagePickerController alloc] init];
                pick.delegate = self;
                pick.sourceType =UIImagePickerControllerSourceTypePhotoLibrary;
                [self presentViewController:pick animated:YES completion:nil];
            }
        }
        if ([message.body[@"option"] isEqualToString:@"getText"]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message.body[@"value"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }]];
            [self presentViewController:alert animated:true completion:nil];
        }
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    NSString *type = [info objectForKey:@"UIImagePickerControllerMediaType"];
    if ([type isEqualToString:@"public.image"]) {
        NSLog(@"选取的类型是照片类型，其他的视屏类型过滤掉");
        UIImage *getImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];

        [self saveImage:getImage ImageName:@"jsgetimages.png" back:^(NSString *imagePath) {
            NSLog(@"imagePath:==%@",imagePath);
            NSString *js = [[NSString alloc] initWithFormat:@"hello(\"%@\")",imagePath];
            [self.web evaluateJavaScript:js completionHandler:^(id _Nullable name, NSError * _Nullable error) {
                NSLog(@"%@", error.localizedDescription);
            }];
        }];
        
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)saveImage:(UIImage *)saveImage ImageName:(NSString *)imageName back:(void(^)(NSString *imagePath))back
{
    NSString *path = [self getImageDocumentFolderPath];
    NSData *imageData = UIImagePNGRepresentation(saveImage);
    NSString *documentsDirectory = [NSString stringWithFormat:@"%@/", path];
    // Now we get the full path to the file
    NSString *imageFile = [documentsDirectory stringByAppendingPathComponent:imageName];
    // and then we write it out
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //如果文件路径存在的话
    BOOL bRet = [fileManager fileExistsAtPath:imageFile];
    if (bRet)
    {
        //        NSLog(@"文件已存在");
        if ([fileManager removeItemAtPath:imageFile error:nil]){
            //            NSLog(@"删除文件成功");
            if ([imageData writeToFile:imageFile atomically:YES]){
                //                NSLog(@"保存文件成功");
                back(imageFile);
            }
        }else{
            
        }
        
    }
    else
    {
        if (![imageData writeToFile:imageFile atomically:NO])
        {
            [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            if ([imageData writeToFile:imageFile atomically:YES])
            {
                back(imageFile);
            }
        }
        else
        {
            return YES;
        }
        
    }
    return NO;
}
#pragma mark  从文档目录下获取Documents路径
- (NSString *)getImageDocumentFolderPath
{
    NSString *patchDocument = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [NSString stringWithFormat:@"%@/Images", patchDocument];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
