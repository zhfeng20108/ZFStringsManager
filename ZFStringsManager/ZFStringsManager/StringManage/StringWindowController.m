//
//  StringWindowController.m
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringWindowController.h"
#import "StringModel.h"
#import "StringManage.h"
#import "PreferencesWindowController.h"
#import "StringSetting.h"
#import "StringInfoViewController.h"
#import "NSButton+Extension.h"
#import "NSString+Extension.h"
#import "StringEditViewController.h"
#import "WarningWindowController.h"

#define kStrKey @"key"
#define kRemove @"remove"
#define kInfo @"info"
#define kRowNo @"rowno"

#define kFont [NSFont systemFontOfSize:11]

@interface StringWindowController()

@property (nonatomic, strong)IBOutlet NSTableView *tableview;
@property (weak) IBOutlet NSButton *refreshBtn;
@property (weak) IBOutlet NSButton *saveBtn;
@property (weak) IBOutlet NSButton *saveSyncBtn;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *tipsLabel;
@property (weak) IBOutlet NSTextField *recordLabel;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSButton *addBtn;
@property (weak) IBOutlet NSButton *CheckBtn;
@property (weak) IBOutlet NSProgressIndicator *checkIndicator;
@property (weak) IBOutlet NSButton *showOnlyBtn;
@property (weak) IBOutlet NSButton *untranslatedBtn;
@property (weak) IBOutlet NSButton *unusedBtn;
@property (weak) IBOutlet NSButton *errorBtn;
@property (weak) IBOutlet NSTextField *toastLabel;
@property (weak) IBOutlet NSView *hud;
@property (weak) IBOutlet NSPopUpButton *tableBtn;
@property (weak) IBOutlet NSProgressIndicator *syncIndicator;

@property (nonatomic, strong) NSMutableArray *stringArray;
@property (nonatomic, strong) NSMutableArray *keyArray;
@property (nonatomic, strong) NSMutableArray *actionArray;
@property () PreferencesWindowController* prefsController;
@property (nonatomic, strong) NSArray *showArray;
@property (nonatomic, copy) NSString* projectPath;
@property (nonatomic, copy) NSString* projectName;
@property (nonatomic, strong) NSMutableDictionary* infoDict;
@property (nonatomic) BOOL isRefreshing;
@property (nonatomic, strong) NSMutableDictionary* keyDict;
@property (nonatomic) BOOL isChecking;
@property (nonatomic, strong) NSPopover* editPopOver;
@property (nonatomic, strong) NSPopover* infoPopOver;
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic, strong) NSString *sortingCol;
@property (nonatomic) BOOL ascending;
@property (nonatomic, strong) NSMutableDictionary *columnTitleDict;
@property (nonatomic, strong) StringModel *hansModel;
@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, strong) WarningWindowController *warningWindowCtrl;

- (IBAction)addAction:(id)sender;
- (IBAction)saveAction:(id)sender;
- (IBAction)searchAnswer:(id)sender;
- (IBAction)checkAction:(id)sender;
@end

@implementation StringWindowController

#pragma mark - override

