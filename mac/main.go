package main

/*
#cgo CFLAGS: -x objective-c -fobjc-arc
#cgo LDFLAGS: -framework Cocoa

#import <Cocoa/Cocoa.h>

// ──── Global state ────
static NSWindow      *gWindow;
static NSTextField   *gLabel;
static NSPopUpButton *gCombo;
static NSButton      *gBtn;
static NSTimer       *gTimer;

static int  gIntervals[]  = {1, 2, 5, 10, 15, 20, 30, 45, 60};
static int  gIntervalCount = 9;
static int  gIntervalMin  = 20;
static int  gRemaining    = 0;
static BOOL gRunning      = NO;

// ──── App Controller ────
@interface RGController : NSObject <NSApplicationDelegate>
- (void)buildWindow;
- (void)updateUI;
@end

@implementation RGController

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)n {
    [self buildWindow];
    [self updateUI];
}

- (void)buildWindow {
    NSUInteger mask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
    gWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 360, 220)
                                          styleMask:mask
                                            backing:NSBackingStoreBuffered
                                              defer:NO];
    [gWindow setTitle:@"Retina Guard"];
    [gWindow center];
    NSView *v = [gWindow contentView];

    // Status label
    gLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 155, 320, 28)];
    [gLabel setStringValue:@"Click Start to begin"];
    [gLabel setBezeled:NO];
    [gLabel setDrawsBackground:NO];
    [gLabel setEditable:NO];
    [gLabel setSelectable:NO];
    [gLabel setAlignment:NSTextAlignmentCenter];
    [gLabel setFont:[NSFont systemFontOfSize:16 weight:NSFontWeightMedium]];
    [v addSubview:gLabel];

    // "Interval:" label
    NSTextField *lbl = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 115, 80, 24)];
    [lbl setStringValue:@"Interval:"];
    [lbl setBezeled:NO];
    [lbl setDrawsBackground:NO];
    [lbl setEditable:NO];
    [lbl setSelectable:NO];
    [lbl setAlignment:NSTextAlignmentRight];
    [lbl setFont:[NSFont systemFontOfSize:13]];
    [v addSubview:lbl];

    // Interval popup button
    gCombo = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(140, 115, 160, 28) pullsDown:NO];
    for (int i = 0; i < gIntervalCount; i++) {
        [gCombo addItemWithTitle:[NSString stringWithFormat:@"%d min", gIntervals[i]]];
    }
    [gCombo selectItemAtIndex:5]; // default 20 min
    [gCombo setTarget:self];
    [gCombo setAction:@selector(comboChanged:)];
    [v addSubview:gCombo];

    // Start/Stop button
    gBtn = [[NSButton alloc] initWithFrame:NSMakeRect(100, 50, 160, 44)];
    [gBtn setTitle:@"Start"];
    [gBtn setBezelStyle:NSBezelStyleRounded];
    [gBtn setTarget:self];
    [gBtn setAction:@selector(buttonClicked:)];
    [gBtn setFont:[NSFont systemFontOfSize:14 weight:NSFontWeightMedium]];
    [v addSubview:gBtn];

    [gWindow makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)updateUI {
    if (gRunning) {
        int m = gRemaining / 60;
        int s = gRemaining % 60;
        [gLabel setStringValue:[NSString stringWithFormat:@"Next reminder in %02d:%02d", m, s]];
        [gBtn setTitle:@"Stop"];
    } else {
        [gLabel setStringValue:@"Click Start to begin"];
        [gBtn setTitle:@"Start"];
    }
}

- (void)buttonClicked:(id)sender {
    if (gRunning) {
        gRunning = NO;
        [gTimer invalidate];
        gTimer = nil;
    } else {
        gRunning = YES;
        gRemaining = gIntervalMin * 60;
        gTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                          target:self
                          selector:@selector(timerFired:)
                          userInfo:nil
                          repeats:YES];
    }
    [self updateUI];
}

- (void)comboChanged:(id)sender {
    if (!gRunning) {
        NSInteger idx = [gCombo indexOfSelectedItem];
        if (idx >= 0 && idx < gIntervalCount) {
            gIntervalMin = gIntervals[idx];
        }
    } else {
        // Revert selection while running
        for (int i = 0; i < gIntervalCount; i++) {
            if (gIntervals[i] == gIntervalMin) {
                [gCombo selectItemAtIndex:i];
                break;
            }
        }
    }
}

- (void)timerFired:(NSTimer *)t {
    if (!gRunning) return;
    gRemaining--;
    if (gRemaining <= 0) {
        gRemaining = gIntervalMin * 60;
        [self updateUI];

        // Play Glass sound
        NSSound *sound = [NSSound soundNamed:@"Glass"];
        [sound play];

        // Show blocking alert (mirrors Windows MessageBox behavior)
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Retina Guard"];
        [alert setInformativeText:@"Please look at something 20 feet away for 20 seconds."];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];

        // Reset after user clicks OK
        gRemaining = gIntervalMin * 60;
        [self updateUI];
    } else {
        [self updateUI];
    }
}

@end

// Keep a strong reference so ARC doesn't release it
static RGController *gController;

static void run(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        // Menu bar
        NSMenu *menuBar = [[NSMenu alloc] init];
        NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
        [menuBar addItem:appMenuItem];
        [NSApp setMainMenu:menuBar];
        NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Retina Guard"];
        [appMenu addItemWithTitle:@"Quit Retina Guard"
                           action:@selector(terminate:)
                    keyEquivalent:@"q"];
        [appMenuItem setSubmenu:appMenu];

        gController = [[RGController alloc] init];
        [NSApp setDelegate:gController];
        [NSApp run];
    }
}
*/
import "C"

import "runtime"

func main() {
	runtime.LockOSThread()
	C.run()
}
