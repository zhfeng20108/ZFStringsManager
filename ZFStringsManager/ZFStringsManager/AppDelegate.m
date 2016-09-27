//
//  AppDelegate.m
//  ZFStringsManager
//
//  Created by zhangfeng on 16/9/20.
//  Copyright © 2016年 zhangfeng. All rights reserved.
//

#import "AppDelegate.h"
#import "StringWindowController.h"
#import "StringModel.h"
#import "StringManage.h"
#include <mach-o/dyld.h>
@interface AppDelegate ()

//@property (weak) IBOutlet NSWindow *window;
@property (strong) NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//
   self.ctrl = [[StringWindowController alloc] init];
    self.window = self.ctrl.window;
    [self.window makeKeyWindow];

    char g_path[MAXPATHLEN+1];
    uint32_t size = sizeof(g_path);
    if (_NSGetExecutablePath(g_path, &size) == 0)
    printf("executable path is %s\n", g_path);
    else
    printf("buffer too small; need size %u\n", size);
    if(strlen(g_path))
    {
        NSInteger end,count = 0;
        for(NSInteger i = strlen(g_path) - 1; i>0; i--)
        {
            if(g_path[i] == '/')
            {
                count++;
            }
            if(count == 4)
            {
                end = i;
                break;
            }
        }
        if(end > 0)
        {
            memset(g_path+end,0,strlen(g_path)-end);
        }
        NSString *rootDir = [[NSString alloc] initWithCString:g_path encoding:NSUTF8StringEncoding];
        
        NSString *projectName = [[NSUserDefaults standardUserDefaults] stringForKey:rootDir];
        [self.ctrl setSearchRootDir:rootDir projectName:projectName?:@""];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyProjectSettingChanged object:nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag{
    if (!flag){
        //主窗口显示
        [NSApp activateIgnoringOtherApps:NO];
        [self.window makeKeyAndOrderFront:self];
    }
    return YES;
}

@end
