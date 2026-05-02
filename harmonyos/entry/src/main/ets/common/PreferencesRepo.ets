import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AppSettings, ReminderStyle, SoundMode, SessionState, TodayStats } from './Models';

const STORE_NAME = 'retina_guard';
const KEY_INTERVAL = 'interval_minutes';
const KEY_BREAK_SEC = 'break_seconds';
const KEY_SNOOZE = 'snooze_minutes';
const KEY_STYLE = 'reminder_style';
const KEY_SOUND = 'sound_mode';
const KEY_VIBRATE = 'vibration_enabled';
const KEY_ONBOARDING = 'onboarding_done';
const KEY_DAILY = 'daily_schedule_enabled';
const KEY_QUIET = 'quiet_hours_enabled';
const KEY_DAYS = 'active_days_mask';
const KEY_USAGE_AWARE = 'usage_aware_enabled';
const KEY_EXCLUDED = 'excluded_packages';
const KEY_RUNNING = 'protection_running';
const KEY_NEXT_DUE = 'next_due_at';
const KEY_STARTED_AT = 'protection_started_at';
const KEY_MISSED = 'consecutive_missed';
const KEY_REMINDER_OUT = 'reminder_outstanding';
const KEY_ACCUM_MS = 'accumulated_screen_ms';
const KEY_STATS_DATE = 'stats_date';
const KEY_STATS_DONE = 'stats_completed';
const KEY_STATS_SKIP = 'stats_skipped';
const KEY_STATS_MISS = 'stats_missed';
const KEY_STATS_SEC = 'stats_protected_sec';

export class PreferencesRepo {
  private store: preferences.Preferences | null = null;

  async init(context: common.UIAbilityContext): Promise<void> {
    this.store = await preferences.getPreferences(context, STORE_NAME);
  }

  private async get(key: string, def: preferences.ValueType): Promise<preferences.ValueType> {
    if (!this.store) return def;
    try {
      return await this.store.get(key, def);
    } catch {
      return def;
    }
  }

  private async put(key: string, val: preferences.ValueType): Promise<void> {
    if (!this.store) return;
    await this.store.put(key, val);
    await this.store.flush();
  }

  async getSettings(): Promise<AppSettings> {
    const s = new AppSettings();
    s.intervalMinutes = (await this.get(KEY_INTERVAL, 20)) as number;
    s.breakSeconds = (await this.get(KEY_BREAK_SEC, 20)) as number;
    s.snoozeMinutes = (await this.get(KEY_SNOOZE, 5)) as number;
    s.reminderStyle = (await this.get(KEY_STYLE, ReminderStyle.ALARM_SCREEN)) as ReminderStyle;
    s.soundMode = (await this.get(KEY_SOUND, SoundMode.SOFT)) as SoundMode;
    s.vibrationEnabled = (await this.get(KEY_VIBRATE, 1)) === 1;
    s.onboardingDone = (await this.get(KEY_ONBOARDING, 0)) === 1;
    s.dailyScheduleEnabled = (await this.get(KEY_DAILY, 0)) === 1;
    s.quietHoursEnabled = (await this.get(KEY_QUIET, 0)) === 1;
    s.activeDaysMask = (await this.get(KEY_DAYS, 0b0111110)) as number;
    s.usageAwareEnabled = (await this.get(KEY_USAGE_AWARE, 1)) === 1;
    const excl = (await this.get(KEY_EXCLUDED, '')) as string;
    s.excludedPackages = excl ? excl.split(',').filter((e: string) => e.length > 0) : [];
    return s;
  }

  async getSession(): Promise<SessionState> {
    const s = new SessionState();
    s.protectionRunning = (await this.get(KEY_RUNNING, 0)) === 1;
    s.nextDueAtMillis = (await this.get(KEY_NEXT_DUE, 0)) as number;
    s.protectionStartedAtMillis = (await this.get(KEY_STARTED_AT, 0)) as number;
    s.consecutiveMissed = (await this.get(KEY_MISSED, 0)) as number;
    s.reminderOutstanding = (await this.get(KEY_REMINDER_OUT, 0)) === 1;
    return s;
  }

  async getStats(): Promise<TodayStats> {
    const today = this.todayKey();
    const stored = (await this.get(KEY_STATS_DATE, '')) as string;
    if (stored !== today) return { date: today, completed: 0, skipped: 0, missed: 0, protectedSeconds: 0 };
    return {
      date: today,
      completed: (await this.get(KEY_STATS_DONE, 0)) as number,
      skipped: (await this.get(KEY_STATS_SKIP, 0)) as number,
      missed: (await this.get(KEY_STATS_MISS, 0)) as number,
      protectedSeconds: (await this.get(KEY_STATS_SEC, 0)) as number
    };
  }

