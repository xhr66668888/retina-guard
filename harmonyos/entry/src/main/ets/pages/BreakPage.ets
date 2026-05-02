import { router } from '@kit.ArkUI';
import { repo } from '../common/PreferencesRepo';
import { NotificationHelper } from '../common/NotificationHelper';
import { AlarmScheduler } from '../common/AlarmScheduler';
import { GhostButton, RedPillButton } from '../components/Buttons';

@Entry
@Component
struct BreakPage {
  @State remainingSec: number = 20;
  @State totalSec: number = 20;
  @State snoozeMinutes: number = 5;
  private timer: number = -1;

  async aboutToAppear(): Promise<void> {
    const s = await repo.getSettings();
    this.totalSec = s.breakSeconds;
    this.remainingSec = s.breakSeconds;
    this.snoozeMinutes = s.snoozeMinutes;
    this.timer = setInterval(() => {
      this.remainingSec--;
      if (this.remainingSec <= 0) {
        this.onComplete();
      }
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timer >= 0) clearInterval(this.timer);
  }

  private async onComplete(): Promise<void> {
    if (this.timer >= 0) { clearInterval(this.timer); this.timer = -1; }
    await repo.recordCompleted();
    await repo.resetAccumulatedScreenMs();
    await NotificationHelper.cancelBreak();
    const s = await repo.getSettings();
    const due = Date.now() + s.intervalMinutes * 60_000;
    await repo.setNextDueAt(due);
    await AlarmScheduler.schedule(due, 1001);
    router.back();
  }

  private async onSkip(): Promise<void> {
    if (this.timer >= 0) { clearInterval(this.timer); this.timer = -1; }
    await repo.recordSkipped();
    await repo.resetAccumulatedScreenMs();
    await NotificationHelper.cancelBreak();
    const s = await repo.getSettings();
    const due = Date.now() + s.intervalMinutes * 60_000;
    await repo.setNextDueAt(due);
    await AlarmScheduler.schedule(due, 1001);
    router.back();
  }

  private async onSnooze(): Promise<void> {
    if (this.timer >= 0) { clearInterval(this.timer); this.timer = -1; }
    await repo.clearReminderOutstanding();
    await repo.resetAccumulatedScreenMs();
    const s = await repo.getSettings();
    const due = Date.now() + s.snoozeMinutes * 60_000;
    await repo.setNextDueAt(due);
    await AlarmScheduler.schedule(due, 1001);
    await NotificationHelper.cancelBreak();
    router.back();
  }

  build() {
    Column() {
      Blank()

      Text(String(this.remainingSec))
        .fontSize(120)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width('100%')

      Text('Look at something far away')
        .fontSize(20)
        .fontColor('#FFFFFFCC')
        .margin({ top: 16 })

      Blank()

      Column() {
        RedPillButton({ text: 'Done', enabled: true, onAction: () => this.onComplete() })
          .width('100%')

        Row() {
          GhostButton({ text: `Snooze ${this.snoozeMinutes}m`, onAction: () => this.onSnooze() })
            .layoutWeight(1)
            .margin({ right: 6 })
          GhostButton({ text: 'Skip', onAction: () => this.onSkip() })
            .layoutWeight(1)
            .margin({ left: 6 })
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 48 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1D1D1F')
  }
}
