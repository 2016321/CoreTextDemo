
//
//  HomeTableViewController.m
//  CoreTextDemo
//
//  Created by Bingo on 2018/7/9.
//  Copyright © 2018年 Bingo. All rights reserved.
//

#import "HomeTableViewController.h"

#import "CoreTextBaseViewController.h"

#define CellID @"cellID"

@interface HomeTableViewController ()

@property (nonatomic, copy) NSArray *dataArr;

@end

@implementation HomeTableViewController

- (NSArray *)dataArr{
    if (!_dataArr) {
        _dataArr = @[
                     @{
                         @"title": @"Base",
                         @"vc": @"CoreTextBaseView"
                         },
                     @{
                         @"title": @"图文混排",
                         @"vc": @"CoreTextImageView"
                         },
                     @{
                         @"title": @"点击回调",
                         @"vc": @"CoreTextClickView"
                         },
                     @{
                         @"title": @"文字点击高亮",
                         @"vc": @"CoreTextHighlightView"
                         },
                     ];
    }
    return _dataArr;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Demo";
    self.tableView.rowHeight = 44;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellID];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID forIndexPath:indexPath];
    cell.textLabel.text = self.dataArr[indexPath.row][@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CoreTextBaseViewController *vc = [CoreTextBaseViewController new];
    vc.viewClass = _dataArr[indexPath.row][@"vc"];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