-(instancetype)init{
    if(self = [super initWithWindowNibName:@"StringWindowController"])
    {
        //perform any initializations
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    self.prefsController = [[PreferencesWindowController alloc] init];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.sortingCol = kStrKey;
    self.ascending = YES;
    self.hud.hidden = YES;
    self.syncIndicator.hidden = YES;
    
    self.columnTitleDict = [[NSMutableDictionary alloc] init];
    self.actionArray=[[NSMutableArray alloc]init];
    self.stringArray = [[NSMutableArray alloc]init];
    self.keyArray = [[NSMutableArray alloc]init];
    self.infoDict = [[NSMutableDictionary alloc]init];
    self.keyDict = [[NSMutableDictionary alloc]init];
    
    self.window.level = NSNormalWindowLevel;
    //    self.window.hidesOnDeactivate = YES;
    [self.window setTitle:[NSString stringWithFormat:@"%@ ( V%@ )",LocalizedString(@"StringManage"),[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]]];
    
    self.tableview.delegate=self;
    self.tableview.dataSource = self;
    self.tableview.action = @selector(cellClicked:);//点击编辑
    self.tableview.doubleAction = @selector(doubleAction:);//双击撤销修改
    [self.window makeFirstResponder:self.tableview];
    
    [self.showOnlyBtn setTitle:LocalizedString(@"OnlyShowModified")];
    [self.untranslatedBtn setTitle:LocalizedString(@"Untranslated")];
    [self.unusedBtn setTitle:LocalizedString(@"Unused")];
    [self.errorBtn setTitle:@"参数出错(黄色)"];
    [self.searchField setPlaceholderString:LocalizedString(@"Search")];
    [self.saveBtn setTitle:LocalizedString(@"Save")];
    [self.saveSyncBtn setTitle:LocalizedString(@"Save and Sync")];
    [self.refreshBtn setTitle:LocalizedString(@"Refresh")];
    [self.CheckBtn setTitle:LocalizedString(@"Check")];
    [self.tipsLabel setStringValue:LocalizedString(@"UseTips")];
    [self.addBtn setTitle:LocalizedString(@"Add")];
    
    //读取所有的表
    StringSetting *setting = [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
    NSSet *talbeSet = [StringModel tableNamesWithProjectSetting:setting project:self.projectName?:@""];
    
    [self.tableBtn removeAllItems];
    [self.tableBtn addItemsWithTitles:[talbeSet allObjects]];
    if ([self.tableBtn.itemTitles containsObject:[setting.searchTableName stringByDeletingPathExtension]]) {
        [self.tableBtn selectItemWithTitle:[setting.searchTableName stringByDeletingPathExtension]];
    } else if(self.tableBtn.itemTitles.count > 0) {
        [self.tableBtn selectItemAtIndex:0];
        setting.searchTableName = [self.tableBtn.itemTitles[0] stringByAppendingString:@".strings"];
        //重新打开
        [StringModel saveProjectSetting:setting ByProjectName:self.projectName];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectSettingChanged:)  name:kNotifyProjectSettingChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self];
}

#pragma mark - Private
- (void)setSearchRootDir:(NSString*)searchRootDir projectName:(NSString*)projectName {
    self.projectPath = searchRootDir;
    self.projectName = projectName;
    self.prefsController.projectPath = searchRootDir;
    self.prefsController.projectName = projectName;
}

-(void)setIsRefreshing:(BOOL)isRefreshing {
    _isRefreshing = isRefreshing;
    [self.refreshBtn setEnabled:!isRefreshing];
    [self.addBtn setEnabled:!isRefreshing];
    if(isRefreshing)
        [self.progressIndicator startAnimation:nil];
    else
        [self.progressIndicator stopAnimation:nil];
}

-(void)setIsChecking:(BOOL)isChecking{
    _isChecking = isChecking;
    [self.refreshBtn setEnabled:!isChecking];
    [self.addBtn setEnabled:!isChecking];
    [self.CheckBtn setEnabled:!isChecking];
    [self.checkIndicator setHidden:!isChecking];
    if(isChecking)
        [self.checkIndicator startAnimation:nil];
    else
        [self.checkIndicator stopAnimation:nil];
}

-(void)refreshTableView {
    NSArray *columns = [[NSArray alloc]initWithArray:self.tableview.tableColumns];
    for (NSTableColumn *column in columns) {
        [self.tableview removeTableColumn:column];
    }
    
    float columnWidth = (self.tableview.bounds.size.width - 160.0)/(_stringArray.count+1);
    
    NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:kStrKey];
    self.columnTitleDict[kStrKey] = kStrKey;
    [column setWidth:columnWidth];
    [self.tableview addTableColumn:column];
    
    for (StringModel *model in _stringArray) {
        NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:model.identifier];
        self.columnTitleDict[model.identifier] = model.identifier;
        [column setWidth:columnWidth];
        [self.tableview addTableColumn:column];
    }
    
    NSTableColumn * rowNumColumn = [[NSTableColumn alloc] initWithIdentifier:kRowNo];
    self.columnTitleDict[kRowNo] = @"行号";
    [rowNumColumn setWidth:80];
    [rowNumColumn setMinWidth:60];
    [rowNumColumn setMaxWidth:50];
    [self.tableview addTableColumn:rowNumColumn];
    
    NSTableColumn * lastcolumn = [[NSTableColumn alloc] initWithIdentifier:kRemove];
    self.columnTitleDict[kRemove] = LocalizedString(@"Remove");
    [lastcolumn setWidth:80];
    [lastcolumn setMinWidth:60];
    [lastcolumn setMaxWidth:100];
    [self.tableview addTableColumn:lastcolumn];
    NSTableColumn * infocolumn = [[NSTableColumn alloc] initWithIdentifier:kInfo];
    self.columnTitleDict[kInfo] = LocalizedString(@"FoundNum");
    [infocolumn setWidth:80];
    [infocolumn setMinWidth:60];
    [infocolumn setMaxWidth:100];
    [self.tableview addTableColumn:infocolumn];
    
    [self refreshTableColumn];
    [self searchAnswer:nil];
    [self checkAction:nil];
}

-(void)refreshTableColumn{
    NSArray *columns = [NSArray arrayWithArray:self.tableview.tableColumns];
    for (NSTableColumn *column in columns) {
        NSString *cid = column.identifier;
        if ([cid isEqualToString:_sortingCol]) {
            column.title = [NSString stringWithFormat:@"%@ %@", self.columnTitleDict[cid], _ascending?@"▲":@"▼"];
        } else{
            column.title = self.columnTitleDict[cid];
        }
    }
}

-(NSString*)titleWithKey:(NSString*)key identifier:(NSString*)identifier {
    if(key.length==0 || identifier.length == 0)
        return @"";
    if([identifier isEqualToString:kStrKey]) {
        return key;
    }
    ActionModel *action = [self findActionWith:key identify:identifier];
    if(action){
        return action.value.length==0 ? @"" : action.value;
    }
    return [self valueInRaw:key identifier:identifier];
}

-(NSString*)valueInRaw:(NSString*)key  identifier:(NSString*)identifier {
    if([identifier isEqualToString:kStrKey]) {
        return key;
    }
    StringModel *model = [self findStringModelWithIdentifier:identifier];
    if(model){
        NSString *value = model.stringDictionary[key];
        return value.length==0 ? @"" : value;
    }
    return @"";
}

-(ActionModel *)findActionWith:(NSString*)key identify:(NSString*)identify {
    for (ActionModel *model in _actionArray) {
        if([model.key isEqualToString:key] && [model.identifier isEqualToString:identify]){
            return model;
        }
    }
    return nil;
}

-(StringModel*)findStringModelWithIdentifier:(NSString*)identifier {
    for (StringModel *model in _stringArray) {
        if([model.identifier isEqualToString:identifier]){
            return model;
        }
    }
    return nil;
}

-(BOOL)validateKey:(NSString*)key {
    if(key.length==0)
        return NO;
    if([_keyArray containsObject:key]) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText: LocalizedString(@"InputIsExist")];
        [alert addButtonWithTitle: LocalizedString(@"OK")];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        return NO;
    }
    StringSetting *setting = [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
    if (setting.language == StringLanguageSwift) {
        NSString *regex = @"[_a-zA-Z][_a-zA-Z0-9]*";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
        return [predicate evaluateWithObject:key];
    }else{
        return YES;
    }
}

-(void)changeWithKey:(NSString*)key identifier:(NSString*)identifier newValue:(NSString*)newValue {
    NSString *rawValue = [self valueInRaw:key identifier:identifier];
    NSString *oldValue = [self titleWithKey:key identifier:identifier];
    if([oldValue isEqualToString:newValue])
        return;
    ActionModel *action = [self findActionWith:key identify:identifier];
    if(action){
        if([rawValue isEqualToString:newValue]){
            [_actionArray removeObject:action];
        }else{
            action.actionType = (newValue.length==0) ? ActionTypeRemove:ActionTypeAdd;
            action.value = (newValue.length==0) ? rawValue : newValue;
        }
    } else {
        ActionModel *action = [[ActionModel alloc]init];
        action.actionType = (newValue.length==0) ? ActionTypeRemove:ActionTypeAdd;
        action.identifier = identifier;
        action.key = key;
        action.value =  (newValue.length==0) ? rawValue : newValue;
        [_actionArray addObject:action];
    }
    [self searchAnswer:nil];
}

