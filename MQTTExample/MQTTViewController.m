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

// this UISwitch will be used to display the status received from the topic.
@property (weak, nonatomic) IBOutlet UISwitch *subscribedSwitch;

// create a property for the MQTTClient that is used to send and receive the message
@property (nonatomic, strong) MQTTClient *client;

@end

@implementation MQTTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // create the MQTT client with an unique identifier
    NSString *clientID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    self.client = [[MQTTClient alloc] initWithClientId:clientID];

    // keep a reference on the switch to avoid having a reference to self in the
    // block below (retain/release cycle, blah blah blah)
    UISwitch *subSwitch = self.subscribedSwitch;

    // define the handler that will be called when MQTT messages are receive by the client
    [self.client setMessageHandler:^(MQTTMessage *message) {
        // extract the switch status from the message payload
        BOOL on = [message.payloadString boolValue];

        // the MQTTClientDelegate methods are called from a GCD queue.
        // Any update to the UI must be done on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [subSwitch setOn:on animated:YES];
        });
    }];

    // connect the MQTT client
    [self.client connectToHost:kMQTTServerHost completionHandler:^(NSUInteger code) {
        // The client is connected when this completion handler is called
        NSLog(@"client is connected with id %@", clientID);
        // Subscribe to the topic
        [self.client subscribe:kTopic withCompletionHandler:^(NSArray *grantedQos) {
            // The client is effectively subscribed to the topic when this completion handler is called
             NSLog(@"subscribed to topic %@", kTopic);
         }];
    }];
}

- (void)dealloc
{
    // disconnect the MQTT client
    [self.client disconnectWithCompletionHandler:^(NSUInteger code) {
        // The client is disconnected when this completion handler is called
        NSLog(@"MQTT is disconnected");
    }];
}

#pragma mark - IBActions

// This method is called when the "published LED" switch status changes
- (IBAction)switchUpdated:(id)sender {
    BOOL on = [sender isOn];
    NSString *payload = [NSNumber numberWithBool:on].stringValue;

    // use the MQTT client to send a message with the switch status to the topic
    [self.client publishString:payload
                       toTopic:kTopic
                       withQos:AtMostOnce
                        retain:YES
             completionHandler:nil];
    // we passed nil to the completionHandler as we are not interested to know
    // when the message was effectively sent
}

@end