  async setInterval(v: number): Promise<void> { await this.put(KEY_INTERVAL, v); }
  async setBreakSeconds(v: number): Promise<void> { await this.put(KEY_BREAK_SEC, v); }
  async setSnoozeMinutes(v: number): Promise<void> { await this.put(KEY_SNOOZE, v); }
  async setReminderStyle(v: ReminderStyle): Promise<void> { await this.put(KEY_STYLE, v); }
  async setSoundMode(v: SoundMode): Promise<void> { await this.put(KEY_SOUND, v); }
  async setVibration(v: boolean): Promise<void> { await this.put(KEY_VIBRATE, v ? 1 : 0); }
  async setOnboardingDone(v: boolean): Promise<void> { await this.put(KEY_ONBOARDING, v ? 1 : 0); }
  async setDailyScheduleEnabled(v: boolean): Promise<void> { await this.put(KEY_DAILY, v ? 1 : 0); }
  async setQuietHoursEnabled(v: boolean): Promise<void> { await this.put(KEY_QUIET, v ? 1 : 0); }
  async setActiveDaysMask(v: number): Promise<void> { await this.put(KEY_DAYS, v); }
  async setUsageAwareEnabled(v: boolean): Promise<void> { await this.put(KEY_USAGE_AWARE, v ? 1 : 0); }
  async setExcludedPackages(v: string[]): Promise<void> { await this.put(KEY_EXCLUDED, v.join(',')); }

  async startProtection(nextDueAt: number, now: number): Promise<void> {
    await this.put(KEY_RUNNING, 1);
    await this.put(KEY_STARTED_AT, now);
    await this.put(KEY_NEXT_DUE, nextDueAt);
    await this.put(KEY_MISSED, 0);
    await this.put(KEY_REMINDER_OUT, 0);
    await this.put(KEY_ACCUM_MS, 0);
  }

  async stopProtection(now: number): Promise<void> {
    const started = (await this.get(KEY_STARTED_AT, 0)) as number;
    const delta = started > 0 ? Math.max(0, Math.floor((now - started) / 1000)) : 0;
    await this.put(KEY_RUNNING, 0);
    await this.put(KEY_NEXT_DUE, 0);
    await this.put(KEY_STARTED_AT, 0);
    await this.put(KEY_REMINDER_OUT, 0);
    await this.put(KEY_ACCUM_MS, 0);
    if (delta > 0) await this.bumpProtectedSeconds(delta);
  }

  async setNextDueAt(t: number): Promise<void> { await this.put(KEY_NEXT_DUE, t); }
  async markReminderShown(): Promise<void> { await this.put(KEY_REMINDER_OUT, 1); }
  async clearReminderOutstanding(): Promise<void> { await this.put(KEY_REMINDER_OUT, 0); }
  async getAccumulatedScreenMs(): Promise<number> { return (await this.get(KEY_ACCUM_MS, 0)) as number; }
  async setAccumulatedScreenMs(v: number): Promise<void> { await this.put(KEY_ACCUM_MS, v); }
  async resetAccumulatedScreenMs(): Promise<void> { await this.put(KEY_ACCUM_MS, 0); }
  async resetMissedStreak(): Promise<void> { await this.put(KEY_MISSED, 0); }

  async recordCompleted(): Promise<void> {
    const st = await this.getStats();
    await this.ensureStatsToday();
    await this.put(KEY_STATS_DONE, st.completed + 1);
    await this.put(KEY_MISSED, 0);
    await this.put(KEY_REMINDER_OUT, 0);
  }

  async recordSkipped(): Promise<void> {
    const st = await this.getStats();
    await this.ensureStatsToday();
    await this.put(KEY_STATS_SKIP, st.skipped + 1);
    await this.put(KEY_REMINDER_OUT, 0);
  }

  async recordMissed(): Promise<void> {
    const st = await this.getStats();
    const s = await this.getSession();
    await this.ensureStatsToday();
    await this.put(KEY_STATS_MISS, st.missed + 1);
    await this.put(KEY_MISSED, s.consecutiveMissed + 1);
    await this.put(KEY_REMINDER_OUT, 0);
  }

  async resetTodayStats(): Promise<void> {
    await this.put(KEY_STATS_DATE, this.todayKey());
    await this.put(KEY_STATS_DONE, 0);
    await this.put(KEY_STATS_SKIP, 0);
    await this.put(KEY_STATS_MISS, 0);
    await this.put(KEY_STATS_SEC, 0);
  }

  private async bumpProtectedSeconds(sec: number): Promise<void> {
    const st = await this.getStats();
    await this.ensureStatsToday();
    await this.put(KEY_STATS_SEC, st.protectedSeconds + sec);
  }

  private async ensureStatsToday(): Promise<void> {
    const today = this.todayKey();
    const stored = (await this.get(KEY_STATS_DATE, '')) as string;
    if (stored !== today) {
      await this.put(KEY_STATS_DATE, today);
      await this.put(KEY_STATS_DONE, 0);
      await this.put(KEY_STATS_SKIP, 0);
      await this.put(KEY_STATS_MISS, 0);
      await this.put(KEY_STATS_SEC, 0);
    }
  }

  private todayKey(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }
}

export const repo = new PreferencesRepo();