- (void)_sendFeishumsg:(NSString *)errorStr type:(int)type {
    NSString *title = @"";
    if (type == 0) {
        title = @"👏干得漂亮👍多语言没有错误";
    } else if (type == 1) {
        title = @"‼️多语言警告‼️--未翻译的";
    } else if (type == 2) {
        title = @"‼️多语言警告‼️--参数出错的";
    }
    //准备发送httprequest
    NSString *urlString = @"https://open.feishu.cn/open-apis/auth/v3/app_access_token/internal/";
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    //设置http头
    NSString *contentType = [NSString stringWithFormat:@"application/json"];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
     
    StringSetting *setting = [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];

    //创建http内容
    NSString *app_id = setting.feishu_appid;
    NSString *app_secret = setting.feishu_appsecret;
    NSDictionary *bodyDic = @{@"app_id":app_id,@"app_secret":app_secret};
    NSData *postBody = [NSJSONSerialization dataWithJSONObject:bodyDic options:0 error:NULL];
    //设置发送内容
    [request setHTTPBody:postBody];
     
    //获取响应
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask =
    [urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //获取返回的内容
        if (!error)
        {
            NSString *result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSLog(@"Response: %@", result);
            NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:NULL];
            NSString *app_access_token = resultDic[@"app_access_token"];
            //准备发送httprequest
            NSString *urlString = @"https://open.feishu.cn/open-apis/message/v4/send/";
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:[NSURL URLWithString:urlString]];
            [request setHTTPMethod:@"POST"];
            //设置http头
            NSString *contentType = [NSString stringWithFormat:@"application/json"];
            [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
            [request addValue:[NSString stringWithFormat:@"Bearer %@",app_access_token] forHTTPHeaderField:@"Authorization"];
             
            //创建http内容
            NSString *chat_id = setting.feishu_chatid;
            NSString *user_id = setting.feishu_atuserid;
            NSDictionary *bodyDic = @{@"msg_type":@"post",@"chat_id":chat_id,@"content":@{@"post":@{@"zh_cn":@{@"title":title,@"content":@[@[@{@"tag":@"at",@"user_id":user_id}],@[@{@"tag":@"text",@"text":errorStr}]]}}}};
            NSData *postBody = [NSJSONSerialization dataWithJSONObject:bodyDic options:0 error:NULL];
            //设置发送内容
            [request setHTTPBody:postBody];
             
            //获取响应
            NSURLSessionDataTask *dataTask =
            [urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (!error)
                {
                    NSLog(@"飞书消息发送成功");
                } else {
                    NSLog(@"飞书消息发送失败");
                }
            }];
            [dataTask resume];
        } else {
            NSLog(@"飞书消息发送失败");
        }
    }];
    [dataTask resume];
}

#pragma mark - Button Action
- (IBAction)openAbout:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/zhfeng20108/ZFStringsManager"]];
}

- (IBAction)showPreferencesPanel:(id)sender {
    if(self.isRefreshing || self.isChecking)
        return;
    [self.prefsController loadWindow];
    
    NSRect windowFrame = [[self window] frame], prefsFrame = [[self.prefsController window] frame];
    prefsFrame.origin = NSMakePoint(windowFrame.origin.x + (windowFrame.size.width - prefsFrame.size.width) / 2.0,
                                    NSMaxY(windowFrame) - NSHeight(prefsFrame) - 20.0);
    
    [[self.prefsController window] setFrame:prefsFrame display:NO];
    [self.prefsController showWindow:sender];
}

- (IBAction)refresh:(id)sender {
    self.isRefreshing = YES;
    [_actionArray removeAllObjects];
    [self.saveBtn setEnabled:NO];
    StringSetting *setting = [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
    if (self.tableBtn.itemTitles.count < 1) {
        //读取所有的表
        NSSet *talbeSet = [StringModel tableNamesWithProjectSetting:setting project:self.projectName?:@""];
        [self.tableBtn removeAllItems];
        [self.tableBtn addItemsWithTitles:[talbeSet allObjects]];
        if ([self.tableBtn.itemTitles containsObject:[setting.searchTableName stringByDeletingPathExtension]]) {
            [self.tableBtn selectItemWithTitle:[setting.searchTableName stringByDeletingPathExtension]];
        } else if(self.tableBtn.itemTitles.count > 0) {
            [self.tableBtn selectItemAtIndex:0];
            setting.searchTableName = [self.tableBtn.itemTitles[0] stringByAppendingString:@".strings"];
            //重新打开
            [StringModel saveProjectSetting:setting ByProjectName:self.projectName];
        }
    } else {
        [self.tableBtn selectItemWithTitle:[setting.searchTableName stringByDeletingPathExtension]];
    }
    __block NSMutableArray *stringArray = [[NSMutableArray alloc] init];
    __block NSMutableArray *keyArray = [[NSMutableArray alloc] init];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *lprojDirectorys = [StringModel lprojDirectoriesWithProjectSetting:setting project:self.projectPath];
        if (lprojDirectorys.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc]init];
                [alert setMessageText: LocalizedString(@"NoLocalizedFiles")];
                [alert addButtonWithTitle: LocalizedString(@"OK")];
                [alert setAlertStyle:NSAlertStyleInformational];
                [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                    self.isRefreshing = NO;
                }];
            });
        } else {
            NSMutableSet *keySet = [NSMutableSet set];
            for (NSString *path in lprojDirectorys) {
                StringModel *model = [[StringModel alloc]initWithPath:path projectSetting:setting];
                if (model) {
                    [stringArray addObject:model];
                    NSSet *set = [NSSet setWithArray:model.stringDictionary.allKeys];
                    [keySet unionSet:set];
                }
            }
            
            NSArray *tmp = [[NSArray alloc]initWithArray:keySet.allObjects];
            NSArray *sortedArray = [tmp sortedArrayUsingSelector:@selector(compare:)];
            [keyArray addObjectsFromArray:sortedArray];
            self.hansModel = [self findStringModelWithIdentifier:@"zh-Hans"];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.stringArray = stringArray;
                self.keyArray = keyArray;
                [self.keyDict removeAllObjects];
                [self refreshTableView];
                self.isRefreshing = NO;
            });
        }
    });
}

