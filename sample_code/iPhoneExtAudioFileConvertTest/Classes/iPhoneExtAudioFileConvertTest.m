/*
        File: iPhoneExtAudioFileConvertTest.m
    Abstract: The application delegate.
     Version: 1.2
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2013 Apple Inc. All Rights Reserved.
    
*/

#import "iPhoneExtAudioFileConvertTest.h"

extern void ThreadStateInitalize();
extern void ThreadStateBeginInterruption();
extern void ThreadStateEndInterruption();

@implementation ExtAudioFileConvertAppDelegate

@synthesize window, navigationController, myViewController;

#pragma mark -Audio Session Interruption Notification

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    printf("Session interrupted! --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
	   
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        ThreadStateBeginInterruption();
    }
    
    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure we are again the active session
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        ThreadStateEndInterruption();
    }
}

#pragma mark -Audio Session Route Change Notification

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    printf("Route change:\n");
    switch (reasonValue) {
    case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        NSLog(@"     NewDeviceAvailable");
        break;
    case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        NSLog(@"     OldDeviceUnavailable");
        break;
    case AVAudioSessionRouteChangeReasonCategoryChange:
        NSLog(@"     CategoryChange");
        break;
    case AVAudioSessionRouteChangeReasonOverride:
        NSLog(@"     Override");
        break;
    case AVAudioSessionRouteChangeReasonWakeFromSleep:
        NSLog(@"     WakeFromSleep");
        break;
    case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        NSLog(@"     NoSuitableRouteForCategory");
        break;
    default:
        NSLog(@"     ReasonUnknown");
    }
    
    printf("\nPrevious route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {    

    // Override point for customization after application launch
    self.window.rootViewController = navigationController;
        
    ThreadStateInitalize();
    
    try {
        NSError *error = nil;
        
        // Configure the audio session
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        // our default category -- we change this for conversion and playback appropriately
        [sessionInstance setCategory:AVAudioSessionCategoryAudioProcessing error:&error];
        XThrowIfError(error.code, "couldn't set audio category");
        
        // add interruption handler
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:) 
                                                     name:AVAudioSessionInterruptionNotification 
                                                   object:sessionInstance];
        
        // we don't do anything special in the route change notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRouteChange:)
                                                     name:AVAudioSessionRouteChangeNotification 
                                                   object:sessionInstance];
        
        // the session must be active for offline conversion
        [sessionInstance setActive:YES error:&error];
        XThrowIfError(error.code, "couldn't set audio session active\n");
        
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
        printf("You probably want to fix this before continuing!");
    }
}

- (void)dealloc {
    self.window = nil;
    self.navigationController = nil;
    self.myViewController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification 
                                                  object:[AVAudioSession sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification 
                                                  object:[AVAudioSession sharedInstance]]; 

    [super dealloc];
}

@end
