//
//  TestCoding.m
//  StringManage
//
//  Created by kiwik on 1/17/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringSetting.h"
#import "StringModel.h"
#import "NSString+Extension.h"

@implementation StringSetting

+ (StringSetting*)defaultSettingWithProjectPath:(NSString *)projectPath projectName:(NSString*)projectName {
    NSString *name = [projectName stringByDeletingPathExtension];
    StringSetting* projectSetting = [[StringSetting alloc] init];
    projectSetting.searchDirectory = [@"xcodeproj" isEqualToString:[projectName pathExtension]] ?  [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:name]] : [StringModel addPathSlash:[StringModel rootPathMacro]];
    projectSetting.searchTableName = @"Localizable.strings";
    projectSetting.searchProjectName = @"";
    projectSetting.shellPath = @"~";
    projectSetting.searchTypes = @[@"h", @"m",@"swift",@"mm",@"pch"];
    projectSetting.includeDirs = @[ [StringModel rootPathMacro] ];
    projectSetting.excludeDirs = @[
                                   [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:@"Pods"]],
                                   [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:@"Carthage"]],
                                   [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:@"DerivedData"]]
                                   ];
    NSInteger language = [StringModel devLanguageWithProjectPath:projectPath];
    projectSetting.language = language;
    if (language == StringLanguageSwift) {
        //key will be replace with "value"
        projectSetting.doubleClickWrapper = @"NSLocalizedString(key, comment: \"\")";
    }else{
        //key will be replace with @"value"
        projectSetting.doubleClickWrapper = @"NSLocalizedString(key, nil)";
    }
    projectSetting.maxOperationCount = 5;
    projectSetting.feishu_appid = @"";
    projectSetting.feishu_appsecret = @"";
    projectSetting.feishu_chatid = @"";
    projectSetting.feishu_atuserid = @"";
    return projectSetting;
}

#pragma mark - Archiving

static NSString *searchDirectory = @"searchDirectory";
static NSString *searchTableName = @"searchTableName";
static NSString *searchTypes = @"searchTypes";
static NSString *includeDirs = @"includeDirs";
static NSString *excludeDirs = @"excludeDirs";
static NSString *language = @"language";
static NSString *doubleClickWrapper = @"doubleClickWrapper";
static NSString *maxOperationCount = @"maxOperationCount";
static NSString *shellPath = @"shellPath";
static NSString *searchProjectName = @"searchProjectName";
static NSString *feishu_appid = @"feishu_appid";
static NSString *feishu_appsecret = @"feishu_appsecret";
static NSString *feishu_chatid = @"feishu_chatid";
static NSString *feishu_atuserid = @"feishu_atuserid";

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _searchDirectory = [aDecoder decodeObjectForKey:searchDirectory];
        _searchTableName = [aDecoder decodeObjectForKey:searchTableName];
        _searchTypes = [aDecoder decodeObjectForKey:searchTypes];
        _includeDirs = [aDecoder decodeObjectForKey:includeDirs];
        _excludeDirs = [aDecoder decodeObjectForKey:excludeDirs];
        _language = [aDecoder decodeIntegerForKey:language];
        _doubleClickWrapper = [aDecoder decodeObjectForKey:doubleClickWrapper];
        _maxOperationCount = [aDecoder decodeIntegerForKey:maxOperationCount];
        _shellPath = [aDecoder decodeObjectForKey:shellPath];
        _searchProjectName = [aDecoder decodeObjectForKey:searchProjectName];
        _feishu_appid = [aDecoder decodeObjectForKey:feishu_appid];
        _feishu_appsecret = [aDecoder decodeObjectForKey:feishu_appsecret];
        _feishu_chatid = [aDecoder decodeObjectForKey:feishu_chatid];
        _feishu_atuserid = [aDecoder decodeObjectForKey:feishu_atuserid];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
    [aCoder encodeObject:self.searchDirectory ? self.searchDirectory : @"" forKey:searchDirectory];
    [aCoder encodeObject:self.searchTableName ? self.searchTableName : @"" forKey:searchTableName];
    [aCoder encodeObject:self.searchTypes ? self.searchTypes : @[] forKey:searchTypes];
    [aCoder encodeObject:self.includeDirs ? self.includeDirs : @[] forKey:includeDirs];
    [aCoder encodeObject:self.excludeDirs ? self.excludeDirs : @[] forKey:excludeDirs];
    [aCoder encodeInteger:self.language forKey:language];
    [aCoder encodeObject:self.doubleClickWrapper ? self.doubleClickWrapper : @"" forKey:doubleClickWrapper];
    [aCoder encodeInteger:self.maxOperationCount forKey:maxOperationCount];
    [aCoder encodeObject:self.shellPath ? self.shellPath : @"" forKey:shellPath];
    [aCoder encodeObject:self.searchProjectName ? self.searchProjectName : @"" forKey:searchProjectName];
    [aCoder encodeObject:self.feishu_appid ?: @"" forKey:feishu_appid];
    [aCoder encodeObject:self.feishu_appsecret ?: @"" forKey:feishu_appsecret];
    [aCoder encodeObject:self.feishu_chatid ?: @"" forKey:feishu_chatid];
    [aCoder encodeObject:self.feishu_atuserid ?: @"" forKey:feishu_atuserid];
}

-(NSInteger)language{
    if (_language < 0 || _language > 1) {
        _language = 0;
    }
    return _language;
}

-(NSString*)doubleClickWrapper{
//    if (!_doubleClickWrapper) {
//        if (_language == StringLanguageSwift) {
//            //key will be replace with "value"
//            _doubleClickWrapper = @"NSLocalizedString(key, comment: "")";
//        }else{
//            //key will be replace with @"value"
//            _doubleClickWrapper = @"NSLocalizedString(key, nil)";
//        }
//    }
    if (_language == StringLanguageSwift) {
        //key will be replace with "value"
        if ([self.searchTableName isEqualToString:@"Localizable.strings"]) {
            _doubleClickWrapper = @"NSLocalizedString(key, comment: \"\")";
        } else {
            _doubleClickWrapper = [NSString stringWithFormat:@"NSLocalizedStringFromTable(key, \"%@\", comment: \"\")",[self.searchTableName stringByDeletingPathExtension]];
        }
    }else{
        //key will be replace with @"value"
        if ([self.searchTableName isEqualToString:@"Localizable.strings"]) {
            _doubleClickWrapper = @"NSLocalizedString(key, nil)";
        } else {
            _doubleClickWrapper = [NSString stringWithFormat:@"NSLocalizedStringFromTable(key, @\"%@\", nil)",[self.searchTableName stringByDeletingPathExtension]];
        }
    }
    return _doubleClickWrapper;
}

-(NSInteger)maxOperationCount{
    if (_maxOperationCount<=0 || _maxOperationCount>10) {
        _maxOperationCount = 5;
    }
    return _maxOperationCount;
}


@end