- (IBAction)warner:(id)sender {
    if (!self.checkTimer) {
        self.checkTimer = [NSTimer timerWithTimeInterval:5400 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.checkTimer forMode:NSDefaultRunLoopMode];
    } else {
        [self.checkTimer invalidate];
        self.checkTimer = nil;
    }
}

- (void)timerAction {
    static BOOL flag = YES;
    if (flag) {
        flag = NO;
        [self saveSyncAction:self.saveSyncBtn];
        return;
    }
    flag = YES;
    [self checkError];
}

- (void)checkError {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.hansModel = [self findStringModelWithIdentifier:@"zh-Hans"];
        NSSet *keys = [NSSet setWithArray:[self.infoDict allKeys]];
        NSMutableSet *set1 = [[NSMutableSet alloc] initWithArray:self.keyArray];
        [set1 unionSet:keys];
        
        NSMutableArray *tmp2 = [NSMutableArray array];
        [tmp2 addObjectsFromArray:[set1 allObjects]];
        NSMutableString *errorStr = [[NSMutableString alloc] init];
        NSMutableString *errorParamsStr = [[NSMutableString alloc] init];
        NSArray *paramArray = @[@"%@",@"%1$@",@"%2$@",@"%3$@",@"%4$@",@"%5$@",
                                @"%d",@"%1$d",@"%2$d",@"%3$d",@"%4$d",@"%5$d",
                                @"%ld",@"%1$ld",@"%2$ld",@"%3$ld",@"%4$ld",@"%5$ld",
                                @"%lld",@"%1$lld",@"%2$lld",@"%3$lld",@"%4$lld",@"%5$lld",
                                @"%zd",@"%1$zd",@"%2$zd",@"%3$zd",@"%4$zd",@"%5$zd",@"%.0f"];
        NSArray *pArr = @[@"%@",@"%d",@"%ld",@"%lld",@"%zd"];
        for (NSString *string in [tmp2 copy]) {
            NSString *hasValue = self.hansModel.stringDictionary[string];
            for (StringModel *model in self.stringArray) {
                NSString *str2 = model.stringDictionary[string];
                if (str2.length == 0) {
                    [errorStr appendFormat:@"行号：%lu     语言：%@  key:%@\n",[self.hansModel.keyArray indexOfObject:string]+2,model.identifier,string];
                } else {
                    BOOL existError = NO;
                    NSString *errorParam = nil;
                    if ([str2 isEqualToString:@"#N/A"]) {
                        existError = YES;
                        errorParam = str2;
                    } else {
                        NSArray *pArray = pArr;
                        for (NSString *p in pArray) {
                            if ([str2 componentsSeparatedByString:p].count > 2) {
                                existError = YES;
                                errorParam = p;
                                break;
                            }
                        }
                        if (!existError) {
                            for (int i=0; i<paramArray.count; ++i) {
                                NSString *p = paramArray[i];
                                //检查参数个数是否一致
                                NSUInteger n1 = [hasValue componentsSeparatedByString:p].count;
                                NSUInteger n2 = [str2 componentsSeparatedByString:p].count;
                                if (n1 != n2) {
                                    existError = YES;
                                    errorParam = p;
                                    break;
                                }
                            }
                        }
                    }
                    if (existError) {
                        [errorParamsStr appendFormat:@"行号：%lu     语言：%@  错误参数:%@        key:%@\n",[self.hansModel.keyArray indexOfObject:string]+2,model.identifier,errorParam,string];
                    }
                }
            }
        }
        if (errorStr.length > 0 || errorParamsStr.length > 0) {
            NSLog(@"报警：%@\n\n%@",errorStr,errorParamsStr);
            if (errorStr.length > 0) {
                //发送飞书消息
                [self _sendFeishumsg:errorStr type:1];
            }
            if (errorParamsStr.length > 0) {
                [self _sendFeishumsg:errorParamsStr type:2];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.warningWindowCtrl) {
                    [self.warningWindowCtrl.window close];
                }
                WarningWindowController *ctrl = [[WarningWindowController alloc] initWithWindowNibName:@"WarningWindowController"];
                [ctrl refreshText:[NSString stringWithFormat:@"未翻译的如下：\n%@\n\n参数出错的如下：\n%@",errorStr,errorParamsStr]];
                ctrl.window.level = kCGAssistiveTechHighWindowLevel;
                [ctrl.window orderFrontRegardless];
                [ctrl showWindow:self];
                [ctrl.window makeKeyWindow];
                self.warningWindowCtrl = ctrl;
            });
        } else {
            //发送飞书消息
            [self _sendFeishumsg:errorStr type:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.warningWindowCtrl) {
                    [self.warningWindowCtrl.window close];
                }
            });
        }
    });
}

