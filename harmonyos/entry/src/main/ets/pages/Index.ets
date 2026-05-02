import { common } from '@kit.AbilityKit';
import { repo } from '../common/PreferencesRepo';
import { AppSettings, SessionState, TodayStats } from '../common/Models';
import { PermissionState, PermissionHelper } from '../common/PermissionHelper';
import { NotificationHelper } from '../common/NotificationHelper';
import { AlarmScheduler } from '../common/AlarmScheduler';
import { ScreenUsageTracker } from '../common/ScreenUsageTracker';
import { OnboardingPage } from './OnboardingPage';
import { TodayPage } from './TodayPage';
import { SchedulePage } from './SchedulePage';
import { SettingsPage } from './SettingsPage';

@Entry
@Component
struct Index {
  @State settings: AppSettings = new AppSettings();
  @State session: SessionState = new SessionState();
  @State stats: TodayStats = new TodayStats();
  @State perms: PermissionState = new PermissionState();
  @State onboardingDone: boolean = false;
  @State currentTab: number = 0;
  @State ready: boolean = false;

  private timer: number = -1;
  private tracker: ScreenUsageTracker = new ScreenUsageTracker();
  private context: common.UIAbilityContext | null = null;

  async aboutToAppear(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    this.context = ctx;
    await repo.init(ctx);
    await this.loadData();
    await NotificationHelper.ensureChannels();
    this.ready = true;
    if (this.session.protectionRunning) {
      this.startTicker();
    }
  }

  aboutToDisappear(): void {
    this.stopTicker();
  }

  private async loadData(): Promise<void> {
    this.settings = await repo.getSettings();
    this.session = await repo.getSession();
    this.stats = await repo.getStats();
    if (this.context) {
      this.perms = await PermissionState.read(this.context);
    }
    this.onboardingDone = this.settings.onboardingDone;
  }

  private startTicker(): void {
    this.stopTicker();
    if (this.settings.usageAwareEnabled) {
      this.tracker.start(this.session.protectionStartedAtMillis > 0 ? 0 : 0, this.settings.excludedPackages);
    }
    this.timer = setInterval(async () => {
      if (!this.session.protectionRunning) { this.stopTicker(); return; }

      if (this.settings.usageAwareEnabled) {
        this.tracker.tick();
        const accum = this.tracker.getAccumulatedMs();
        const intervalMs = this.settings.intervalMinutes * 60_000;
        if (accum >= intervalMs) {
          await this.onBreakDue();
          this.tracker.start(0, this.settings.excludedPackages);
        }
      } else {
        const now = Date.now();
        if (now >= this.session.nextDueAtMillis && this.session.nextDueAtMillis > 0) {
          await this.onBreakDue();
        }
      }
      this.session = await repo.getSession();
      this.stats = await repo.getStats();
    }, 1000);
  }

  private stopTicker(): void {
    if (this.timer >= 0) { clearInterval(this.timer); this.timer = -1; }
  }

  private async onBreakDue(): Promise<void> {
    await repo.markReminderShown();
    await NotificationHelper.postBreakReminder(this.settings);
    const now = Date.now();
    const nextDue = now + this.settings.intervalMinutes * 60_000;
    await repo.setNextDueAt(nextDue);
    await repo.resetAccumulatedScreenMs();
    await AlarmScheduler.schedule(nextDue, 1001);
  }

  private async onStart(): Promise<void> {
    const now = Date.now();
    const due = now + this.settings.intervalMinutes * 60_000;
    await repo.startProtection(due, now);
    await AlarmScheduler.schedule(due, 1001);
    this.session = await repo.getSession();
    this.startTicker();
  }

  private async onStop(): Promise<void> {
    this.stopTicker();
    this.tracker.stop();
    await AlarmScheduler.cancelAll();
    await repo.stopProtection(Date.now());
    await NotificationHelper.cancelOngoing();
    this.session = await repo.getSession();
    this.stats = await repo.getStats();
  }

  private async onTakeBreakNow(): Promise<void> {
    if (this.context) {
      const want = { bundleName: 'com.retinaguard.app', abilityName: 'BreakAbility' };
      try { await (await import('@kit.AbilityKit')).common.startAbility(this.context, want); } catch { }
    }
  }

  build() {
    if (!this.ready) {
      Column() {
        Text('Loading...')
          .fontSize(16)
          .fontColor('#86868B')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF')
      return;
    }

    if (!this.onboardingDone) {
      OnboardingPage({
        perms: this.perms,
        onRefresh: () => { this.loadData(); },
        onFinish: async () => {
          await repo.setOnboardingDone(true);
          this.onboardingDone = true;
        }
      })
      return;
    }

    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
      // Today
      TabContent() {
        TodayPage({
          settings: this.settings,
          session: this.session,
          stats: this.stats,
          perms: this.perms,
          onStart: () => this.onStart(),
          onStop: () => this.onStop(),
          onTakeBreakNow: () => this.onTakeBreakNow(),
          onIntervalChange: async (m: number) => {
            await repo.setInterval(m);
            this.settings = await repo.getSettings();
          }
        })
      }
      .tabBar(this.tabItem('Today', 0))

      // Schedule
      TabContent() {
        SchedulePage({
          settings: this.settings,
          onDailyChange: async (v: boolean) => { await repo.setDailyScheduleEnabled(v); this.settings = await repo.getSettings(); },
          onQuietChange: async (v: boolean) => { await repo.setQuietHoursEnabled(v); this.settings = await repo.getSettings(); },
          onDaysChange: async (m: number) => { await repo.setActiveDaysMask(m); this.settings = await repo.getSettings(); }
        })
      }
      .tabBar(this.tabItem('Schedule', 1))

      // Settings
      TabContent() {
        SettingsPage({
          settings: this.settings,
          perms: this.perms,
          onReminderStyleChange: async (s: string) => { await repo.setReminderStyle(s); this.settings = await repo.getSettings(); },
          onSoundModeChange: async (s: string) => { await repo.setSoundMode(s); this.settings = await repo.getSettings(); },
          onVibrationChange: async (v: boolean) => { await repo.setVibration(v); this.settings = await repo.getSettings(); },
          onUsageAwareChange: async (v: boolean) => { await repo.setUsageAwareEnabled(v); this.settings = await repo.getSettings(); },
          onExcludedPackagesChange: async (p: string[]) => { await repo.setExcludedPackages(p); this.settings = await repo.getSettings(); },
          onResetStats: async () => { await repo.resetTodayStats(); this.stats = await repo.getStats(); },
          onRefreshPerms: async () => { if (this.context) this.perms = await PermissionState.read(this.context); }
        })
      }
      .tabBar(this.tabItem('Settings', 2))
    }
    .onChange((index: number) => { this.currentTab = index; })
    .barWidth('100%')
    .barHeight(56)
    .scrollable(false)
    .animationDuration(0)
  }

  @Builder
  tabItem(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(this.currentTab === index ? '#E60000' : '#86868B')
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
