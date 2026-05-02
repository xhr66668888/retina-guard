import { AppSettings, SessionState, TodayStats, INTERVAL_CHOICES } from '../common/Models';
import { PermissionState } from '../common/PermissionHelper';
import { RedPillButton, GhostButton } from '../components/Buttons';
import { RedBand } from '../components/ChecklistRow';

@Component
export struct TodayPage {
  @Prop settings: AppSettings;
  @Prop session: SessionState;
  @Prop stats: TodayStats;
  @Prop perms: PermissionState;
  onStart: () => void = () => {};
  onStop: () => void = () => {};
  onTakeBreakNow: () => void = () => {};
  onIntervalChange: (m: number) => void = () => {};

  @State nowMs: number = Date.now();
  private tickTimer: number = -1;

  aboutToAppear(): void {
    this.nowMs = Date.now();
    this.tickTimer = setInterval(() => { this.nowMs = Date.now(); }, 500);
  }

  aboutToDisappear(): void {
    if (this.tickTimer >= 0) clearInterval(this.tickTimer);
  }

  private get remainingSec(): number {
    if (this.session.protectionRunning) {
      return Math.max(0, Math.floor((this.session.nextDueAtMillis - this.nowMs) / 1000));
    }
    return this.settings.intervalMinutes * 60;
  }

  private get timerText(): string {
    const m = Math.floor(this.remainingSec / 60);
    const s = this.remainingSec % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }

  private get subText(): string {
    if (this.session.protectionRunning) {
      const d = new Date(this.session.nextDueAtMillis);
      return `next break at ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
    }
    return 'until your next eye break';
  }

  private get protectedLabel(): string {
    const h = Math.floor(this.stats.protectedSeconds / 3600);
    const m = Math.floor((this.stats.protectedSeconds % 3600) / 60);
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  }

  build() {
    Column() {
      // Header
      Text('RETINA GUARD')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ top: 12, left: 24 })

      // Timer hero
      Column() {
        Text(this.timerText)
          .fontSize(80)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D1D1F')
          .margin({ top: 28 })

        Text(this.subText)
          .fontSize(16)
          .fontColor('#86868B')
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 24 })

      // Buttons
      Row() {
        if (this.session.protectionRunning) {
          GhostButton({ text: 'Stop', onAction: this.onStop })
            .layoutWeight(1)
            .margin({ right: 6 })
          RedPillButton({ text: 'Take break now', enabled: true, onAction: this.onTakeBreakNow })
            .layoutWeight(1)
            .margin({ left: 6 })
        } else {
          RedPillButton({ text: 'Start protection', enabled: this.perms.ready, onAction: this.onStart })
            .layoutWeight(1)
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      .margin({ top: 28 })

      // Interval picker
      if (!this.session.protectionRunning) {
        Text('INTERVAL')
          .fontSize(12)
          .fontColor('#86868B')
          .margin({ top: 28, left: 24 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(INTERVAL_CHOICES, (item: number) => {
            Button(`${item}`)
              .width(48)
              .height(40)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(item === this.settings.intervalMinutes ? '#E60000' : '#F5F5F7')
              .fontColor(item === this.settings.intervalMinutes ? '#FFFFFF' : '#1D1D1F')
              .borderRadius(4)
              .margin(4)
              .onClick(() => this.onIntervalChange(item))
          })
        }
        .margin({ top: 8, left: 20, right: 20 })

        Text('minutes between breaks')
          .fontSize(12)
          .fontColor('#86868B')
          .margin({ top: 4, left: 24 })
      }

      RedBand()

      // Stats
      Text('Today')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ left: 24 })

      Row() {
        this.statTile('Completed', `${this.stats.completed}`)
        this.statTile('Skipped', `${this.stats.skipped}`)
        this.statTile('Protected', this.protectedLabel)
      }
      .width('100%')
      .margin({ top: 16, left: 24, right: 24 })

      // Reliability
      Text('Reliability')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ top: 28, left: 24 })

      Column() {
        Row() {
          Text(this.perms.ready ? 'All permissions ready' : `${this.perms.readyCount}/${this.perms.totalCount} permissions ready`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1D1D1F')
            .layoutWeight(1)
          Text('Review')
            .fontSize(14)
            .fontColor('#E60000')
        }
        .width('100%')

        Text(this.perms.ready ? 'Retina Guard can behave like a clock alarm.' : 'Finish setup to make reminders more reliable.')
          .fontSize(14)
          .fontColor('#86868B')
          .margin({ top: 4 })
          .width('100%')
      }
      .padding(16)
      .margin({ top: 8, left: 24, right: 24 })
      .borderRadius(8)
      .border({ width: 1, color: '#F5F5F7' })

      // Background status
      if (this.session.protectionRunning) {
        Text('Background')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D1D1F')
          .margin({ top: 28, left: 24 })

        this.bgRow('Exact alarm', this.session.nextDueAtMillis > 0 ? 'scheduled' : 'not scheduled')
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  statTile(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
      Text(label.toUpperCase())
        .fontSize(10)
        .fontColor('#86868B')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  bgRow(name: string, value: string) {
    Row() {
      Text(name)
        .fontSize(14)
        .fontColor('#1D1D1F')
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor('#86868B')
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 8 })
  }
}
