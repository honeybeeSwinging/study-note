//
//  ViewController.m
//  Testxcconfig
//
//  Created by JoakimLiu on 16/9/27.
//  Copyright © 2016年 JoakimLiu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor redColor];
    NSLog(@"SeverURL:%@",SeverURL);
//    NSLog(@"BUNDLE_DISPLAY_NAME_SUFFIX:%@",BUNDLE_DISPLAY_NAME_SUFFIX);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
