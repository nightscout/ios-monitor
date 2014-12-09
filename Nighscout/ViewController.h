//
//  ViewController.h
//  Nighscout
//
//  Created by John Costik on 12/8/14.
//  Copyright (c) 2014 Nightscout Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIWebViewDelegate>


@property (weak, nonatomic) IBOutlet UIWebView *nightscoutSite;
@property (weak, nonatomic) IBOutlet UIButton *setUrl;
@property (weak, nonatomic) IBOutlet UIButton *refreshUrl;
@property (weak, nonatomic) IBOutlet UIButton *sleep;

- (IBAction)updateUrl:(id)sender;
- (IBAction)reloadUrl:(id)sender;
- (IBAction)changeSleep:(id)sender;

@end

