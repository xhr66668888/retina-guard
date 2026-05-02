import Foundation

// MARK: - Enums (port of Android ReminderStyle, SoundMode)

enum ReminderStyle: String, CaseIterable, Codable {
    case headsUp     = "HEADS_UP"
    case alarmScreen = "ALARM_SCREEN"
    case overlay     = "OVERLAY"

    var label: String {
        switch self {
        case .headsUp:     return "Banner"
        case .alarmScreen: return "Full screen"
        case .overlay:     return "Persistent"
        }
    }
}

enum SoundMode: String, CaseIterable, Codable {
    case off   = "OFF"
    case soft  = "SOFT"
    case alarm = "ALARM"

    var label: String {
        switch self {
        case .off:   return "Off"
        case .soft:  return "Soft"
        case .alarm: return "Alarm"
        }
    }
}

// MARK: - AppSettings (port of Android AppSettings)

struct AppSettings: Codable {
    var intervalMinutes: Int     = 20
    var breakSeconds: Int        = 20
    var snoozeMinutes: Int       = 5
    var reminderStyle: ReminderStyle = .alarmScreen
    var soundMode: SoundMode     = .soft
    var vibrationEnabled: Bool   = true
    var onboardingDone: Bool     = false
    var dailyScheduleEnabled: Bool = false
    var quietHoursEnabled: Bool  = false
    var activeDaysMask: Int      = 0b0111110  // Mon-Fri
    var usageAwareEnabled: Bool  = true
    var excludedBundleIDs: [String] = []
}

// MARK: - SessionState (port of Android SessionState)

struct SessionState: Codable {
    var protectionRunning: Bool        = false
    var nextDueAt: Date                = .distantPast
    var protectionStartedAt: Date      = .distantPast
    var consecutiveMissed: Int         = 0
    var reminderOutstanding: Bool      = false
}

// MARK: - TodayStats (port of Android TodayStats)

struct TodayStats: Codable {
    var date: String           = ""
    var completed: Int         = 0
    var skipped: Int           = 0
    var missed: Int            = 0
    var protectedSeconds: Int  = 0
}

// MARK: - Constants

let intervalChoices: [Int] = [5, 10, 15, 20, 30, 45, 60]
