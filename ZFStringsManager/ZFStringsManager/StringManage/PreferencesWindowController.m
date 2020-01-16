//
//  XToDoPreferencesWindowController.m
//  XToDo
//
//  Created by kiwik on 1/16/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "StringManage.h"
#import "StringSetting.h"
#import "StringPathEditViewController.h"
#import "StringModel.h"

NSString* const kNotifyProjectSettingChanged = @"StringManage_NotifyProjectSettingChanged";

@interface PreferencesWindowController ()
@property (weak) IBOutlet NSTextField *dirTitleTextField;
@property (weak) IBOutlet NSTextField *tableTitleTextField;
@property (weak) IBOutlet NSTextField* directoryTextField;
@property (weak) IBOutlet NSTextField* tableNameTextField;
@property (weak) IBOutlet NSTextField *searchFilesTextField;
@property (weak) IBOutlet NSTextField *includeTextField;
@property (weak) IBOutlet NSTextField *excludeTextField;
@property (weak) IBOutlet NSPopUpButton *languagePopUpBtn;
@property (weak) IBOutlet NSTextField *languageLabel;
@property (weak) IBOutlet NSTextField *languageTipsLabel;
@property (weak) IBOutlet NSTextField *wrapperTextField;
@property (weak) IBOutlet NSTextField *wrapperTitleField;
@property (weak) IBOutlet NSTextField *wrapperTipsField;
@property (weak) IBOutlet NSTextField *searchNumberLabel;
@property (weak) IBOutlet NSPopUpButton *searchNumberPopUpBtn;
@property (weak) IBOutlet NSTextField *projectNameTextField;
@property (weak) IBOutlet NSTextField *shellPathTextField;
@property (weak) IBOutlet NSTextField *feishu_appidTextField;
@property (weak) IBOutlet NSTextField *feishu_appsecretTextField;
@property (weak) IBOutlet NSTextField *feishu_chatidTextField;
@property (weak) IBOutlet NSTextField *feishu_atuseridTextField;

- (IBAction)onTouchUpInsideLocalizable:(id)sender;
- (IBAction)onTouchUpInsideExtension:(id)sender;
- (IBAction)onTouchUpInsideEditInclude:(id)sender;
- (IBAction)onTouchUpInsideEditExclude:(id)sender;
- (IBAction)searchNumberClicked:(id)sender;

@end

@implementation PreferencesWindowController

#pragma mark - override
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditingAction:) name:NSControlTextDidEndEditingNotification object:nil];
    
    return [self initWithWindowNibName:@"PreferencesWindowController"];
}

- (void)loadWindow {
    [super loadWindow];
    
    [self.window setTitle:LocalizedString(@"Preferences")];
    [self.dirTitleTextField setStringValue:LocalizedString(@"SearchDirectory")];
    [self.tableTitleTextField setStringValue:LocalizedString(@"SearchTableName")];
    [self.languageLabel setStringValue:LocalizedString(@"DevLanguage")];
    [self.languageTipsLabel setStringValue:LocalizedString(@"DevLanguageTips")];
    [self.wrapperTitleField setStringValue:LocalizedString(@"Wrapper")];
    [self.wrapperTipsField setStringValue:LocalizedString(@"WrapperTips")];
    [self.searchNumberLabel setStringValue:LocalizedString(@"SearchNumber")];
    
    [self _updateDirsUI];
    
    [self.window makeFirstResponder:nil];
}

