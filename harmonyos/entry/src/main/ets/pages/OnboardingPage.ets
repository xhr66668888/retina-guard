import { PermissionState, PermissionHelper } from '../common/PermissionHelper';
import { common } from '@kit.AbilityKit';
import { ChecklistRow, RedBand } from '../components/ChecklistRow';
import { RedPillButton, GhostButton } from '../components/Buttons';

@Component
export struct OnboardingPage {
  @ObjectLink perms: PermissionStateObserved;
  onRefresh: () => void = () => {};
  onFinish: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // Header
        Text('RETINA GUARD')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D1D1F')
          .margin({ top: 24, left: 24 })

        Text('PROTECT\nYOUR EYES')
          .fontSize(56)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D1D1F')
          .margin({ top: 48, left: 24 })

        Text('Every 20 minutes, take 20 seconds to look into the distance.')
          .fontSize(16)
          .fontColor('#86868B')
          .margin({ top: 20, left: 24, right: 24 })

        RedBand()

        Text('Reliability checklist')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D1D1F')
          .margin({ left: 24 })

        Text('Notifications and exact alarms are required; the rest improve reliability.')
          .fontSize(14)
          .fontColor('#86868B')
          .margin({ top: 8, left: 24, right: 24 })

        ChecklistRow({
          title: 'Notifications',
          description: 'Required to deliver break reminders.',
          granted: this.perms.notifications,
          actionLabel: 'Allow',
          onAction: async () => {
            await PermissionHelper.requestNotifications();
            this.onRefresh();
          }
        })

        ChecklistRow({
          title: 'Reminder agent',
          description: 'Schedule alarms that fire on time.',
          granted: this.perms.reminderAgent,
          actionLabel: 'Allow',
          onAction: async () => {
            const ctx = getContext(this) as common.UIAbilityContext;
            await PermissionHelper.requestReminderAgent(ctx);
            this.onRefresh();
          }
        })

        Scroll() { Column() {} }.layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      // Bottom buttons
      Column() {
        Row() {
          GhostButton({ text: 'Skip for now', onAction: this.onFinish })
            .layoutWeight(1)
            .margin({ right: 6 })
          RedPillButton({
            text: this.perms.ready ? 'Continue' : `${this.perms.readyCount}/${this.perms.totalCount} ready`,
            enabled: this.perms.ready,
            onAction: this.onFinish
          })
            .layoutWeight(1)
            .margin({ left: 6 })
        }
        .width('100%')

        if (!this.perms.ready) {
          Text('Notifications are required to start.')
            .fontSize(12)
            .fontColor('#E60000')
            .margin({ top: 8 })
        }
      }
      .padding(24)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}

@Observed
export class PermissionStateObserved extends PermissionState {
  updateFrom(src: PermissionState): void {
    this.notifications = src.notifications;
    this.reminderAgent = src.reminderAgent;
  }
}
