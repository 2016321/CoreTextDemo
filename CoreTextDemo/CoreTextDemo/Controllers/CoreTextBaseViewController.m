//
//  CoreTextBaseViewController.m
//  CoreTextDemo
//
//  Created by Bingo on 2018/7/9.
//  Copyright © 2018年 Bingo. All rights reserved.
//

#import "CoreTextBaseViewController.h"

@interface CoreTextBaseViewController ()

@property (nonatomic, strong) UIView *coreTextView;

@end

@implementation CoreTextBaseViewController

-(UIView *)coreTextView{
    if (!_coreTextView) {
        Class cls = NSClassFromString(self.viewClass);
        _coreTextView = [cls new];
        _coreTextView.backgroundColor = [UIColor whiteColor];
    }
    return _coreTextView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.coreTextView];
    NSLog(@"%@", [UIFont familyNames]);
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    CGFloat topInset = 0, bottomInset = 0;
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets inset = self.view.safeAreaInsets;
        topInset = inset.top;
        bottomInset = inset.bottom;
    }
    _coreTextView.frame = CGRectMake(0, topInset, self.view.bounds.size.width, self.view.bounds.size.height - topInset - bottomInset);
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
