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
@property NSString *lastUrl;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    self.defaultUrl = @"http://www.nightscout.info/wiki/welcome/nightscout-for-ios-optional";
    
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.nightscoutSite.delegate = self;
    self.nightscoutSite.backgroundColor = [UIColor clearColor];
    self.nightscoutSite.alpha = 0.0;
    
    [self.loadingIndicator startAnimating];
    
    [self registerDefaultsFromSettingsBundle];
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    self.lastUrl = [data objectForKey:@"lastUrl"];
    NSNumber *screenLock = [data valueForKey:@"screenLock"];
    NSInteger screenLockValue = [screenLock intValue];
    
    if (self.lastUrl==nil || [self.lastUrl  isEqual:self.defaultUrl]){
        [self requestUrl:@"Please enter your Nightscout URL"];
        [self.setUrl setTitle:@"Set URL" forState: UIControlStateNormal];
    } else
    {
        self.nightscoutSite.scrollView.scrollEnabled = NO;
        self.nightscoutUrl = self.lastUrl;
        [self.setUrl setTitle:@"Change URL" forState: UIControlStateNormal];
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

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self loadUrl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)requestUrl:(NSString *)message {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Hello!" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue",nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeAlphabet;
    
    if (self.lastUrl==nil || [self.lastUrl  isEqual:self.defaultUrl]){
        alertTextField.placeholder = @"http://your.nightscout.site";
    } else
    {
        alertTextField.text = self.lastUrl;
    }
    
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
    if (buttonIndex==1){
        NSLog(@"Entered: %@",[[alertView textFieldAtIndex:0] text]);
        self.nightscoutUrl =[[alertView textFieldAtIndex:0] text];
        if ([self.nightscoutUrl hasPrefix:@"http://"] || [self.nightscoutUrl hasPrefix:@"https://"] )
        {
            //good to go
        }
        else {
            self.nightscoutUrl = [NSString stringWithFormat:@"http://%@", self.nightscoutUrl];
        }
        NSString *key = @"lastUrl";
        [[NSUserDefaults standardUserDefaults] setObject:self.nightscoutUrl  forKey:key];
        self.lastUrl = self.nightscoutUrl;
        self.nightscoutSite.scrollView.scrollEnabled = NO;
        [self.setUrl setTitle:@"Change URL" forState: UIControlStateNormal];
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

#pragma mark - UIWebViewDelegate delegate methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
    webView.backgroundColor = [UIColor blackColor];
    webView.opaque = YES;
    
    [self fadeIn : webView withDuration: 2 andWait : 0 ];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self requestUrl:@"Sorry, I couldn't load the page, please verify address:"];
    NSLog(@"Error loading page");
}

#pragma mark ANIMATION
-(void)fadeIn:(UIView*)viewToFadeIn withDuration:(NSTimeInterval)duration 	  andWait:(NSTimeInterval)wait
{
    [UIView beginAnimations: @"Fade In" context:nil];
    
    // wait for time before begin
    [UIView setAnimationDelay:wait];
    
    // druation of animation
    [UIView setAnimationDuration:duration];
    viewToFadeIn.alpha = 1;
    [UIView commitAnimations];
    [self.loadingIndicator stopAnimating];
    
}

@end
