//
//  ViewController.m
//  Nighscout
//
//  Created by John Costik on 12/8/14.
//  Copyright (c) 2014 Nightscout Foundation. All rights reserved.
//

#import "ViewController.h"
#import "SettingsManager.h"

@interface ViewController ()
@property NSString *nightscoutUrl;
@property NSString *defaultUrl;
@property NSString *lastUrl;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    self.defaultUrl = @"http://www.nightscout.info/wiki/welcome/nightscout-for-ios-optional";
    self.blur.hidden = YES;
    [super viewDidLoad];
    self.alertVolume = [[SNVolumeSlider alloc] init];
    [self.setUrl.layer setBorderWidth:1.0];
    [self.setUrl.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.refreshUrl.layer setBorderWidth:1.0];
    [self.refreshUrl.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self setNeedsStatusBarAppearanceUpdate];
    [self refreshNightscout];
    

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
    
    //TODO: boolean return method as this is being reused
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
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                timeoutInterval:30.0];
        [self.nightscoutSite loadRequest:requestObj];
        self.nightscoutSite.mediaPlaybackRequiresUserAction = NO;
    } else {
        [self requestUrl:@"Hmm, URL was not valid, please retry"];
        [[SettingsManager sharedManager] setLastURL:self.defaultUrl];
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
        [[SettingsManager sharedManager] setLastURL:self.nightscoutUrl];
        self.lastUrl = self.nightscoutUrl;
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

- (void) refreshNightscout {
    self.nightscoutSite.delegate = self;
    self.nightscoutSite.backgroundColor = [UIColor clearColor];
    self.nightscoutSite.alpha = 0.0;
    
    [self.loadingIndicator startAnimating];
    
    self.lastUrl = [[SettingsManager sharedManager] getLastURL];
    BOOL screenLock = [[SettingsManager sharedManager] isScreenLock];
    
    if (self.lastUrl==nil || [self.lastUrl  isEqual:self.defaultUrl]){
        [self requestUrl:@"Please enter your Nightscout URL"];
        [self.setUrl setTitle:@"Set URL" forState: UIControlStateNormal];
    } else
    {
        self.nightscoutUrl = self.lastUrl;
        [self.setUrl setTitle:@"Change URL" forState: UIControlStateNormal];
        [self loadUrl];
    }
    if (screenLock) {
        [self.sleep setTitle: @"Sleep Off" forState: UIControlStateNormal];
    } else {
        [self.sleep setTitle: @"Sleep On" forState: UIControlStateNormal];
    }

}


- (IBAction)changeSleep:(id)sender {
    [[SettingsManager sharedManager] setScreenLock:[sender isOn]];
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
        
    [self fadeIn : webView withDuration: 3 andWait : 1 ];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.loadingIndicator stopAnimating];
    // Disable user selection
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    // Disable callout
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //[self.loadingIndicator stopAnimating];
    //[self requestUrl:@"Sorry, I couldn't load the page, please verify address:"];
    NSLog(@"Error loading page");
}

#pragma mark ANIMATION
-(void)fadeIn:(UIView*)viewToFadeIn withDuration:(NSTimeInterval)duration 	  andWait:(NSTimeInterval)wait
{
    self.nightscoutSite.backgroundColor = [UIColor blackColor];
    self.nightscoutSite.opaque = YES;
    [UIView beginAnimations: @"Fade In" context:nil];
    
    // wait for time before begin
    [UIView setAnimationDelay:wait];
    
    // druation of animation
    [UIView setAnimationDuration:duration];
    viewToFadeIn.alpha = 1;
    [UIView commitAnimations];

}

- (void)toggleScreenLockOverride:(BOOL)on {
    [self.screenLock setOn:on animated:NO];
    [[SettingsManager sharedManager] setScreenLock:on];
}

@end
