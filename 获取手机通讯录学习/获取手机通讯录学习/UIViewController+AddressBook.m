//
//  UIViewController+AddressBook.m
//  获取联系人信息
//
//  Created by qwkj on 16/12/27.
//  Copyright © 2016年 andy. All rights reserved.
//

#import "UIViewController+AddressBook.h"
#import <objc/runtime.h>
/// iOS 9前的框架
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
/// iOS 9的新框架
#import <ContactsUI/ContactsUI.h>
#import <Contacts/Contacts.h>

#define Is_up_Ios_9 ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0)

#define Is_Ios_8 ([[UIDevice currentDevice].systemVersion floatValue] == 8.0)

#define Safe_ReleaseCFType(value) \
    if (value)                    \
    {                             \
        CFRelease((value));       \
    }
#define NO_NULL_Str(value) value ? value : @""

@interface WZ_Contact ()

+ (instancetype)WZ_ContactWithName:(NSString *)name PhoneNumbers:(NSArray<NSString *> *)phoneNumbers;
@end
@implementation WZ_Contact

+ (instancetype)WZ_ContactWithName:(NSString *)name PhoneNumbers:(NSArray<NSString *> *)phoneNumbers
{
    WZ_Contact *contact = [[WZ_Contact alloc] init];
    contact.contactName = name;
    contact.phoneNumbers = phoneNumbers;
    return contact;
}
@end
@interface UIViewController () <ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate>

@property (copy, nonatomic) WZ_FetchContactCompleteBlock fetchCompleteBlock;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation UIViewController (AddressBook)

- (WZ_FetchContactCompleteBlock)fetchCompleteBlock
{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setFetchCompleteBlock:(WZ_FetchContactCompleteBlock)fetchCompleteBlock
{
    objc_setAssociatedObject(self, @selector(fetchCompleteBlock), fetchCompleteBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (WZ_SelectPerosonCallBack)WZ_selectPersonBlock
{
    return objc_getAssociatedObject(self, @selector(WZ_selectPersonBlock));
}
- (void)WZ_setSelectPersonBlcok:(WZ_SelectPerosonCallBack)selectPersonBlock
{
    objc_setAssociatedObject(self, @selector(WZ_selectPersonBlock), selectPersonBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
#pragma mark---- 调用系统通讯录
- (void)WZ_JudgeAddressBookPicker:(WZ_SelectPerosonCallBack)selectPersonBlcok
{
    //设置选择联系人回调
    [self WZ_setSelectPersonBlcok:selectPersonBlcok];
    ///获取通讯录权限，调用系统通讯录
    [self CheckAddressBookAuthorization:^(bool isAuthorized) {
        if (isAuthorized)
        {
            [self callAddressBook];
        }
        else
        {
            NSLog(@"请到设置>隐私>通讯录打开本应用的权限设置");
        }
    }];
}
- (void)WZ_fetchAllContacts:(WZ_FetchContactCompleteBlock)fetchCompleteBlock
{
    self.fetchCompleteBlock = fetchCompleteBlock;
    [self CheckAddressBookAuthorization:^(bool isAuthorized) {
        if (isAuthorized)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableArray *contacts = [self WZ_fetchAllContact];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.fetchCompleteBlock)
                    {
                        self.fetchCompleteBlock(contacts);
                    }
                });
            });
        }
        else
        {
            NSLog(@"请到设置>隐私>通讯录打开本应用的权限设置");
        }
    }];
}
#pragma - mark 获取所有通讯录信息
- (NSMutableArray *)WZ_fetchAllContact
{
    NSMutableArray *contacts = [NSMutableArray new];
    if (Is_up_Ios_9)
    {
        NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactPhoneNumbersKey];
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
        CNContactStore *contactStore = [[CNContactStore alloc] init];
        [contactStore enumerateContactsWithFetchRequest:request
                                                  error:nil
                                             usingBlock:^(CNContact *_Nonnull contact, BOOL *_Nonnull stop) {
                                                 NSMutableArray *phoneArr = [NSMutableArray new];

                                                 for (CNLabeledValue *labelValue in contact.phoneNumbers)
                                                 {
                                                     CNPhoneNumber *number = labelValue.value;
                                                     NSString *phone = [self clearPhone:number.stringValue];
                                                     [phoneArr addObject:phone];
                                                 }
                                           
                                                 NSString *givenName =@"";
                                                 NSString *familyName =@"";
                                                 NSSet *availableKeys =[contact valueForKey:@"availableKeys"];
                                                 if (availableKeys&&[availableKeys containsObject:@"givenName"]) {
                                                     givenName = contact.givenName;
                                                 }
                                                 if (availableKeys&&[availableKeys containsObject:@"familyName"]) {
                                                     givenName = contact.familyName;
                                                 }
                                                 WZ_Contact *model = [WZ_Contact WZ_ContactWithName:[NSString stringWithFormat:@"%@%@", givenName, familyName] PhoneNumbers:phoneArr.copy];
                                                 [contacts addObject:model];
                                             }];
    }
    else
    {
        ABAddressBookRef addressbookRef = ABAddressBookCreate();
        CFArrayRef arrayRef = ABAddressBookCopyArrayOfAllPeople(addressbookRef);
        long count = CFArrayGetCount(arrayRef);
        for (int i = 0; i < count; i++)
        {
            ABRecordRef people = CFArrayGetValueAtIndex(arrayRef, i);
            //姓
            NSString *firstName = (__bridge NSString *) (ABRecordCopyValue(people, kABPersonFirstNameProperty));
            //名字
            NSString *familyName = (__bridge NSString *) (ABRecordCopyValue(people, kABPersonLastNameProperty));
            NSMutableArray *phoneArr = [NSMutableArray new];
            ABMultiValueRef phones = ABRecordCopyValue(people, kABPersonPhoneProperty);
            for (int j = 0; j < ABMultiValueGetCount(phones); j++)
            {
                NSString *phone = (__bridge NSString *) ABMultiValueCopyValueAtIndex(phones, j);
                [phoneArr addObject:[self clearPhone:phone]];
                Safe_ReleaseCFType((__bridge CFTypeRef) phone);
            }
            WZ_Contact *model = [WZ_Contact WZ_ContactWithName:[NSString stringWithFormat:@"%@%@", NO_NULL_Str(firstName), NO_NULL_Str(familyName)] PhoneNumbers:phoneArr.copy];
            [contacts addObject:model];
            Safe_ReleaseCFType((__bridge CFTypeRef) firstName);
            Safe_ReleaseCFType((__bridge CFTypeRef) familyName);
            Safe_ReleaseCFType(phones);
        }
        Safe_ReleaseCFType(arrayRef);
        Safe_ReleaseCFType(addressbookRef);
    }
    return contacts;
}

