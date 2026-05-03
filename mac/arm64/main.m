#import <Cocoa/Cocoa.h>

@interface RGAppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) NSPopUpButton *intervalPopup;
@property(nonatomic, strong) NSButton *startButton;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic) NSInteger intervalMinutes;
@property(nonatomic) NSInteger remainingSeconds;
@property(nonatomic) BOOL running;
@end

@implementation RGAppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _intervalMinutes = 20;
        _remainingSeconds = 0;
        _running = NO;
    }
    return self;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self buildWindow];
    [self updateUI];
}

- (void)buildWindow {
    NSWindowStyleMask style = NSWindowStyleMaskTitled |
                              NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable;

    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 380, 230)
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    self.window.title = @"Retina Guard";
    self.window.releasedWhenClosed = NO;
    self.window.minSize = NSMakeSize(380, 230);
    [self.window center];

    NSView *contentView = self.window.contentView;

    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(24, 160, 332, 28)];
    self.statusLabel.bezeled = NO;
    self.statusLabel.drawsBackground = NO;
    self.statusLabel.editable = NO;
    self.statusLabel.selectable = NO;
    self.statusLabel.alignment = NSTextAlignmentCenter;
    self.statusLabel.font = [NSFont systemFontOfSize:16 weight:NSFontWeightMedium];
    [contentView addSubview:self.statusLabel];

    NSTextField *intervalLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(55, 118, 90, 24)];
    intervalLabel.stringValue = @"Interval:";
    intervalLabel.bezeled = NO;
    intervalLabel.drawsBackground = NO;
    intervalLabel.editable = NO;
    intervalLabel.selectable = NO;
    intervalLabel.alignment = NSTextAlignmentRight;
    intervalLabel.font = [NSFont systemFontOfSize:13];
    [contentView addSubview:intervalLabel];

    self.intervalPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(155, 116, 150, 28)
                                                    pullsDown:NO];
    NSArray<NSNumber *> *intervals = @[@1, @2, @5, @10, @15, @20, @30, @45, @60];
    for (NSNumber *interval in intervals) {
        [self.intervalPopup addItemWithTitle:[NSString stringWithFormat:@"%@ min", interval]];
    }
    [self.intervalPopup selectItemWithTitle:@"20 min"];
    self.intervalPopup.target = self;
    self.intervalPopup.action = @selector(intervalChanged:);
    [contentView addSubview:self.intervalPopup];

    self.startButton = [[NSButton alloc] initWithFrame:NSMakeRect(110, 50, 160, 44)];
    self.startButton.bezelStyle = NSBezelStyleRounded;
    self.startButton.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    self.startButton.target = self;
    self.startButton.action = @selector(startStopClicked:);
    [contentView addSubview:self.startButton];

    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)updateUI {
    if (self.running) {
        NSInteger minutes = self.remainingSeconds / 60;
        NSInteger seconds = self.remainingSeconds % 60;
        self.statusLabel.stringValue = [NSString stringWithFormat:@"Next reminder in %02ld:%02ld",
                                        (long)minutes,
                                        (long)seconds];
        self.startButton.title = @"Stop";
        self.intervalPopup.enabled = NO;
    } else {
        self.statusLabel.stringValue = @"Click Start to begin";
        self.startButton.title = @"Start";
        self.intervalPopup.enabled = YES;
    }
}

- (void)startStopClicked:(id)sender {
    if (self.running) {
        [self stopTimer];
    } else {
        [self startTimer];
    }
    [self updateUI];
}

- (void)intervalChanged:(id)sender {
    NSString *title = self.intervalPopup.titleOfSelectedItem;
    self.intervalMinutes = title.integerValue;
}

- (void)startTimer {
    self.running = YES;
    self.remainingSeconds = self.intervalMinutes * 60;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(timerFired:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopTimer {
    self.running = NO;
    [self.timer invalidate];
    self.timer = nil;
    self.remainingSeconds = 0;
}

- (void)timerFired:(NSTimer *)timer {
    if (!self.running) {
        return;
    }

    self.remainingSeconds -= 1;
    if (self.remainingSeconds > 0) {
        [self updateUI];
        return;
    }

    self.remainingSeconds = self.intervalMinutes * 60;
    [self updateUI];

    NSSound *sound = [NSSound soundNamed:@"Glass"];
    [sound play];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Retina Guard";
    alert.informativeText = @"Please look at something 20 feet away for 20 seconds.";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];

    self.remainingSeconds = self.intervalMinutes * 60;
    [self updateUI];
}

@end

static void RGInstallMenu(void) {
    NSMenu *menuBar = [[NSMenu alloc] init];
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [menuBar addItem:appMenuItem];
    NSApp.mainMenu = menuBar;

    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Retina Guard"];
    [appMenu addItemWithTitle:@"Quit Retina Guard"
                       action:@selector(terminate:)
                keyEquivalent:@"q"];
    appMenuItem.submenu = appMenu;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        app.activationPolicy = NSApplicationActivationPolicyRegular;

        RGInstallMenu();

        RGAppDelegate *delegate = [[RGAppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
