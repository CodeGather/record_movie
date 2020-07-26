#import "RecordMoviePlugin.h"
#import "XDVideocamera.h"
#import "SelectLabel.h"

@interface RecordMoviePlugin()<FlutterStreamHandler>

@end
@implementation RecordMoviePlugin{
  FlutterEventSink eventSink;
  UIViewController *flutterViewController;
  XDVideocamera *xDVideocamera;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel  methodChannelWithName:@"record_movie" binaryMessenger:[registrar messenger]];
  FlutterEventChannel* eventChannel = [FlutterEventChannel  eventChannelWithName: @"record_movie/event" binaryMessenger:[registrar messenger]];
  RecordMoviePlugin* instance = [[RecordMoviePlugin alloc] init];
  
  [eventChannel setStreamHandler: instance];
  [registrar addMethodCallDelegate:instance channel:channel];
  
  [instance getRootViewController];
  
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if([@"startRecord" isEqualToString:call.method]){
    xDVideocamera.modalPresentationStyle = UIModalPresentationFullScreen;
    xDVideocamera.edgesForExtendedLayout = YES;
    
    __block typeof(self) weakSelf = self;
    
    NSDictionary *dic = call.arguments;
    
    if ([dic objectForKey:@"isSaveGallery"] && ([dic[@"isSaveGallery"] boolValue] == TRUE || [dic[@"isSaveGallery"] boolValue] == FALSE)) {
      xDVideocamera.isSaveGallery = [dic[@"isSaveGallery"] boolValue];
    }
    
    xDVideocamera.cancelBlock=^(){
      
    };
    
    xDVideocamera.completionBlock=^(NSMutableDictionary *fileUrl){
      NSLog(@"成功返回数据%@",fileUrl);
      weakSelf->eventSink(fileUrl);
    };
    
    [flutterViewController presentViewController: xDVideocamera animated: false completion:^{
        NSLog(@"进入摄像机");
    }];
  } else if([@"cleanCache" isEqualToString:call.method]){
    [xDVideocamera cleanCacheFile];
    result(@(TRUE));
  } else {
    result(FlutterMethodNotImplemented);
  }
}


#pragma mark - 获取到跟视图
- (UIViewController *)getRootViewController {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    flutterViewController = window.rootViewController;
    return window.rootViewController;
}

#pragma mark  ======在view上添加UIViewController========
- (UIViewController *)findCurrentViewController{
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    UIViewController *topViewController = [window rootViewController];
    while (true) {
        if (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        } else if ([topViewController isKindOfClass:[UINavigationController class]] && [(UINavigationController*)topViewController topViewController]) {
            topViewController = [(UINavigationController *)topViewController topViewController];
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    return topViewController;
}

#pragma mark - IOS 主动发送通知s让 flutter调用监听 eventChannel start
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSinks {
  xDVideocamera = [[XDVideocamera alloc]init];
  if(eventSink == Nil){
    eventSink = eventSinks;
  }
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if( eventSink != Nil ){
    eventSink = nil;
  }
  return nil;
}

@end