#pragma - mark 获取权限
- (void)CheckAddressBookAuthorization:(void (^)(bool isAuthorized))block
{
    if (Is_up_Ios_9)
    {
        CNContactStore *contactStore = [[CNContactStore alloc] init];
        if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusNotDetermined)
        {
            [contactStore requestAccessForEntityType:CNEntityTypeContacts
                                   completionHandler:^(BOOL granted, NSError *__nullable error) {
                                       if (error)
                                       {
                                           NSLog(@"Error: %@", error);
                                       }
                                       else if (!granted)
                                       {

                                           block(NO);
                                       }
                                       else
                                       {
                                           block(YES);
                                       }
                                   }];
        }
        else if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized)
        {
            block(YES);
        }
        else
        {
            NSLog(@"请到设置>隐私>通讯录打开本应用的权限设置");
        }
    }
    else
    {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();

        if (authStatus == kABAuthorizationStatusNotDetermined)
        {
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error)
                    {
                        NSLog(@"Error: %@", (__bridge NSError *) error);
                    }
                    else if (!granted)
                    {

                        block(NO);
                    }
                    else
                    {
                        block(YES);
                    }
                });
            });
        }
        else if (authStatus == kABAuthorizationStatusAuthorized)
        {
            block(YES);
        }
        else
        {
            NSLog(@"请到设置>隐私>通讯录打开本应用的权限设置");
        }
        Safe_ReleaseCFType(addressBook);
    }
}

- (void)callAddressBook
{
    if (Is_up_Ios_9)
    {
        CNContactPickerViewController *contactPicker = [[CNContactPickerViewController alloc] init];
        contactPicker.delegate = self;
        contactPicker.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
        [self presentViewController:contactPicker animated:YES completion:nil];
    }
    else
    {
        ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
        peoplePicker.peoplePickerDelegate = self;
        if (Is_Ios_8)
        {
            peoplePicker.predicateForSelectionOfPerson = [NSPredicate predicateWithValue:false];
        }
        [self presentViewController:peoplePicker animated:YES completion:nil];
    }
}

