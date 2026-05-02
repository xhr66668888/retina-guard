import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { wantAgent, Want } from '@kit.AbilityKit';

export class AlarmScheduler {
  static async schedule(triggerAtMillis: number, reminderId: number): Promise<void> {
    const want: Want = {
      bundleName: 'com.retinaguard.app',
      abilityName: 'EntryAbility'
    };
    const agentInfo: wantAgent.WantAgentInfo = {
      wants: [want],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: reminderId
    };
    const agent = await wantAgent.getWantAgent(agentInfo);
    const triggerTime = new Date(triggerAtMillis);
    const request: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.ALARM,
      hour: triggerTime.getHours(),
      minute: triggerTime.getMinutes(),
      second: triggerTime.getSeconds(),
      wantAgent: agent,
      title: 'Time to look away',
      content: 'Focus on something 20 feet away for 20 seconds.',
      notificationId: reminderId,
      slotType: reminderAgentManager.SlotType.SOCIAL_COMMUNICATION
    };
    try {
      await reminderAgentManager.publishReminder(request);
    } catch (e) {
      console.error('AlarmScheduler: publish failed ' + JSON.stringify(e));
    }
  }

  static async cancel(reminderId: number): Promise<void> {
    try {
      await reminderAgentManager.cancelReminder(reminderId);
    } catch (e) {
      // ignore
    }
  }

  static async cancelAll(): Promise<void> {
    try {
      const reminders = await reminderAgentManager.getValidReminders();
      for (const r of reminders) {
        await reminderAgentManager.cancelReminder(r.id);
      }
    } catch (e) {
      // ignore
    }
  }
}