- (IBAction)searchAnswer:(id)sender {
    NSString *searchString = _searchField.stringValue;
    NSControlStateValue showOnlyBtnState = self.showOnlyBtn.state;
    NSControlStateValue unusedBtnState = self.unusedBtn.state;
    NSControlStateValue untranslatedBtnState = self.untranslatedBtn.state;
    NSControlStateValue errorBtnState = self.errorBtn.state;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSSet *keys = [NSSet setWithArray:[self.infoDict allKeys]];
        NSMutableSet *set1 = [[NSMutableSet alloc] initWithArray:self.keyArray];
        [set1 unionSet:keys];
        
        NSMutableArray *tmp2 = [NSMutableArray array];
        if(showOnlyBtnState){
            for (ActionModel *model in self.actionArray) {
                if (![tmp2 containsObject:model.key]) {
                    [tmp2 addObject:model.key];
                }
            }
        }else{
            [tmp2 addObjectsFromArray:[set1 allObjects]];
        }
        
        for (NSString *string in [tmp2 copy]) {
            if(unusedBtnState){
                NSArray *arr = self.infoDict[string];
                if (arr.count > 0) {
                    [tmp2 removeObject:string];
                }
            }
            
            BOOL exist = YES;
            BOOL found = searchString.length==0 || [string contain:searchString];
            for (StringModel *model in self.stringArray) {
                NSString *str2 = model.stringDictionary[string];
                ActionModel *action = [self findActionWith:string identify:model.identifier];
                exist = exist && (str2.length || (action && action.value.length));
                found = found || ([str2 contain:searchString] || (action && [action.value contain:searchString]));
            }
            if (!found || (found && untranslatedBtnState && exist)) {
                [tmp2 removeObject:string];
            }
        }
        
        if (errorBtnState) {
            NSArray *paramArray = @[@"%@",@"%1$@",@"%2$@",@"%3$@",@"%4$@",@"%5$@",
                                    @"%d",@"%1$d",@"%2$d",@"%3$d",@"%4$d",@"%5$d",
                                    @"%ld",@"%1$ld",@"%2$ld",@"%3$ld",@"%4$ld",@"%5$ld",
                                    @"%lld",@"%1$lld",@"%2$lld",@"%3$lld",@"%4$lld",@"%5$lld",
                                    @"%zd",@"%1$zd",@"%2$zd",@"%3$zd",@"%4$zd",@"%5$zd",@"%.0f"];
            NSArray *pArr = @[@"%@",@"%d",@"%ld",@"%lld",@"%zd"];
            for (NSString *string in [tmp2 copy]) {
                NSString *hasValue = self.hansModel.stringDictionary[string];
                BOOL keyExistError = NO;
                for (StringModel *model in self.stringArray) {
                    BOOL existError = NO;
                    NSString *str2 = model.stringDictionary[string];
                    if ([str2 isEqualToString:@"#N/A"]) {
                        existError = YES;
                    } else {
                        NSArray *pArray = pArr;
                        for (NSString *p in pArray) {
                            if ([str2 componentsSeparatedByString:p].count > 2) {
                                existError = YES;
                                break;
                            }
                        }
                        if (!existError) {
                            for (int i=0; i<paramArray.count; ++i) {
                                NSString *p = paramArray[i];
                                //检查参数个数是否一致
                                NSUInteger n1 = [hasValue componentsSeparatedByString:p].count;
                                NSUInteger n2 = [str2 componentsSeparatedByString:p].count;
                                if (n1 != n2) {
                                    existError = YES;
                                    break;
                                }
                            }
                        }
                    }
                    if (existError) {
                        [model.errorKeySet addObject:string];
                        keyExistError = YES;
                    }
                }
                if(!keyExistError) {
                    [tmp2 removeObject:string];
                }
            }
        }
        
        
        if ([kStrKey isEqualToString:self.sortingCol] || [kRemove isEqualToString:self.sortingCol]){
            self.showArray = [tmp2 sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSString *key1 = self.ascending?obj1:obj2;
                NSString *key2 = self.ascending?obj2:obj1;
                
                return [key1 compare:key2];
            }];
        } else if ([kRowNo isEqualToString:self.sortingCol] ){
            self.showArray = [tmp2 sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull key1, NSString * _Nonnull key2) {
                NSUInteger index1 = [self.hansModel.keyArray indexOfObject:key1];
                NSUInteger index2 = [self.hansModel.keyArray indexOfObject:key2];
                return  self.ascending?index1>index2:index1<index2;
            }];
        }  else if ([kInfo isEqualToString:self.sortingCol]){
            self.showArray = [tmp2 sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull key1, NSString * _Nonnull key2) {
                NSArray *items1 = self.infoDict[self.ascending?key1:key2];
                NSInteger count1 = items1.count;
                NSArray *items2 = self.infoDict[self.ascending?key2:key1];
                NSInteger count2 = items2.count;
                if (count1 > count2) {
                    return NSOrderedDescending;
                } else if (count2 > count1) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedSame;
                }
            }];
        } else {
            self.showArray = [tmp2 sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull key1, NSString * _Nonnull key2) {
                NSString *rawValue1 = [self valueInRaw:self.ascending?key1:key2 identifier:self.sortingCol];
                NSString *rawValue2 = [self valueInRaw:self.ascending?key2:key1 identifier:self.sortingCol];
                return [rawValue1 compare:rawValue2];
            }];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.recordLabel.stringValue = [NSString stringWithFormat:LocalizedString(@"RecordNumMsg"),self.showArray.count];
            [self.saveBtn setEnabled:(self.actionArray.count>0 && !self.isChecking)];
            [self.tableview reloadData];
        });
        
    });
}

- (IBAction)checkAction:(id)sender {
    if(self.showArray.count==0)
        return;
    
    self.isChecking = YES;
    [self.infoDict removeAllObjects];
    [self searchAnswer:nil];
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        StringSetting *settings = [StringModel projectSettingByProjectPath:weakSelf.projectPath projectName:weakSelf.projectName];
        NSDictionary *dict = [StringModel findItemsWithProjectSetting:settings
                                                          projectPath:weakSelf.projectPath
                                                          findStrings:weakSelf.showArray
                                                                block:^(float progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.checkIndicator.doubleValue = progress;
            });
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.isChecking=NO;
            [weakSelf.infoDict addEntriesFromDictionary:dict];
            [weakSelf searchAnswer:nil];
        });
    });
}