-(StringSetting*)getSetting {
    return [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
}

-(void)_updateDirsUI {
    StringSetting* projectSetting = [self getSetting];
    
    NSString *path1 = [StringModel explandRootPathMacro:[projectSetting searchDirectory] projectPath:self.projectPath];
    self.directoryTextField.stringValue = path1;
    [self.directoryTextField setSelectable:YES];
    [self.directoryTextField setEditable:NO];
    [self.directoryTextField resignFirstResponder];
    
    self.projectNameTextField.stringValue = self.projectName;
    self.shellPathTextField.stringValue = projectSetting.shellPath;
    
    self.tableNameTextField.stringValue = [projectSetting searchTableName];
    
    [self.languagePopUpBtn selectItemAtIndex:projectSetting.language];
    
    [self.searchNumberPopUpBtn selectItemAtIndex:projectSetting.maxOperationCount-1];
    
    self.wrapperTextField.stringValue = projectSetting.doubleClickWrapper;
    
    self.searchFilesTextField.stringValue = [[projectSetting searchTypes] componentsJoinedByString:@","];
    [self.searchFilesTextField setSelectable:YES];
    [self.searchFilesTextField setEditable:NO];
    [self.searchFilesTextField resignFirstResponder];
    
    NSArray* includeDirs = [StringModel explandRootPathMacros:[projectSetting includeDirs]
                                                          projectPath:self.projectPath];
    self.includeTextField.stringValue = [includeDirs componentsJoinedByString:@"    "];
    [self.includeTextField setSelectable:YES];
    [self.includeTextField setEditable:NO];
    [self.includeTextField resignFirstResponder];
    
    NSArray* excludeDirs = [StringModel explandRootPathMacros:[projectSetting excludeDirs]
                                                          projectPath:self.projectPath];
    self.excludeTextField.stringValue = [excludeDirs componentsJoinedByString:@"    "];
    [self.excludeTextField setSelectable:YES];
    [self.excludeTextField setEditable:NO];
    [self.excludeTextField resignFirstResponder];
    
    self.feishu_appidTextField.stringValue = projectSetting.feishu_appid;
    self.feishu_appsecretTextField.stringValue = projectSetting.feishu_appsecret;
    self.feishu_chatidTextField.stringValue = projectSetting.feishu_chatid;
    self.feishu_atuseridTextField.stringValue = projectSetting.feishu_atuserid;

}

#pragma mark - NSNotification
-(void)endEditingAction:(NSNotification*)notification {
    if([notification object] == self.tableNameTextField){
        NSString *extension = [self.tableNameTextField.stringValue pathExtension];
        if(![extension isEqualToString:@"strings"]) {
            NSAlert *alert = [[NSAlert alloc]init];
            [alert setMessageText: LocalizedString(@"FileExtensionInvalid")];
            [alert addButtonWithTitle: LocalizedString(@"OK")];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModal];
        }else{
            StringSetting* projectSetting = [self getSetting];
            projectSetting.searchTableName=self.tableNameTextField.stringValue;
        }
    }
    else if([notification object] == self.wrapperTextField){
        StringSetting* projectSetting = [self getSetting];
        projectSetting.doubleClickWrapper=self.wrapperTextField.stringValue;
    }
    else if([notification object] == self.shellPathTextField){
        StringSetting* projectSetting = [self getSetting];
        projectSetting.shellPath=self.shellPathTextField.stringValue;
    }
    else if([notification object] == self.projectNameTextField){
        StringSetting* projectSetting = [self getSetting];
        projectSetting.searchProjectName=self.projectNameTextField.stringValue;
        self.projectName = self.projectNameTextField.stringValue;
    }
    else if([notification object] == self.feishu_appidTextField){
        StringSetting* projectSetting = [self getSetting];
        projectSetting.feishu_appid=self.feishu_appidTextField.stringValue;
    }
    else if([notification object] == self.feishu_appsecretTextField){
        StringSetting* projectSetting = [self getSetting];
        projectSetting.feishu_appsecret=self.feishu_appsecretTextField.stringValue;
    }
    else if([notification object] == self.feishu_chatidTextField){
        StringSetting* projectSetting = [self getSetting];
        projectSetting.feishu_chatid=self.feishu_chatidTextField.stringValue;
    }
    else if([notification object] == self.feishu_atuseridTextField){
        StringSetting* projectSetting = [self getSetting];
        projectSetting.feishu_atuserid=self.feishu_atuseridTextField.stringValue;
    }
}

