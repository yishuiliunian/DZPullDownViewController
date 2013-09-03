//
//  DZPullDownViewController.m
//  DZPullDownViewController
//
//  Created by dzpqzb on 13-9-3.
//  Copyright (c) 2013年 dzpqzb inc. All rights reserved.
//

#import "DZPullDownViewController.h"
static float const kAnimationDuration = 0.25;


@protocol DZTopViewControllderProtocol <NSObject>

- (UIViewController*)_dztopViewController;

@end

@interface UIViewController (_pan_innder) <DZTopViewControllderProtocol>

@end

@implementation UIViewController (_pan_innder)

- (UIViewController*) _dztopViewController
{
    return self;
}

@end

@interface UINavigationController (_pan_innder) <DZTopViewControllderProtocol>

@end

@implementation UINavigationController (_pan_innder)

- (UIViewController*) _dztopViewController
{
    return self.topViewController;
}

@end

@interface UITabBarController (_pan_innder) <DZTopViewControllderProtocol>

@end

@implementation UITabBarController(_pan_innder)

- (UIViewController*) _topViewController
{
    return [self.selectedViewController _dztopViewController];
}
@end



////////////////////////////
typedef enum {
    DZTopViewControllerStatueFullScreen,
    DZTopViewControllerStatueBottomToggled,
    DZTopViewControllerStatueMoving
    
}DZTopViewControllerStatues;
///
typedef enum {
    DZBookDirectionNone,
    DZBookDirectionLeft,
    DZBookDirectionRight,
    DZBookDirectionTop,
    DZBookDirectionDown
    
} DZBookDirection;

CGFloat CGPointDistance(CGPoint point1, CGPoint point2)
{
    return sqrt(pow((point2.x - point1.x), 2) + pow(point2.y -point2.y , 2 ));
}

CGRect CGRectSetY(CGRect rect, CGFloat y) {
	return CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height);
}

typedef struct {
private: DZBookDirection _lastDirection;
    
public:    CGPoint beginPoint;
    CGPoint endPoint;
    BOOL isMoving;
    CGPoint lastPoint;
    
    void setEndPoint(CGPoint point)
    {
        _lastDirection = moveDirection();
        if(CGPointEqualToPoint(endPoint, CGPointZero))
        {
            lastPoint = point;
        }
        else
        {
            lastPoint = endPoint;
        }
        endPoint = point;
        DZBookDirection nDirection = moveDirection();
        if(_lastDirection != DZBookDirectionNone && _lastDirection != nDirection)
        {
            beginPoint = point;
        }
    }
    
    float moveDistance()
    {
        return ABS(beginPoint.y - endPoint.y);
    }
    
    float moveStepDistance()
    {
        return  endPoint.y - lastPoint.y;
    }
    
    DZBookDirection moveDirection()
    {
        DZBookDirection direction;
        if(CGPointEqualToPoint(lastPoint, endPoint))
        {
            direction = _lastDirection;
        }
        if(lastPoint.y > endPoint.y)
        {
            direction = DZBookDirectionDown;
        }
        else
        {
            direction = DZBookDirectionTop;
        }
        NSLog(@"direction %d",direction);
        return direction;
    }
    
    void clearData()
    {
        beginPoint = CGPointZero;
        endPoint = CGPointZero;
        isMoving = NO;
        _lastDirection = DZBookDirectionNone;
    }
}DZBookMove;


////////////////
float(^kDZBottomSlideOffSet)(UIViewController*, float) = ^(UIViewController* viewController, float percent)
{
     return  CGRectGetHeight(viewController.view.frame) * percent;
};

#define kDZPullDownToggledOffSetTopPercent 0.318
#define KDZPullDownToggledBottomOffSetTop kDZBottomSlideOffSet(self, kDZPullDownToggledOffSetTopPercent)

#define kDZPullUpToggledOffSetTopPercent 0.682
#define kDZPullUpToggledUpOffSetTop kDZBottomSlideOffSet(self, kDZPullUpToggledOffSetTopPercent)

#define KDZBottomToggledOffSet 80

@interface DZPullDownViewController () <UIGestureRecognizerDelegate>
{
    UIViewController* _bottomViewController;
    UIViewController* _topViewController;
    UIPanGestureRecognizer* _topPanGestrueRecognizer;
    DZTopViewControllerStatues _topViewControllerStatue;
    UITapGestureRecognizer* _topTapGestureRecognizer;
    //
    DZBookMove _moveData;
    
}
@end

@implementation DZPullDownViewController
@synthesize bottomViewController = _bottomViewController;
@synthesize topViewController = _topViewController;

