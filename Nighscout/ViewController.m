//
//  ViewController.m
//  Nighscout
//
//  Created by John Costik on 12/8/14.
//  Copyright (c) 2014 Nightscout Foundation. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()
@property NSString *nightscoutUrl;
@property NSString *defaultUrl;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self registerDefaultsFromSettingsBundle];
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    NSString *lastUrl = [data objectForKey:@"lastUrl"];
    NSNumber *screenLock = [data valueForKey:@"screenLock"];
    NSInteger screenLockValue = [screenLock intValue];
    
    if (lastUrl==nil || [lastUrl  isEqual:self.defaultUrl]){
        [self requestUrl:@"Please enter your Nightscout URL"];
    } else
    {
        self.nightscoutUrl = lastUrl;
        [self loadUrl];
    }
    
    if(screenLockValue == 1)
    {
        [self.sleep setTitle: @"Sleep Off" forState: UIControlStateNormal];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        
    } else{
        
        [self.sleep setTitle: @"Sleep On" forState: UIControlStateNormal];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)requestUrl:(NSString *)message {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Hello!" message:message delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:@"Cancel",nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeAlphabet;
    alertTextField.placeholder = @"http://your.nightscout.site";
    [alert show];
}

- (void)loadUrl {
    NSURL *url = [NSURL URLWithString:self.nightscoutUrl];
    if (url && url.scheme && url.host) {
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        [self.nightscoutSite loadRequest:requestObj];
        self.nightscoutSite.mediaPlaybackRequiresUserAction = NO;
        NSString * jsCallBack = @"window.getSelection().removeAllRanges();";
        [self.nightscoutSite stringByEvaluatingJavaScriptFromString:jsCallBack];
    } else {
        [self requestUrl:@"Hmm, URL was not valid, please retry"];
        NSString *key = @"lastUrl";
        [[NSUserDefaults standardUserDefaults] setObject:self.defaultUrl forKey:key];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==0){
        NSLog(@"Entered: %@",[[alertView textFieldAtIndex:0] text]);
        self.nightscoutUrl =[[alertView textFieldAtIndex:0] text];
        NSString *key = @"lastUrl";
        [[NSUserDefaults standardUserDefaults] setObject:self.nightscoutUrl  forKey:key];
        [self loadUrl];
    } else {
        NSURL *url = [NSURL URLWithString:self.nightscoutUrl];
        if (url && url.scheme && url.host) {
            [self loadUrl];
        } else {
            NSURL *url = [NSURL URLWithString:self.defaultUrl ];
            if (url && url.scheme && url.host) {
                NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
                [self.nightscoutSite loadRequest:requestObj];
            }
        }
    }
    
}

- (IBAction)updateUrl:(id)sender {
    [self requestUrl:@"Please enter your Nightscout URL"];
}

- (IBAction)reloadUrl:(id)sender {
    [self loadUrl];
}

- (IBAction)changeSleep:(id)sender {
    NSString *title = [(UIButton *)sender currentTitle];
    if([title isEqual:@"Sleep On"])
    {
        [self.sleep setTitle: @"Sleep Off" forState: UIControlStateNormal];
        NSString *key = @"screenLock";
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES]  forKey:key];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else{
        [self.sleep setTitle: @"Sleep On" forState: UIControlStateNormal];
        NSString *key = @"screenLock";
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO]  forKey:key];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)registerDefaultsFromSettingsBundle {
    // this function writes default settings as settings
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
            NSLog(@"writing as default %@ to the key %@",[prefSpecification objectForKey:@"DefaultValue"],key);
        }
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
    
}

@end
