import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';

export class PermissionState {
  notifications: boolean = false;
  reminderAgent: boolean = false;

  static async read(context: common.UIAbilityContext): Promise<PermissionState> {
    const ps = new PermissionState();
    try {
      ps.notifications = await notificationManager.isNotificationEnabled();
    } catch { ps.notifications = false; }
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.checkAccessToken(context.tokenID, 'ohos.permission.PUBLISH_AGENT_REMINDER');
      ps.reminderAgent = result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch { ps.reminderAgent = false; }
    return ps;
  }

  get ready(): boolean {
    return this.notifications;
  }

  get readyCount(): number {
    return (this.notifications ? 1 : 0) + (this.reminderAgent ? 1 : 0);
  }

  get totalCount(): number {
    return 2;
  }
}

export class PermissionHelper {
  static async requestNotifications(): Promise<boolean> {
    try {
      await notificationManager.requestEnableNotification();
      return await notificationManager.isNotificationEnabled();
    } catch { return false; }
  }

  static async requestReminderAgent(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      await atManager.requestPermissionsFromUser(context, ['ohos.permission.PUBLISH_AGENT_REMINDER']);
      const result = await atManager.checkAccessToken(context.tokenID, 'ohos.permission.PUBLISH_AGENT_REMINDER');
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch { return false; }
  }
}
