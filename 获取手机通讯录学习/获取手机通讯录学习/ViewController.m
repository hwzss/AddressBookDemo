//
//  ViewController.m
//  获取手机通讯录学习
//
//  Created by qwkj on 2017/6/2.
//  Copyright © 2017年 qwkj. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+AddressBook.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)goToSelectContactAction:(id)sender {
    [self WZ_JudgeAddressBookPicker:^(WZ_Contact *contact) {
         NSLog(@"%s",__func__);
    }];
}
- (IBAction)fetchAllContactsAction:(id)sender {
    [self WZ_fetchAllContact:^(NSMutableArray<WZ_Contact *> *contacts) {
         NSLog(@"%s",__func__);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
