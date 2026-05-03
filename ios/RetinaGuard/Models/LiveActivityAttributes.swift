@preconcurrency import ActivityKit
import Foundation

struct RetinaGuardActivityAttributes: ActivityAttributes {
    enum Phase: String, Codable, Hashable {
        case countdown
        case breakDue
        case paused
    }

    public struct ContentState: Codable, Hashable {
        var nextDueAt: Date
        var intervalMinutes: Int
        var breakSeconds: Int
        var phase: Phase
    }

    var title: String
}
