//
//  WarningWindowController.m
//  ZFStringsManager
//
//  Created by feng on 2019/12/25.
//  Copyright © 2019 zhangfeng. All rights reserved.
//

#import "WarningWindowController.h"

@interface WarningWindowController ()
@property (strong) IBOutlet NSTextView *textView;
@property (strong) NSString *text;
@end

@implementation WarningWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
//    self.window.showsToolbarButton = NO;
    _textView.editable = NO;
    _textView.string = self.text;
}

- (void)refreshText:(NSString *)text {
    self.text = text;
    self.textView.string = text;
}


@end