- (void)windowWillClose:(NSNotification*)notification {
    [self.window makeFirstResponder:nil];
    
    StringSetting* projectSetting = [self getSetting];
    [StringModel saveProjectSetting:projectSetting ByProjectName:self.projectName];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyProjectSettingChanged object:self.projectName];
}

#pragma mark - private
- (IBAction)onTouchUpInsideLocalizable:(id)sender {
    StringSetting* projectSetting = [self getSetting];
    NSPopover* popover = [[NSPopover alloc] init];
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    StringPathEditViewController* viewController = [[StringPathEditViewController alloc] initWithArray:@[projectSetting.searchDirectory]];
    [popover setContentViewController:viewController];
    viewController.pathEditType = PathEditTypeLocalizable;
    [popover showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
}

- (IBAction)onTouchUpInsideExtension:(id)sender {
    StringSetting* projectSetting = [self getSetting];
    NSPopover* popover = [[NSPopover alloc] init];
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    StringPathEditViewController* viewController = [[StringPathEditViewController alloc] initWithArray:projectSetting.searchTypes];
    [popover setContentViewController:viewController];
    viewController.pathEditType = PathEditTypeExtension;
    [popover showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
}

- (IBAction)langaugeAction:(id)sender {
    StringSetting* projectSetting = [self getSetting];
    NSPopUpButton *popUp = (NSPopUpButton *)sender;
    projectSetting.language = popUp.indexOfSelectedItem;
}

- (IBAction)searchNumberClicked:(id)sender {
    StringSetting* projectSetting = [self getSetting];
    NSPopUpButton *popUp = (NSPopUpButton *)sender;
    projectSetting.maxOperationCount = popUp.indexOfSelectedItem+1;
}

- (IBAction)onTouchUpInsideEditInclude:(id)sender {
    StringSetting* projectSetting = [self getSetting];
    NSPopover* popover = [[NSPopover alloc] init];
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    StringPathEditViewController* viewController = [[StringPathEditViewController alloc] initWithArray:projectSetting.includeDirs];
    [popover setContentViewController:viewController];
    viewController.pathEditType = PathEditTypeInclude;
    [popover showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
}

- (IBAction)onTouchUpInsideEditExclude:(id)sender {
    StringSetting* projectSetting = [self getSetting];
    NSPopover* popover = [[NSPopover alloc] init];
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    StringPathEditViewController* viewController = [[StringPathEditViewController alloc] initWithArray:projectSetting.excludeDirs];
    [popover setContentViewController:viewController];
    viewController.pathEditType = PathEditTypeExclude;
    [popover showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
}

#pragma mark - NSPopoverDelegate
- (void)popoverDidClose:(NSNotification*)notification {
    NSPopover* popOver = [notification object];
    if ([popOver isKindOfClass:[NSPopover class]] == NO) {
        return;
    }
    
    StringPathEditViewController* pathEditViewController = (StringPathEditViewController*)[popOver contentViewController];
    if ([pathEditViewController isKindOfClass:[StringPathEditViewController class]] == NO) {
        return;
    }
    StringSetting* projectSetting = [self getSetting];
    if (pathEditViewController.pathEditType == PathEditTypeInclude) {
        projectSetting.includeDirs = [pathEditViewController array];
    } else if (pathEditViewController.pathEditType == PathEditTypeExclude) {
        projectSetting.excludeDirs = [pathEditViewController array];
    }else if (pathEditViewController.pathEditType == PathEditTypeLocalizable) {
        projectSetting.searchDirectory = [[pathEditViewController array] objectAtIndex:0];
    }else if (pathEditViewController.pathEditType == PathEditTypeExtension) {
        projectSetting.searchTypes = [pathEditViewController array];
    } else if (pathEditViewController.pathEditType == PathEditTypeShellPath) {
        projectSetting.shellPath = [[pathEditViewController array] objectAtIndex:0];
    }
    [self _updateDirsUI];
}
@end