- (IBAction)addAction:(id)sender {
    NSAlert *alert = [[NSAlert alloc]init];
    [alert setMessageText: LocalizedString(@"InputKeyMsg")];
    [alert addButtonWithTitle: LocalizedString(@"OK")];
    [alert addButtonWithTitle:LocalizedString(@"Cancel")];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [alert setAccessoryView:input];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSAlertFirstButtonReturn) {
            NSString *text = [input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if(![self validateKey:text])
                return;
            [self.keyArray addObject:text];
            [self.keyDict setObject:@(KeyTypeAdd) forKey:text];
            
            for (StringModel *model in self.stringArray) {
                ActionModel *action = [[ActionModel alloc]init];
                action.actionType = ActionTypeAdd;
                action.identifier = model.identifier;
                action.key = text;
                action.value = @"";
                [self.actionArray addObject:action];
            }
            
            [self.searchField setStringValue:@""];
            [self searchAnswer:nil];
            
            [self.tableview scrollRowToVisible:[self.showArray indexOfObject:text]];
        }
    }];
}

- (IBAction)saveAction:(id)sender {
    if(_actionArray.count==0)
        return;
    StringSetting *setting = [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
    for (StringModel *model in _stringArray) {
        NSPredicate *predicte = [NSPredicate predicateWithFormat:@"identifier == %@",model.identifier];
        NSArray *arr = [self.actionArray filteredArrayUsingPredicate:predicte];
        [model doAction:arr projectSetting:setting];
    }
    [_actionArray removeAllObjects];
    
    [self refresh:nil];
}

- (IBAction)saveSyncAction:(id)sender {
    StringSetting *setting = [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:setting.shellPath]) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText:setting.shellPath.length>0 ? [NSString stringWithFormat:@"脚本文件\"%@\"不存在",setting.shellPath] : @"请配置shell脚本文件路径"];
        [alert addButtonWithTitle: LocalizedString(@"OK")];
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert runModal];
        return;
    }
    NSString* shellPath = setting.shellPath;
    //跑脚本
    if(shellPath.length==0){
        return;
    }
    
    self.hud.hidden = NO;
    self.syncIndicator.hidden = NO;
    [self.syncIndicator startAnimation:nil];
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[shellPath,@"macapp"]];
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [task launchAndReturnError:NULL];
        task.terminationHandler = ^(NSTask *t){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.hud.hidden = YES;
                [self.syncIndicator stopAnimation:nil];
                self.syncIndicator.hidden = YES;
                [self refresh:nil];
            });
        };
        // 获取运行结果
        NSData *data = [file readDataToEndOfFile];
        NSString *string = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
        NSLog(@"结果： %@",string);
    });
}

-(void)cellClicked:(id)sender {
    if (self.isChecking)
        return;
    
    NSInteger column = _tableview.clickedColumn;
    NSInteger row = _tableview.clickedRow;
    if (_selectedRow != row) {
        self.selectedRow = row;
    } else {
        if(column<=0 || column >= self.tableview.numberOfColumns-2)
            return;
        if(row < 0 || row >= self.tableview.numberOfRows)
            return;
        NSString *key = _showArray[row];
        NSInteger status = [_keyDict[key] integerValue];
        if(status != KeyTypeRemove) {
            StringModel *model = _stringArray[column-1];
            if(model){
                NSString *identifier = model.identifier;
                if (self.infoPopOver && self.infoPopOver.isShown) {
                    [self.infoPopOver close];
                    self.infoPopOver = nil;
                }
                if (self.editPopOver && self.editPopOver.isShown) {
                    StringEditViewController *editVC = (StringEditViewController*)[self.editPopOver contentViewController];
                    [self.editPopOver close];
                    self.editPopOver = nil;
                    if ([key isEqualToString:editVC.key] && [identifier isEqualToString:editVC.identifier]) {
                        return;
                    }
                }
                NSDictionary *dict = @{@"Key":key, @"Identifier":identifier};
                [self performSelector:@selector(startEditWithDict:) withObject:dict afterDelay:0.3];
            }
        }
    }
}

-(void)startEditWithDict:(NSDictionary*)dict{
    NSString *key = dict[@"Key"];
    NSString *identifier = dict[@"Identifier"];
    NSInteger column = [_tableview columnWithIdentifier:identifier];
    NSInteger row = [_showArray indexOfObject:key];
    if (_selectedRow != row) {
        self.selectedRow = row;
    } else {
        NSString *title = nil;
        ActionModel *action = [self findActionWith:key identify:identifier];
        if(action){
            title = action.actionType==ActionTypeRemove ? @"" : action.value;
        }
        if(title==nil){
            title = [self valueInRaw:key identifier:identifier];
        }
        CGRect rect = [_tableview frameOfCellAtColumn:column row:row];
        StringEditViewController* viewController = [[StringEditViewController alloc] initWithKey:key identifier:identifier value:title];
        [viewController setFinishBlock:^{
            if (self.editPopOver && self.editPopOver.isShown) {
                [self.editPopOver close],self.editPopOver = nil;
            }
        }];
        self.editPopOver = [[NSPopover alloc] init];
        self.editPopOver.delegate = self;
        self.editPopOver.behavior = NSPopoverBehaviorSemitransient;
        [self.editPopOver setContentViewController:viewController];
        [self.editPopOver showRelativeToRect:rect ofView:_tableview preferredEdge:NSRectEdgeMinY];
    }
}

