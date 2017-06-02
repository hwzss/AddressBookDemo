# AddressBookDemo
集成addresBook工具分类
一个分类集成跳往通讯录选择联系人功能，获取所有联系人功能

```
  //push到 选择联系人界面
 [self WZ_JudgeAddressBookPicker:^(WZ_Contact *contact) {
         //contact为选择的联系人
    }];
```

```
//获取通讯录中的所有联系人
[self WZ_fetchAllContact:^(NSMutableArray<WZ_Contact *> *contacts) {
        //获取到的联系人数组
    }];
```

#以下是大致分类原理介绍
![孤独的介绍demo.png](https://github.com/hwzss/AddressBookDemo/blob/master/UIViewController+AddressBook.png?raw=true)

