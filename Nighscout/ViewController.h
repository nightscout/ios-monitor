//
//  ViewController.h
//  Nighscout
//
//  Created by John Costik on 12/8/14.
//  Copyright (c) 2014 Nightscout Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "SNVolumeSlider.h"


@interface ViewController : UIViewController <UIWebViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>


@property (weak, nonatomic) IBOutlet UIWebView *nightscoutSite;
@property (weak, nonatomic) IBOutlet UIButton *setUrl;
@property (weak, nonatomic) IBOutlet UIButton *refreshUrl;
@property (weak, nonatomic) IBOutlet UIButton *sleep;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (strong, nonatomic) IBOutlet SNVolumeSlider *alertVolume;
@property (strong, nonatomic) IBOutlet UISwitch *screenLock;
@property (strong, nonatomic) IBOutlet UIVisualEffectView *blur;

@property (strong, nonatomic) CBCentralManager *manager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCharacteristic *peripheralCharacteristic;
@property (strong, nonatomic) CBCharacteristic *authenticationCharacteristic;
@property (strong, nonatomic) CBCharacteristic *writebackCharacteristic;
@property (strong, nonatomic) CBCharacteristic *dataCharacteristic;
@property (nonatomic, readwrite) NSInteger dataIndex;
@property (strong, nonatomic) NSData *data;


- (IBAction)updateUrl:(id)sender;
- (IBAction)reloadUrl:(id)sender;
- (IBAction)changeSleep:(id)sender;
- (void)refreshNightscout;
- (void)fadeIn:(UIView*)viewToFadeIn withDuration:(NSTimeInterval)duration 	  andWait:(NSTimeInterval)wait;

@end

