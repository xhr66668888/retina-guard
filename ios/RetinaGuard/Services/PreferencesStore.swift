import Foundation
import Combine

/// UserDefaults-backed repository — port of Android PreferencesRepository.
/// Every setter writes immediately and publishes via @Published.
@MainActor
final class PreferencesStore: ObservableObject {

    static let shared = PreferencesStore()

    private let ud = UserDefaults.standard

    // MARK: - Keys
    private enum K {
        static let settings    = "rg_settings"
        static let session     = "rg_session"
        static let statsDate   = "rg_stats_date"
        static let statsDone   = "rg_stats_done"
        static let statsSkip   = "rg_stats_skip"
        static let statsMiss   = "rg_stats_miss"
        static let statsSec    = "rg_stats_sec"
        static let accumMs     = "rg_accum_ms"
    }

    // MARK: - Published state
    @Published var settings = AppSettings()
    @Published var session  = SessionState()
    @Published var stats    = TodayStats()

    // MARK: - Init
    private init() { loadAll() }

    private func loadAll() {
        if let data = ud.data(forKey: K.settings),
           let s = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = s
        }
        if let data = ud.data(forKey: K.session),
           let s = try? JSONDecoder().decode(SessionState.self, from: data) {
            session = s
        }
        loadStats()
    }

    private func loadStats() {
        let today = Self.todayKey()
        let stored = ud.string(forKey: K.statsDate) ?? ""
        if stored != today {
            stats = TodayStats(date: today, completed: 0, skipped: 0, missed: 0, protectedSeconds: 0)
            saveStats()
        } else {
            stats = TodayStats(
                date: today,
                completed: ud.integer(forKey: K.statsDone),
                skipped: ud.integer(forKey: K.statsSkip),
                missed:  ud.integer(forKey: K.statsMiss),
                protectedSeconds: ud.integer(forKey: K.statsSec)
            )
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) { ud.set(data, forKey: K.settings) }
    }
    private func saveSession() {
        if let data = try? JSONEncoder().encode(session) { ud.set(data, forKey: K.session) }
    }
    private func saveStats() {
        ud.set(stats.date, forKey: K.statsDate)
        ud.set(stats.completed, forKey: K.statsDone)
        ud.set(stats.skipped, forKey: K.statsSkip)
        ud.set(stats.missed, forKey: K.statsMiss)
        ud.set(stats.protectedSeconds, forKey: K.statsSec)
    }

    // MARK: - Settings setters
    func setInterval(_ v: Int)           { settings.intervalMinutes = v; saveSettings() }
    func setBreakSeconds(_ v: Int)       { settings.breakSeconds = v; saveSettings() }
    func setSnoozeMinutes(_ v: Int)      { settings.snoozeMinutes = v; saveSettings() }
    func setReminderStyle(_ v: ReminderStyle) { settings.reminderStyle = v; saveSettings() }
    func setSoundMode(_ v: SoundMode)    { settings.soundMode = v; saveSettings() }
    func setVibration(_ v: Bool)         { settings.vibrationEnabled = v; saveSettings() }
    func setOnboardingDone(_ v: Bool)    { settings.onboardingDone = v; saveSettings() }
    func setDailySchedule(_ v: Bool)     { settings.dailyScheduleEnabled = v; saveSettings() }
    func setQuietHours(_ v: Bool)        { settings.quietHoursEnabled = v; saveSettings() }
    func setActiveDaysMask(_ v: Int)     { settings.activeDaysMask = v; saveSettings() }
    func setUsageAware(_ v: Bool)        { settings.usageAwareEnabled = v; saveSettings() }
    func setExcludedBundleIDs(_ v: [String]) { settings.excludedBundleIDs = v; saveSettings() }

    // MARK: - Session
    func startProtection(nextDueAt: Date, now: Date) {
        session = SessionState(
            protectionRunning: true,
            nextDueAt: nextDueAt,
            protectionStartedAt: now,
            consecutiveMissed: 0,
            reminderOutstanding: false
        )
        ud.set(0, forKey: K.accumMs)
        saveSession()
    }

    func stopProtection(now: Date) {
        let started = session.protectionStartedAt
        let delta = max(0, Int(now.timeIntervalSince(started)))
        session.protectionRunning = false
        session.nextDueAt = .distantPast
        session.protectionStartedAt = .distantPast
        session.reminderOutstanding = false
        ud.set(0, forKey: K.accumMs)
        if delta > 0 { bumpProtectedSeconds(delta) }
        saveSession()
    }

    func setNextDueAt(_ t: Date) { session.nextDueAt = t; saveSession() }
    func markReminderShown()     { session.reminderOutstanding = true; saveSession() }
    func clearReminderOutstanding() { session.reminderOutstanding = false; saveSession() }
    func resetMissedStreak()     { session.consecutiveMissed = 0; saveSession() }

    // MARK: - Accumulated screen ms (usage-aware)
    func getAccumulatedMs() -> Int { ud.integer(forKey: K.accumMs) }
    func setAccumulatedMs(_ v: Int) { ud.set(v, forKey: K.accumMs) }
    func resetAccumulatedMs()      { ud.set(0, forKey: K.accumMs) }

    // MARK: - Stats
    func recordCompleted() {
        ensureStatsToday()
        stats.completed += 1
        session.consecutiveMissed = 0
        session.reminderOutstanding = false
        saveStats(); saveSession()
    }

    func recordSkipped() {
        ensureStatsToday()
        stats.skipped += 1
        session.reminderOutstanding = false
        saveStats(); saveSession()
    }

    func recordMissed() {
        ensureStatsToday()
        stats.missed += 1
        session.consecutiveMissed += 1
        session.reminderOutstanding = false
        saveStats(); saveSession()
    }

    func resetTodayStats() {
        stats = TodayStats(date: Self.todayKey(), completed: 0, skipped: 0, missed: 0, protectedSeconds: 0)
        saveStats()
    }

    private func bumpProtectedSeconds(_ sec: Int) {
        ensureStatsToday()
        stats.protectedSeconds += sec
        saveStats()
    }

    private func ensureStatsToday() {
        let today = Self.todayKey()
        if stats.date != today {
            stats = TodayStats(date: today, completed: 0, skipped: 0, missed: 0, protectedSeconds: 0)
        }
    }

    private static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
