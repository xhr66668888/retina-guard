export enum ReminderStyle {
  HEADS_UP = 'HEADS_UP',
  ALARM_SCREEN = 'ALARM_SCREEN',
  OVERLAY = 'OVERLAY'
}

export enum SoundMode {
  OFF = 'OFF',
  SOFT = 'SOFT',
  ALARM = 'ALARM'
}

export class AppSettings {
  intervalMinutes: number = 20;
  breakSeconds: number = 20;
  snoozeMinutes: number = 5;
  reminderStyle: ReminderStyle = ReminderStyle.ALARM_SCREEN;
  soundMode: SoundMode = SoundMode.SOFT;
  vibrationEnabled: boolean = true;
  onboardingDone: boolean = false;
  dailyScheduleEnabled: boolean = false;
  quietHoursEnabled: boolean = false;
  activeDaysMask: number = 0b0111110;
  usageAwareEnabled: boolean = true;
  excludedPackages: string[] = [];
}

export class SessionState {
  protectionRunning: boolean = false;
  nextDueAtMillis: number = 0;
  protectionStartedAtMillis: number = 0;
  consecutiveMissed: number = 0;
  reminderOutstanding: boolean = false;
}

export class TodayStats {
  date: string = '';
  completed: number = 0;
  skipped: number = 0;
  missed: number = 0;
  protectedSeconds: number = 0;
}

export const INTERVAL_CHOICES: number[] = [5, 10, 15, 20, 30, 45, 60];
