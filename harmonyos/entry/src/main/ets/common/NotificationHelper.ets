import { notificationManager } from '@kit.NotificationKit';
import { ReminderStyle, SoundMode, AppSettings } from './Models';
import { wantAgent, Want } from '@kit.AbilityKit';

const CHANNEL_ONGOING = 'protection_ongoing';
const CHANNEL_BREAK = 'eye_break_alarm';
const NOTIF_ONGOING = 1001;
const NOTIF_BREAK = 1002;

export class NotificationHelper {
  static async ensureChannels(): Promise<void> {
    try {
      await notificationManager.createNotificationChannel({
        id: CHANNEL_ONGOING,
        name: 'Protection running',
        importance: notificationManager.ImportanceLevel.LEVEL_LOW,
        description: 'Live countdown to your next eye break.',
        enableBadge: false
      });
      await notificationManager.createNotificationChannel({
        id: CHANNEL_BREAK,
        name: 'Eye break reminder',
        importance: notificationManager.ImportanceLevel.LEVEL_HIGH,
        description: 'Reminds you to look 20 feet away for 20 seconds.',
        enableBadge: true
      });
    } catch (e) {
      console.error('NotificationHelper: channel creation failed ' + JSON.stringify(e));
    }
  }

  static async postOngoing(remainingSec: number, paused: boolean): Promise<void> {
    const mins = Math.floor(Math.max(0, remainingSec) / 60);
    const secs = Math.max(0, remainingSec) % 60;
    const title = paused ? 'Protection paused' : `Next break in ${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    const want: Want = { bundleName: 'com.retinaguard.app', abilityName: 'EntryAbility' };
    const agentInfo: wantAgent.WantAgentInfo = { wants: [want], actionType: wantAgent.OperationType.START_ABILITY, requestCode: 10 };
    const agent = await wantAgent.getWantAgent(agentInfo);
    try {
      await notificationManager.publish({
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: { title: title, text: paused ? 'Tap to resume' : 'Retina Guard is running' }
        },
        id: NOTIF_ONGOING,
        notificationSlotType: notificationManager.SlotType.SERVICE_COMMUNICATION,
        label: 'ongoing',
        deliveryTime: 0,
        wantAgent: agent
      });
    } catch (e) { /* ignore */ }
  }

  static async postBreakReminder(settings: AppSettings): Promise<void> {
    const want: Want = { bundleName: 'com.retinaguard.app', abilityName: 'EntryAbility' };
    const agentInfo: wantAgent.WantAgentInfo = { wants: [want], actionType: wantAgent.OperationType.START_ABILITY, requestCode: 20 };
    const agent = await wantAgent.getWantAgent(agentInfo);
    try {
      await notificationManager.publish({
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: { title: 'Time to look away', text: 'Focus on something far away for 20 seconds.' }
        },
        id: NOTIF_BREAK,
        notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        label: 'break',
        deliveryTime: 0,
        wantAgent: agent
      });
    } catch (e) { /* ignore */ }
  }

  static async cancelBreak(): Promise<void> {
    try { await notificationManager.cancel(NOTIF_BREAK); } catch (e) { /* ignore */ }
  }

  static async cancelOngoing(): Promise<void> {
    try { await notificationManager.cancel(NOTIF_ONGOING); } catch (e) { /* ignore */ }
  }
}
