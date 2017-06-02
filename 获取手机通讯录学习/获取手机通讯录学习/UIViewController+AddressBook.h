//
//  UIViewController+AddressBook.h
//  获取联系人信息
//
//  Created by qwkj on 16/12/27.
//  Copyright © 2016年 andy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WZ_Contact : NSObject

/**
 联系人姓名
 */
@property(copy,nonatomic)NSString *contactName;

/**
 联系人手机号数组
 */
@property(copy,nonatomic)NSArray<NSString *> *phoneNumbers;
@end


typedef void(^WZ_SelectPerosonCallBack)(WZ_Contact *contact);
typedef void(^WZ_FetchContactCompleteBlock)(NSMutableArray<WZ_Contact *> *contacts);

@interface UIViewController (AddressBook)
/**
 调用系统通讯录，

 @param selectPersonBlcok 选择联系人后的回调
 */
- (void)WZ_JudgeAddressBookPicker:(WZ_SelectPerosonCallBack )selectPersonBlcok;

/**
 获取通讯录中所有联系人，方法为异步，回调时自动回到main线程

 @param fetchCompleteBlock 获取到联系人后的回调
 */
- (void)WZ_fetchAllContact:(WZ_FetchContactCompleteBlock )fetchCompleteBlock;
@end
