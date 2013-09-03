//
//  DZPullDownViewController.h
//  DZPullDownViewController
//
//  Created by dzpqzb on 13-9-3.
//  Copyright (c) 2013年 dzpqzb inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DZPullDownViewController : UIViewController
- (id) initWithBottom:(UIViewController*)bottomViewController top:(UIViewController*)topViewController;
@property (nonatomic,retain,readonly) UIViewController* bottomViewController;
@property (nonatomic, retain, readonly) UIViewController* topViewController;
@end