#pragma mark-- CNContactPickerDelegate
//＊＊＊＊这里会继续跳往通讯录用户详情，由于怕用户不知道如何操作故去掉了，若要用，请注释contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact那个方法
//- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty {
//    CNPhoneNumber *phoneNumber = (CNPhoneNumber *)contactProperty.value;
//    [self dismissViewControllerAnimated:YES completion:^{
//        /// 联系人
//        NSString *name = [NSString stringWithFormat:@"%@%@",contactProperty.contact.familyName,contactProperty.contact.givenName];
//        /// 电话
//        NSString *phone = phoneNumber.stringValue;
//        phone=[self clearPhone:phone];
//        if([self WZ_selectPersonBlock]){
//            [self WZ_selectPersonBlock](name,phone);
//        }
//        NSLog(@"联系人：%@, 电话：%@",name,phone);
//    }];
//}
- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact
{

    // 6.1 获取姓名
    NSString *givenName = contact.givenName;
    NSString *familyName = contact.familyName;
    NSLog(@"%@--%@", givenName, familyName);

    // 6.2 获取电话
    NSArray *phoneNumbers = contact.phoneNumbers;

    NSMutableArray *phoneArr = [NSMutableArray new];

    for (CNLabeledValue *labelValue in phoneNumbers)
    {
        CNPhoneNumber *number = labelValue.value;
        NSString *phone = [self clearPhone:number.stringValue];
        [phoneArr addObject:phone];
    }
    /// 联系人
    NSString *name = [NSString stringWithFormat:@"%@%@", NO_NULL_Str(familyName), NO_NULL_Str(givenName)];
    [self dismissViewControllerAnimated:YES
                             completion:^{

                                 if ([self WZ_selectPersonBlock])
                                 {
                                     WZ_Contact *contact = [WZ_Contact WZ_ContactWithName:name PhoneNumbers:phoneArr];
                                     [self WZ_selectPersonBlock](contact);
                                 }
                             }];
}
#pragma mark-- ABPeoplePickerNavigationControllerDelegate
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
{
    //获取联系人对象的引用
    ABRecordRef people = person;
    NSString *name = (__bridge NSString *) (ABRecordCopyCompositeName(people));

    //获取当前联系人的电话 数组
    NSMutableArray *phoneArr = [[NSMutableArray alloc] init];
    ABMultiValueRef phones = ABRecordCopyValue(people, kABPersonPhoneProperty);
    for (NSInteger j = 0; j < ABMultiValueGetCount(phones); j++)
    {
        NSString *phone = (__bridge NSString *) (ABMultiValueCopyValueAtIndex(phones, j));
        [phoneArr addObject:[self clearPhone:phone]];
        Safe_ReleaseCFType((__bridge CFTypeRef)(phone));
    }
    Safe_ReleaseCFType(phones);
//    Safe_ReleaseCFType(people);people方法内部并没有retain不应该relase。
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 if ([self WZ_selectPersonBlock])
                                 {
                                     WZ_Contact *contact = [WZ_Contact WZ_ContactWithName:name PhoneNumbers:phoneArr];
                                     [self WZ_selectPersonBlock](contact);
                                 }
                             }];
}
//＊＊＊＊这里会继续跳往通讯录用户详情，由于怕用户不知道如何操作故去掉了，若要用，请注释peoplePickerNavigationController:didSelectPerson:person那个方法
//- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
//
//    ABMultiValueRef valuesRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
//    CFIndex index = ABMultiValueGetIndexForIdentifier(valuesRef,identifier);
//    CFStringRef value = ABMultiValueCopyValueAtIndex(valuesRef,index);
//    CFStringRef anFullName = ABRecordCopyCompositeName(person);
//
//    [self dismissViewControllerAnimated:YES completion:^{
//        /// 联系人
//        NSString *name = [NSString stringWithFormat:@"%@",anFullName];
//        /// 电话
//        NSString *phone = (__bridge NSString*)value;
//        phone=[self clearPhone:phone];
//        if([self WZ_selectPersonBlock]){
//            [self WZ_selectPersonBlock](name,phone);
//        }
//        NSLog(@"联系人：%@, 电话：%@",name,phone);
//    }];
//}

-(NSString *)clearPhone:(NSString *)phoneFullName{
    //除去区号与@“－”
    NSString *phone = phoneFullName;
    if ([phone hasPrefix:@"+"]) {
        phone = [phone substringFromIndex:3];
    }
    phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return phone;
}
@end

#pragma clang diagnostic pop
