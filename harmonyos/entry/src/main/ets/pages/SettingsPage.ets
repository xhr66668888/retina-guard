import { AppSettings, ReminderStyle, SoundMode } from '../common/Models';
import { PermissionState, PermissionHelper } from '../common/PermissionHelper';
import { common } from '@kit.AbilityKit';
import { ChecklistRow, RedBand } from '../components/ChecklistRow';

@Component
export struct SettingsPage {
  @Prop settings: AppSettings;
  @Prop perms: PermissionState;
  onReminderStyleChange: (s: string) => void = () => {};
  onSoundModeChange: (s: string) => void = () => {};
  onVibrationChange: (v: boolean) => void = () => {};
  onUsageAwareChange: (v: boolean) => void = () => {};
  onExcludedPackagesChange: (p: string[]) => void = () => {};
  onResetStats: () => void = () => {};
  onRefreshPerms: () => void = () => {};

  build() {
    Column() {
      Text('SETTINGS')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ top: 12, left: 24 })

      // Reliability
      Text('Reliability')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ top: 24, left: 24 })

      ChecklistRow({
        title: 'Notifications',
        description: 'Required to deliver break reminders.',
        granted: this.perms.notifications,
        onAction: async () => {
          await PermissionHelper.requestNotifications();
          this.onRefreshPerms();
        }
      })

      ChecklistRow({
        title: 'Reminder agent',
        description: 'Schedule alarms that fire on time.',
        granted: this.perms.reminderAgent,
        onAction: async () => {
          const ctx = getContext(this) as common.UIAbilityContext;
          await PermissionHelper.requestReminderAgent(ctx);
          this.onRefreshPerms();
        }
      })

      RedBand()

      // Usage-aware mode
      Text('Usage-aware mode')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ left: 24 })

      Row() {
        Column() {
          Text('Screen-time tracking')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1D1D1F')
          Text('Count only actual screen-on time toward breaks.')
            .fontSize(12)
            .fontColor('#86868B')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Toggle({ type: ToggleType.Switch, isOn: this.settings.usageAwareEnabled })
          .onChange((v: boolean) => this.onUsageAwareChange(v))
          .selectedColor('#E60000')
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16 })

      if (this.settings.usageAwareEnabled) {
        Divider().color('#F5F5F7')
        Row() {
          Column() {
            Text('Excluded apps')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1D1D1F')
            Text(this.settings.excludedPackages.length === 0 ? 'No excluded apps' : `${this.settings.excludedPackages.length} excluded app(s)`)
              .fontSize(12)
              .fontColor('#86868B')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text('Manage')
            .fontSize(14)
            .fontColor('#E60000')
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 16 })
      }

      RedBand()

      // Reminder
      Text('Reminder')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ left: 24 })

      // Style segmented
      Column() {
        Text('Style')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1D1D1F')

        Row() {
          this.segBtn('Heads-up', ReminderStyle.HEADS_UP)
          this.segBtn('Alarm', ReminderStyle.ALARM_SCREEN)
          this.segBtn('Overlay', ReminderStyle.OVERLAY)
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16 })

      Divider().color('#F5F5F7').margin({ top: 12 })

      // Sound segmented
      Column() {
        Text('Sound')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1D1D1F')

        Row() {
          this.segSound('Off', SoundMode.OFF)
          this.segSound('Soft', SoundMode.SOFT)
          this.segSound('Alarm', SoundMode.ALARM)
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16 })

      Divider().color('#F5F5F7').margin({ top: 12 })

      // Vibration
      Row() {
        Text('Vibration')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1D1D1F')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.settings.vibrationEnabled })
          .onChange((v: boolean) => this.onVibrationChange(v))
          .selectedColor('#E60000')
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16 })

      RedBand()

      // OEM guidance
      Text('OEM battery guidance')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ left: 24 })

      Text('Some devices kill background apps aggressively. Follow these steps:')
        .fontSize(14)
        .fontColor('#86868B')
        .margin({ top: 8, left: 24, right: 24 })

      Column() {
        this.oemItem('Huawei/Honor', 'Settings > Battery > App launch > Retina Guard > Manage manually. Enable Auto-launch, Secondary launch, Run in background.')
        this.oemItem('Xiaomi/MIUI', 'Settings > Apps > Manage apps > Retina Guard > Autostart. Also set battery saver to No restrictions.')
        this.oemItem('Samsung', 'Settings > Apps > Retina Guard > Battery > Optimize battery usage > exclude. Add to Never sleeping apps.')
        this.oemItem('Oppo/OnePlus/Realme', 'Settings > Apps > Retina Guard > Auto-start. Disable battery optimization.')
        this.oemItem('Vivo', 'Settings > Battery > High background power consumption > enable Retina Guard.')
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 8 })

      RedBand()

      // Privacy
      Text('Privacy')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ left: 24 })

      Row() {
        Column() {
          Text("Reset today's stats")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1D1D1F')
          Text('Delete completed/skipped/protected counters for today.')
            .fontSize(12)
            .fontColor('#86868B')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('Reset')
          .fontSize(14)
          .fontColor('#E60000')
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16 })
      .onClick(this.onResetStats)

      Divider().color('#F5F5F7').margin({ top: 16 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  segBtn(label: string, style: string) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .backgroundColor(this.settings.reminderStyle === style ? '#E60000' : '#F5F5F7')
      .fontColor(this.settings.reminderStyle === style ? '#FFFFFF' : '#1D1D1F')
      .borderRadius(4)
      .margin(2)
      .onClick(() => this.onReminderStyleChange(style))
  }

  @Builder
  segSound(label: string, mode: string) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .backgroundColor(this.settings.soundMode === mode ? '#E60000' : '#F5F5F7')
      .fontColor(this.settings.soundMode === mode ? '#FFFFFF' : '#1D1D1F')
      .borderRadius(4)
      .margin(2)
      .onClick(() => this.onSoundModeChange(mode))
  }

  @Builder
  oemItem(title: string, body: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1D1D1F')
      Text(body)
        .fontSize(12)
        .fontColor('#86868B')
        .margin({ top: 4 })
    }
    .width('100%')
    .margin({ top: 12 })
  }
}
