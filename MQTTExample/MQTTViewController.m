//
//  MQTTViewController.m
//  MQTTExample
//
//  Created by Jeff Mesnil on 15/02/2014.
//  Copyright (c) 2014 jmesnil.net. All rights reserved.
//

#import "MQTTViewController.h"
#import <MQTTKit.h>

#define kMQTTServerHost @"iot.eclipse.org"
#define kTopic @"MQTTExample/LED"

@interface MQTTViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *subscribedSwitch;

@property (nonatomic, strong) MQTTClient *client;

@end

@implementation MQTTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *clientID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    self.client = [[MQTTClient alloc] initWithClientId:clientID];

    UISwitch *subSwitch = self.subscribedSwitch;

    // define the message handler that will handle the received MQTT messages
    [self.client setMessageHandler:^(MQTTMessage *message) {
        BOOL on = [message.payloadString boolValue];
        // the MQTTClientDelegate methods are called from a GCD queue.
        // Any update to the UI must be done on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [subSwitch setOn:on animated:YES];
        });
    }];
    // connect the MQTT client
    [self.client connectToHost:kMQTTServerHost completionHandler:^(NSUInteger code) {
        NSLog(@"client is connected with id %@", clientID);
        // once the client is connected, subscribe to the topic
        [self.client subscribe:kTopic
         withCompletionHandler:^(NSArray *grantedQos) {
             NSLog(@"subscribed to topic %@", kTopic);
         }];
    }];
}

- (void)dealloc
{
    [self.client disconnectWithCompletionHandler:^(NSUInteger code) {
        NSLog(@"MQTT is disconnected");
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)switchUpdated:(id)sender {
    BOOL on = [sender isOn];
    NSString *payload = [NSNumber numberWithBool:on].stringValue;

    [self.client publishString:payload
                       toTopic:kTopic
                       withQos:AtMostOnce
                        retain:YES
             completionHandler:nil];
}

@end
