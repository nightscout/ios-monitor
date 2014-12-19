//
//  ViewController.m
//  Nighscout
//
//  Created by John Costik on 12/8/14.
//  Copyright (c) 2014 Nightscout Foundation. All rights reserved.
//

#import "ViewController.h"
#define MTU 20
#define AUTH 0
#define WRITE 1
#define READ 2

@interface ViewController ()
@property NSString *nightscoutUrl;
@property NSString *defaultUrl;
@property NSString *lastUrl;
@end

@implementation ViewController

static NSString* const G4ReceiverServiceUUID = @"F0ABA0B1-EBFA-F96F-28DA-076C35A521DB";
static NSString* const AuthenticationUUID = @"F0ABACAC-EBFA-F96F-28DA-076C35A521DB";
static NSString* const G4CommandWriteUUID = @"F0ABB20A-EBFA-F96F-28DA-076C35A521DB";
static NSString* const G4CommandReadUUID = @"F0ABB20B-EBFA-F96F-28DA-076C35A521DB";
static NSString* const PulseUUID = @"F0AB2B18-EBFA-F96F-28DA-076C35A521DB";
static NSString* const CradleStatusUUID = @"F0ABB0CD-EBFA-F96F-28DA-076C35A521DB";
static NSString* const PhoneCommandUUID = @"F0ABB0CC-EBFA-F96F-28DA-076C35A521DB";

NSMutableData *recvData;
bool hasAuthd = NO;

- (void)viewDidLoad {
    
    self.defaultUrl = @"http://www.nightscout.info/wiki/welcome/nightscout-for-ios-optional";
    self.blur.hidden = YES;
    [super viewDidLoad];
    
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
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
                                                timeoutInterval:10.0];
        [self.nightscoutSite loadRequest:requestObj];
        self.nightscoutSite.mediaPlaybackRequiresUserAction = NO;
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


- (IBAction)changeSleep:(id)sender {
    
    if([sender isOn]){
        NSLog(@"Switch is ON");
        NSString *key = @"screenLock";
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES]  forKey:key];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else{
        NSLog(@"Switch is OFF");
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

#pragma mark BLUETOOTH
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch(central.state)
    {
        case CBCentralManagerStatePoweredOn:
            [self.manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:G4ReceiverServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
            NSLog(@"Scanning for peripherals...");
            break;
        default:
            NSLog(@"Bluetooth LE is unsupported.");
            break;
    }
}

- (void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [self.manager stopScan];
    
    if(self.peripheral != peripheral)
    {
        self.peripheral = peripheral;
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.manager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:G4ReceiverServiceUUID]]];
    
    NSLog(@"Connecting to peripheral %@", [peripheral.identifier UUIDString]);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if(error)
    {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        return;
    }
    
    for(CBService *service in peripheral.services)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Found service with UUID: ", service.UUID];
        NSLog(@"Found service with UUID: %@", service.UUID);
        if([service.UUID isEqual:[CBUUID UUIDWithString:G4ReceiverServiceUUID]])
        {
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:AuthenticationUUID]] forService:service];
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:G4CommandWriteUUID]] forService:service];
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:G4CommandReadUUID]] forService:service];
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:PulseUUID]] forService:service];
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CradleStatusUUID]] forService:service];
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:PhoneCommandUUID]] forService:service];
        }
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error discovering characteristic: ", [error localizedDescription]];
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        return;
    }
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:G4ReceiverServiceUUID]])
    {
        for(CBCharacteristic *characteristic in service.characteristics)
        {
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:AuthenticationUUID]])
            {
                NSLog(@"Discovered Authentication characteristic");
                self.authenticationCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:self.authenticationCharacteristic];
            }
            else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:G4CommandWriteUUID]])
            {
                NSLog(@"Discovered G4CommandWrite characteristic");
                self.writebackCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:self.writebackCharacteristic];
            }
            else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:G4CommandReadUUID]])
            {
                NSLog(@"Discovered G4CommandRead characteristic");
                self.dataCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:self.dataCharacteristic];
            }

//            else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PulseUUID]])
//            {
//                NSLog(@"Discovered Pulse characteristic");
//                self.dataCharacteristic = characteristic;
//                [peripheral setNotifyValue:YES forCharacteristic:self.dataCharacteristic];
//            }
//            else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CradleStatusUUID]])
//            {
//                NSLog(@"Discovered CradleStatus characteristic");
//                self.writebackCharacteristic = characteristic;
//                [peripheral setNotifyValue:YES forCharacteristic:self.writebackCharacteristic];
//            }
//            else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PhoneCommandUUID]])
//            {
//                NSLog(@"Discovered PhoneCommand characteristic");
//                self.dataCharacteristic = characteristic;
//                [peripheral setNotifyValue:YES forCharacteristic:self.dataCharacteristic];
//            }
        }
    }
    
    if(self.authenticationCharacteristic != nil && hasAuthd!=YES) {
        NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
        NSString *sn = [NSString stringWithFormat:@"%@%@",[data objectForKey:@"g4Sn"], @"000000"];
        self.data = [sn dataUsingEncoding:NSASCIIStringEncoding];
        self.dataIndex = 0;
        [self sendData:AUTH];
        hasAuthd = YES;
    }
    
    
}
- (void)peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
        return;
    }
    
    if(!([characteristic.UUID isEqual:[CBUUID UUIDWithString:AuthenticationUUID]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:G4CommandReadUUID]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:G4CommandWriteUUID]]))
    {
        return;
    }
    
    if(characteristic.isNotifying)
    {
        NSLog(@"Notification began on %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
    }
    else
    {
        NSLog(@"Notification has stopped on %@", characteristic);
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        NSLog(@"Error reading updated characteristic value: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    if([stringFromData isEqualToString:@"EOM"])
    {
        if(recvData != nil)
        {
            NSLog(@"DONE RECV");
            NSString *final = [[NSString alloc] initWithData:recvData encoding:NSUTF8StringEncoding];
            NSLog(@"[IN:]%@",final);
            recvData = nil;
        }
    }
    else
    {
        if(recvData == nil)
        {
            recvData = [[NSMutableData alloc] initWithData:characteristic.value];
        }
        else
        {
            [recvData appendData:characteristic.value];
        }
    }
}

- (void)sendData:(int)characteristic
{
    if(self.dataIndex >= self.data.length)
    {
        return;
    }
    
    BOOL doneSending = NO;
    
    while(!doneSending)
    {
        NSInteger sendAmt = self.data.length - self.dataIndex;
        
        if(sendAmt > MTU)
        {
            sendAmt = MTU;
        }
        
        NSData *packet = [NSData dataWithBytes:self.data.bytes+self.dataIndex length:sendAmt];
        NSLog(@"Sending packet: %@", packet.description);
        
        switch(characteristic)
        {
            case AUTH:
                [self.peripheral writeValue:packet forCharacteristic:self.authenticationCharacteristic type:CBCharacteristicWriteWithResponse];
                break;
            case READ:
                break;
            case WRITE:
                break;
        }
        
        self.dataIndex += sendAmt;
        
        if(self.dataIndex >= self.data.length)
        {
            switch(characteristic)
            {
                case AUTH:
                    [self.peripheral writeValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.authenticationCharacteristic type:CBCharacteristicWriteWithResponse];
                    break;
                case READ:
                    break;
                case WRITE:
                    break;
            }
            doneSending = YES;
            return;
        }
        packet = nil;
    }
}


@end