- (id) initWithBottom:(UIViewController *)bottomViewController top:(UIViewController *)topViewController
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _bottomViewController = bottomViewController;
    _topViewController = topViewController;
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) drawTopViewControllerShadows
{
    CALayer* layer = _topViewController.view.layer;
    layer.shadowColor = [UIColor grayColor].CGColor;
    layer.shadowOffset = CGSizeMake(5, -5);
    layer.shadowOpacity = 0.5;
    layer.shadowRadius = 5;
    
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void) replaceTopViewControllerWith:(UIViewController*)topViewController
{
    if (_topViewController) {
        [_topViewController willMoveToParentViewController:nil];
        [_topViewController.view removeFromSuperview];
        [_topViewController removeFromParentViewController];
        [_topViewController didMoveToParentViewController:nil];
    }
    if (!topViewController) {
        return;
    }
    
    _topViewController = topViewController;
    [_topViewController willMoveToParentViewController:self];
    [self addChildViewController:_topViewController];
    [self.view addSubview:_topViewController.view];
    _topViewController.view.frame = self.view.bounds;
    _topPanGestrueRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPerformPanGestureRecoginzer:)];
    [_topViewController.view addGestureRecognizer:_topPanGestrueRecognizer];
    _topPanGestrueRecognizer.delegate = self;
    [_topViewController didMoveToParentViewController:self];
    [self drawTopViewControllerShadows];
    _topViewControllerStatue = DZTopViewControllerStatueFullScreen;
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    _topTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didPerformTap:)];
    _topTapGestureRecognizer.numberOfTapsRequired = 1;
    _topTapGestureRecognizer.numberOfTouchesRequired = 1;
    [_topViewController.view addGestureRecognizer:_topTapGestureRecognizer];
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
}
- (void) setTopViewScreenEdgeGestureEnable:(BOOL)enable
{
    if ([_topViewController isKindOfClass:[UINavigationController class]]) {
        NSArray* gestures = _topViewController.view.gestureRecognizers;
        for (UIGestureRecognizer* each  in gestures) {
            if ([each isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
                each.enabled = enable;
            }
        }
    }
}

- (void) setTopViewControllerStatue:(DZTopViewControllerStatues)statue animation:(BOOL)animation
{
    if (animation) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            [self setTopViewControllerStatue:statue animation:NO];
        } completion:^(BOOL finished) {
            
        }];
    }
    else
    {
        switch (statue) {
            case DZTopViewControllerStatueFullScreen:
                _topViewController.view.frame = self.view.bounds;
                [self setTopViewScreenEdgeGestureEnable:YES];
                break;
            case DZTopViewControllerStatueBottomToggled:
                _topViewController.view.frame = CGRectMake(0, CGRectGetHeight(self.view.frame) - KDZBottomToggledOffSet, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
                [self setTopViewScreenEdgeGestureEnable:NO];
                break;
            case DZTopViewControllerStatueMoving:
            default:
                break;
        }
    }
    _topViewControllerStatue = statue;
    
}

- (void) setTopViewControllerYCoordiate:(float)y
{
    _topViewController.view.frame = CGRectSetY(_topPanGestrueRecognizer.view.frame, y);
}


- (void) didPerformPanGestureRecoginzer:(UIGestureRecognizer*)recognizer
{
    if (recognizer != _topPanGestrueRecognizer) {
        return;
    }
    
    
    CGPoint location = [recognizer locationInView:self.view];
    //
    UIViewController* _topVC = [self.topViewController _dztopViewController];
    UIView* topView = _topVC.view;
    if (![topView isKindOfClass:[UIScrollView class]]) {
        NSArray* subViews = topView.subviews;
        for (UIView* each  in subViews) {
            if ([each isKindOfClass:[UIScrollView class]]) {
                topView = each;
                break;
            }
        }
    }
    
    if ([topView isKindOfClass:[UIScrollView class]]) {
        UIScrollView* scrollView = (UIScrollView*)topView;
        float contentOffSetY = scrollView.contentOffset.y + scrollView.contentInset.top;
        if (_topViewControllerStatue == DZTopViewControllerStatueFullScreen) {
            if (contentOffSetY > -10) {
                return;
            }
        }
        else if (_topViewControllerStatue == DZTopViewControllerStatueMoving)
        {
            scrollView.contentOffset = CGPointMake(0, -scrollView.contentInset.top - 10);
        }
    }
    
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _moveData.beginPoint = location;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if(_topViewControllerStatue == DZTopViewControllerStatueBottomToggled || _topViewControllerStatue == DZTopViewControllerStatueFullScreen)
        {
            _moveData.beginPoint = location;
        }
        _moveData.setEndPoint(location);
        float moveStep = _moveData.moveStepDistance();
        [UIView animateWithDuration:kAnimationDuration animations:^{
            [self setTopViewControllerYCoordiate:CGRectGetMinY(self.topViewController.view.frame) + moveStep];
        }];
        [self setTopViewControllerStatue:DZTopViewControllerStatueMoving animation:YES];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        switch (_moveData.moveDirection()) {
            case DZBookDirectionTop:
                NSLog(@"top");
                break;
            case DZBookDirectionDown:
                NSLog(@"down");
            default:
                break;
        }
        
        NSLog(@"%f %f %f",CGRectGetMinY(self.topViewController.view.frame), kDZPullUpToggledUpOffSetTop, KDZPullDownToggledBottomOffSetTop);
        
        if(CGRectGetMinY(self.topViewController.view.frame) > KDZPullDownToggledBottomOffSetTop )
        {
             [self setTopViewControllerStatue:DZTopViewControllerStatueBottomToggled animation:YES];
        }
        else if (CGRectGetMinY(self.topViewController.view.frame) > kDZPullUpToggledUpOffSetTop)
        {
             [self setTopViewControllerStatue:DZTopViewControllerStatueFullScreen animation:YES];
        }
        else
        {
            [self setTopViewControllerStatue:DZTopViewControllerStatueFullScreen animation:YES];
        }
        //
        //
        //
        _moveData.clearData();
        
    }

}

- (void) didPerformTap:(UITapGestureRecognizer*)tapGestureRecognizer
{
    if (tapGestureRecognizer != _topTapGestureRecognizer) {
        return;
    }
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (_bottomViewController) {
        [_bottomViewController willMoveToParentViewController:self];
        [self addChildViewController:_bottomViewController];
        [self.view addSubview:_bottomViewController.view];
        _bottomViewController.view.frame = self.view.bounds;
        [_bottomViewController didMoveToParentViewController:self];
    }
    
    [self replaceTopViewControllerWith:_topViewController];
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
