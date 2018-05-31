//
//  CoreMotionVC.m
//  Indoorpositioning
//
//  Created by 柯思汉 on 17/8/25.
//  Copyright © 2017年 KKK. All rights reserved.
//

#import "CoreMotionVC.h"
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
#define DEVICE_WIDTH ([UIScreen mainScreen].bounds.size.width)//设备宽
#define DEVICE_HEIGHT ([UIScreen mainScreen].bounds.size.height)//设备高

@interface CoreMotionVC ()<UIScrollViewDelegate,UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *LABEL;
@property(nonatomic,strong)CMMotionManager *manger;


@property(strong, nonatomic)AVAudioPlayer *mPlayer;

@property(assign, nonatomic)NSInteger mCount;
@property (strong, nonatomic) IBOutlet UIView *backview;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollview;
@property (strong, nonatomic) IBOutlet UIImageView *map;
@property(nonatomic,strong)UIView *point;
@property (nonatomic,strong)NSTimer *timer;
@property (nonatomic,assign)float MAP_HIGH;
@property (nonatomic,assign)float MAP_WIDTH;
@property (nonatomic,assign)float distance;
@property (nonatomic,assign)float sum;
@property (nonatomic,assign)float scales;
@property (nonatomic,strong)NSArray *point_arr;
@property (nonatomic,assign)int hiddentime;



@end

@implementation CoreMotionVC
- (void)viewWillAppear:(BOOL)animated
{
//    [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _hiddentime=0;
    _MAP_HIGH=667;
    _MAP_WIDTH=1000;
    _distance=10;
    _point_arr = @[@[@"1",@"5"],@[@"3",@"5"],@[@"5",@"5"],@[@"7",@"5"],@[@"9",@"5"],@[@"11",@"5"],@[@"11",@"3"],@[@"15",@"3"],@[@"17",@"3"],@[@"19",@"3"],@[@"21",@"3"],@[@"23",@"3"],@[@"23",@"4"],@[@"23",@"7"],@[@"23",@"9"],@[@"23",@"11"],@[@"23",@"13"],@[@"23",@"14"],@[@"23",@"16"],@[@"23",@"18"],@[@"23",@"20"],@[@"23",@"22"],@[@"21",@"22"],@[@"19",@"22"],@[@"17",@"22"],@[@"17",@"20"],@[@"17",@"18"],@[@"15",@"18"],@[@"13",@"18"],@[@"12",@"18"],@[@"10",@"18"],@[@"10",@"20"],@[@"10",@"25"]];
    
    _mCount = 0;
//
    self.timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timers:) userInfo:nil repeats:YES];
    // 添加到运行循环  NSRunLoopCommonModes:占位模式  主线程
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes]; // 如果不改变Mode模式在滑动屏幕的时候定时器就不起作用了
//    在子线程中定义定时器：
    [NSThread detachNewThreadSelector:@selector(bannerStart)toTarget:self withObject:nil];
    
    //设置最大伸缩比例
    _scrollview.maximumZoomScale=1.0;
    //设置最小伸缩比例
    _scrollview.minimumZoomScale=0.3;
    //设置代理scrollview的代理对象
    _scrollview.delegate=self;
    _scales=1;

    
    [self setpath:_point_arr];
    [self.backview addSubview:self.point];
    
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.backview addGestureRecognizer:singleTap];//这个可以加到任何控件上,比如你只想响应WebView，我正好填满整个屏幕
    singleTap.delegate = self;
    singleTap.cancelsTouchesInView = NO;
   
    // Do any additional setup after loading the view from its nib.
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender{
    CGPoint point = [sender locationInView:self.view];
    NSLog(@"handleSingleTap!pointx:%f,y:%f",point.x,point.y);
}

//当有一个或多个手指触摸事件在当前视图或window窗体中响应
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
    UITouch *touch = [allTouches anyObject];   //视图中的所有对象
    CGPoint point = [touch locationInView:[touch view]]; //返回触摸点在视图中的当前坐标
    int x = point.x;
    int y = point.y;
    NSLog(@"touch (x, y) is (%d, %d)", x, y);
}

- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize {
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
      [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
       UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
       UIGraphicsEndImageContext();
        return scaledImage;
}
- (void)setChangePath:(NSArray *)pointArry
{
    for (int i=0; i<pointArry.count-1; i++) {
        
        UIImageView *imageView = [self.backview viewWithTag:100+i];
        imageView.frame = CGRectMake(0, 0, _MAP_WIDTH, _MAP_HIGH);
    }
}
- (void)setpath:(NSArray *)pointArry
{
    for (int i=0; i<pointArry.count-1; i++) {
        NSString *x = [[NSString alloc]initWithFormat:@"%@",pointArry[i][0]];
        NSString *y = [[NSString alloc]initWithFormat:@"%@",pointArry[i][1]];
        NSString *x1 = [[NSString alloc]initWithFormat:@"%@",pointArry[i+1][0]];
        NSString *y1 = [[NSString alloc]initWithFormat:@"%@",pointArry[i+1][1]];
        UIImageView *imageView=[[UIImageView alloc] initWithFrame:self.backview.frame];
        imageView.tag =100+i;
        [self.backview addSubview:imageView];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 30.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), _MAP_WIDTH*([x floatValue]/30.0)+5, _MAP_HIGH*([y floatValue]/30)+5);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), _MAP_WIDTH*([x1 floatValue]/30.0)+5, _MAP_HIGH*([y1 floatValue]/30)+5);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
}
- (void)bannerStart{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
}
- (void)updateTimer
{
    NSLog(@"当前线程：%@",[NSThread currentThread]);
    NSLog(@"启动RunLoop后--%@",[NSRunLoop currentRunLoop].currentMode);
    NSLog(@"currentRunLoop:%@",[NSRunLoop currentRunLoop]);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"1");
    });
}
//告诉scrollview要缩放的是哪个子控件
 -(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
 return _map;
}
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    NSLog(@"%@",view);
    _point.hidden=YES;
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale
{
    _point.hidden=YES;
    NSLog(@"scale = %lf",scale);
//    _mCount =_sum*scale;
//    _distance =10*scale;
    _MAP_HIGH =scrollView.contentSize.height;
    _MAP_WIDTH =1000*scale;
    _scales = scale;
    //因为其始终以自身左上角为坐标原点，所以只能修改尺寸，修改位置不会改变
    CGRect tempBounds   = self.point.bounds;
    
    tempBounds.size.height=20*_scales;
    
    tempBounds.size.width=20*_scales;
    
    self.point.bounds=tempBounds;
    self.point.layer.cornerRadius = 10*_scales;
    [self setChangePath:_point_arr];
    _hiddentime = 10000;
}

- (IBAction)start:(id)sender {
    _mCount=0;
//    self.map.transform = CGAffineTransformMakeRotation(M_PI_2);
}

- (void)timers:(NSTimer *)timer
{
    NSArray *point = [[NSArray alloc]initWithArray:_point_arr[_mCount]];
    NSString *x =[[NSString alloc]initWithFormat:@"%@",point[0]];
    NSString *y =[[NSString alloc]initWithFormat:@"%@",point[1]];
    //    self.point.frame =CGRectMake(_MAP_WIDTH*([x integerValue]/30.0),_MAP_HIGH*([y integerValue]/30.0)-5, 20*_scales, 20*_scales);
    
    CGPoint pointS = CGPointMake(_MAP_WIDTH*([x integerValue]/30.0),_MAP_HIGH*([y integerValue]/30.0));
    [self animateWith:pointS];
    _hiddentime++;
    if(_hiddentime == 10002)
    _point.hidden=NO;
    if(_mCount<32)
    {
    _mCount++;
        [_scrollview setContentOffset:CGPointMake(((int)(_MAP_WIDTH*([x integerValue]/30.0))/DEVICE_WIDTH)*DEVICE_WIDTH-DEVICE_WIDTH/2.0,0) animated:YES];
    }

}

//这里调用封装好的CABasic动画,传了一个参数用来指定position目的点
-(void)animateWith:(CGPoint )point {
    
    //NSNumber转化,可以将CGFloat等简单的数值转换成对象类型
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    //动画时间
    animation.duration = 0.5;
    //动画的起点和终点
    animation.fromValue = [NSValue valueWithCGPoint: self.point.layer.position];
    animation.toValue = [NSValue valueWithCGPoint:point];
    [self.point.layer addAnimation:animation forKey:@"动画名称"];
    //动画结束后把imageview的position改变到目的点
    self.point.layer.position = point;
    
    
}


//别忘了释放掉
-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}



- (UIView *)point
{
    if (!_point) {
        _point = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 20, 20)];
        _point.backgroundColor = [UIColor blueColor];
        _point.layer.cornerRadius = 10;
        _point.layer.masksToBounds=YES;
    }
    return _point;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//强制转屏
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector  = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        // 从2开始是因为0 1 两个参数已经被selector和target占用
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
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