-(void)doubleAction:(id)sender {
    if (self.isChecking)
        return;
    
    NSInteger column = _tableview.clickedColumn;
    NSInteger row = _tableview.clickedRow;
    if(column<0 || column >= self.tableview.numberOfColumns-2)
        return;
    if(row < 0 || row >= self.tableview.numberOfRows)
        return;
    [[NSObject class] cancelPreviousPerformRequestsWithTarget:self];
    NSString *key = _showArray[row];
    NSString *identifier = nil;
    if(column==0){
        identifier=@"key";
    }else{
        StringModel *model = _stringArray[column-1];
        identifier = model.identifier;
    }
    NSInteger status = [_keyDict[key] integerValue];
    if(status != KeyTypeRemove) {
        ActionModel *action = [self findActionWith:key identify:identifier];
        if(action){
            [_actionArray removeObject:action];
            [self searchAnswer:nil];
        }
        
        NSString *value = [self valueInRaw:key identifier:identifier];
        
        if (column == 0) {
            StringSetting *setting = [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
            if (setting.language == StringLanguageSwift)
                value = [NSString stringWithFormat:@"\"%@\"",value];
            else
                value = [NSString stringWithFormat:@"@\"%@\"",value];
            
            NSString *wrapper = [NSString stringWithString:setting.doubleClickWrapper];
            NSRange start = [wrapper rangeOfString:@"("];
            NSRange end = [wrapper rangeOfString:@")"];
            if (start.location != NSNotFound && end.location != NSNotFound && end.location > start.location) {
                NSRange range = NSMakeRange(start.location, end.location-start.location);
                NSRange keyRange = [wrapper rangeOfString:@"KEY" options:NSCaseInsensitiveSearch range:range];
                if (keyRange.location != NSNotFound)
                    value = [wrapper stringByReplacingCharactersInRange:keyRange withString:value];
            }
        }
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
        [pasteboard setString:value forType:NSStringPboardType];
        
        [self makeToast:value];
    }
}

-(void)makeToast:(NSString *)string{
    [[NSObject class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToast) object:nil];
    
    NSString *tmp = [NSString stringWithFormat:LocalizedString(@"CopyToPasteboard"),string];
    CGFloat width = self.window.contentView.frame.size.width-100;
    NSFont *font =[NSFont systemFontOfSize:24.0];
    CGRect rect = [tmp sizeWithWidth:width font:font];
    rect.size.width += 15.0f;
    rect.size.height += 5.0f;
    rect.origin = CGPointMake(CGRectGetMidX(self.window.contentView.bounds) - CGRectGetMidX(rect), 70.0f);
    self.toastLabel.frame = rect;
    self.toastLabel.stringValue = tmp;
    self.toastLabel.hidden = NO;
    [self performSelector:@selector(hideToast) withObject:nil afterDelay:2];
}

-(void)hideToast{
    self.toastLabel.hidden = YES;
}

-(void)removeAction:(id)sender {
    if (self.isChecking)
        return;
    
    NSButton *button = (NSButton*)sender;
    NSString *key=button.identifier;
    NSInteger status = [_keyDict[key] integerValue];
    for (ActionModel *action in [_actionArray copy]) {
        if ([action.key isEqualToString:key]) {
            [_actionArray removeObject:action];
        }
    }
    if(status == KeyTypeRemove || status == KeyTypeAdd) {
        [_keyDict removeObjectForKey:key];
        if(status == KeyTypeAdd){
            [_keyArray removeObject:key];
        }
    } else {
        for (StringModel *model in _stringArray) {
            ActionModel *action = [[ActionModel alloc]init];
            action.actionType = ActionTypeRemove;
            action.identifier = model.identifier;
            action.key = key;
            action.value = [self valueInRaw:key identifier:model.identifier];
            [_actionArray addObject:action];
        }
        [_keyDict setObject:@(KeyTypeRemove) forKey:key];
    }
    [self searchAnswer:nil];
}

-(void)infoAction:(id)sender {
    if (self.isChecking)
        return;
    
    NSButton *button = (NSButton*)sender;
    NSString *key=button.identifier;
    if(self.infoDict && key.length>0){
        if (self.editPopOver && self.editPopOver.isShown) {
            [self.editPopOver close];
            self.editPopOver = nil;
        }
        if (self.infoPopOver && self.infoPopOver.isShown) {
            StringInfoViewController *infoVC = (StringInfoViewController*)[self.infoPopOver contentViewController];
            [self.infoPopOver close];
            self.infoPopOver = nil;
            if ([key isEqualToString:infoVC.key]) {
                return;
            }
        }
        NSArray *infos = self.infoDict[key];
        if(infos.count==0)
            return;
        StringInfoViewController* viewController = [[StringInfoViewController alloc] initWithArray:infos];
        viewController.key = key;
        self.infoPopOver = [[NSPopover alloc] init];
        self.infoPopOver.behavior = NSPopoverBehaviorSemitransient;
        [self.infoPopOver setContentViewController:viewController];
        [self.infoPopOver showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
    }
}

- (IBAction)tableAction:(id)sender {
    StringSetting* projectSetting = [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
    NSPopUpButton *popUp = (NSPopUpButton *)sender;
    projectSetting.searchTableName = [popUp.selectedItem.title stringByAppendingString:@".strings"];
    [StringModel saveProjectSetting:projectSetting ByProjectName:self.projectName];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyProjectSettingChanged object:nil];
}

#pragma mark - Notification
- (void)projectSettingChanged:(NSNotification*)notification {
    if ([notification object]) {
        NSString *projectname = (NSString *)[notification object];
        self.projectName = projectname;
    }
    [self.infoDict removeAllObjects];
    [self refresh:nil];
}

- (void)windowDidResize:(NSNotification *)notification {
    [_tableview reloadData];
}

#pragma mark - NSPopoverDelegate
- (void)popoverDidClose:(NSNotification*)notification {
    NSPopover* popOver = [notification object];
    if ([popOver isKindOfClass:[NSPopover class]] == NO) {
        return;
    }
    id controller = [popOver contentViewController];
    if ([controller isKindOfClass:[StringEditViewController class]] == NO) {
        return;
    }
    StringEditViewController* editViewController = (StringEditViewController*)controller;
    NSString *string1 = editViewController.textView.string;
    NSString *string2 = [string1 stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    [self changeWithKey:editViewController.key identifier:editViewController.identifier newValue:string2];
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.showArray.count;
}

- (void)tableViewColumnDidResize:(NSNotification *)notification{
    [_tableview reloadData];
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    float height = 0;
    NSString *key = _showArray[row];
    for (ActionModel *model in _actionArray) {
        if ([model.key isEqualToString:key]) {
            NSTableColumn *column = [_tableview tableColumnWithIdentifier:model.identifier];
            float tmpHeight = ceilf([model.value sizeWithWidth:column.width font:kFont].size.height);
            height = MAX(height, tmpHeight);
        }
    }
    StringModel *maxHeightModel = nil;
    for (StringModel *model in _stringArray) {
        float tmpHeight = [model.heightDictionary[key] floatValue];
        if (tmpHeight > height) {
            maxHeightModel = model;
            height = tmpHeight;
        }
    }
    NSString *tmp = maxHeightModel.stringDictionary[key];
    NSTableColumn *column = [_tableview tableColumnWithIdentifier:maxHeightModel.identifier];
    float tmpHeight = ceilf([tmp sizeWithWidth:column.width font:kFont].size.height);
    height = MAX(17, tmpHeight);
    return height;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if(row>=self.showArray.count)
        return nil;
    NSString *identifier=[tableColumn identifier];
    NSString *key = self.showArray[row];
    if([identifier isEqualToString:kRowNo]){
        NSTextField *aView = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!aView) {
            aView = [[NSTextField alloc]initWithFrame:NSZeroRect];
            [aView setTextColor:[NSColor blackColor]];
            [aView setBordered:NO];
            [aView setFont:kFont];
            [aView setEditable:NO];
            [aView setLineBreakMode:NSLineBreakByWordWrapping];
            [aView setAlignment:NSTextAlignmentNatural];
        }
        [aView setTag:row];
        [aView setIdentifier:identifier];
        if(self.hansModel){
            [aView setStringValue:[NSString stringWithFormat:@"%zd",[self.hansModel.keyArray indexOfObject:key]+2]];
        } else {
            [aView setStringValue:@""];
        }
        return aView;
    } else if([identifier isEqualToString:kRemove]){
        NSButton *aView = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!aView) {
            aView = [[NSButton alloc]initWithFrame:NSZeroRect];
            [aView setButtonType:NSToggleButton];
            [aView setTitle:LocalizedString(@"Remove") textColor:[NSColor blackColor]];
            [aView setAlternateTitle:LocalizedString(@"Revoke") textColor:[NSColor redColor]];
            [aView setAction:@selector(removeAction:)];
            [aView setTarget:self];
        }
        NSInteger status = [_keyDict[key] integerValue];
        [aView setHighlighted:status];
        [aView setTag:row];
        [aView setIdentifier:key];
        return aView;
    }else if([identifier isEqualToString:kInfo]){
        NSArray *items = self.infoDict[key];
        NSButton *aView = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!aView) {
            aView = [[NSButton alloc]initWithFrame:NSZeroRect];
            [aView setAction:@selector(infoAction:)];
            [aView setTarget:self];
            [aView setState:1];
        }
        [aView setTag:row];
        [aView setIdentifier:key];
        [aView setTitle:[@(items.count) stringValue]];
        return aView;
    }else {
        NSTextField *aView = [tableView makeViewWithIdentifier:@"MYCell" owner:self];
        if(!aView) {
            aView = [[NSTextField alloc]initWithFrame:NSZeroRect];
            [aView setTextColor:[NSColor blackColor]];
            [aView setBordered:NO];
            [aView setFont:kFont];
            [aView setEditable:NO];
            [aView setLineBreakMode:NSLineBreakByWordWrapping];
        }
        if([identifier isEqualToString:kStrKey]){
            NSInteger status = [_keyDict[key] integerValue];
            if(status == KeyTypeRemove){
                [aView setBackgroundColor:[NSColor redColor]];
            }else if (status == KeyTypeAdd) {
                [aView setBackgroundColor: [NSColor colorWithRed:0 green:0.8 blue:0 alpha:1.0]];
            }else{
                StringModel *model = [self findStringModelWithIdentifier:identifier];
                if ([model.errorKeySet containsObject:key]) {
                    [aView setBackgroundColor: [NSColor yellowColor]];
                } else {
                    [aView setBackgroundColor: [NSColor clearColor]];
                }
            }
            [aView setStringValue:_showArray[row]];
        }else{
            ActionModel *action = [self findActionWith:key identify:identifier];
            NSString *rawValue = @"";
            if([identifier isEqualToString:kStrKey]) {
                rawValue =  key;
            }
            StringModel *model = [self findStringModelWithIdentifier:identifier];
            if(model){
                NSString *value = model.stringDictionary[key];
                if(value.length>0) rawValue = value;
            }
            if (action) {
                if(action.actionType == ActionTypeRemove){
                    [aView setBackgroundColor:[NSColor redColor]];
                }else{
                    if (rawValue.length==0) {
                        [aView setBackgroundColor: [NSColor colorWithRed:0 green:0.8 blue:0 alpha:1.0]];
                    }else{
                        [aView setBackgroundColor: [NSColor blueColor]];
                    }
                }
                [aView setStringValue:action.value];
            }else{
                if ([model.errorKeySet containsObject:key]) {
                    [aView setBackgroundColor: [NSColor yellowColor]];
                } else {
                    [aView setBackgroundColor: [NSColor clearColor]];
                }
                //                [aView setStringValue:rawValue];
                NSMutableAttributedString *attriStr =  [[NSMutableAttributedString alloc] initWithString:rawValue attributes:@{NSForegroundColorAttributeName:[NSColor blackColor]}];
                NSRange range = [rawValue rangeOfString:_searchField.stringValue options:NSCaseInsensitiveSearch];
                [attriStr setAttributes:@{NSForegroundColorAttributeName:[NSColor redColor]} range:range];
                [aView setAttributedStringValue:attriStr];
            }
        }
        [aView setTag:row];
        [aView setIdentifier:identifier];
        return aView;
    }
}

-(void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
    NSString *identifier=[tableColumn identifier];
    if ([identifier isEqualToString:kRemove]) {
        return;
    }
    if ([identifier isEqualToString:_sortingCol]) {
        self.ascending = !self.ascending;
    } else {
        self.ascending = YES;
    }
    self.sortingCol = identifier;
    
    [self refreshTableColumn];
    
    [self searchAnswer:nil];
}
@end
