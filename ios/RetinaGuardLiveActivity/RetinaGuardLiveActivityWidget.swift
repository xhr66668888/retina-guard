@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

@main
struct RetinaGuardLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        RetinaGuardLiveActivityWidget()
    }
}

struct RetinaGuardLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RetinaGuardActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(.red)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Retina Guard", systemImage: "eye")
                        .font(.caption.weight(.semibold))
                }

                DynamicIslandExpandedRegion(.trailing) {
                    CountdownText(context: context)
                        .font(.title3.monospacedDigit().weight(.bold))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(message(for: context))
                        .font(.caption)
                        .lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: "eye")
                    .foregroundStyle(.red)
            } compactTrailing: {
                CountdownText(context: context)
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .frame(width: 42, alignment: .trailing)
            } minimal: {
                Image(systemName: "eye")
                    .foregroundStyle(.red)
            }
            .keylineTint(.red)
        }
    }

    private func message(for context: ActivityViewContext<RetinaGuardActivityAttributes>) -> String {
        switch context.state.phase {
        case .breakDue:
            return "Look 20 feet away for \(context.state.breakSeconds) seconds"
        case .paused:
            return "Protection paused"
        case .countdown:
            return "Next eye break is counting down"
        }
    }
}

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<RetinaGuardActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "eye")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.red)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            CountdownText(context: context)
                .font(.title2.monospacedDigit().weight(.heavy))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var subtitle: String {
        switch context.state.phase {
        case .breakDue:
            return "Time to look away"
        case .paused:
            return "Paused"
        case .countdown:
            return "Next break"
        }
    }
}

private struct CountdownText: View {
    let context: ActivityViewContext<RetinaGuardActivityAttributes>

    var body: some View {
        if context.state.phase == .breakDue || context.state.nextDueAt <= Date() {
            Text("Now")
        } else if context.state.phase == .paused {
            Text("--:--")
        } else {
            Text(timerInterval: Date()...context.state.nextDueAt, countsDown: true)
                .multilineTextAlignment(.trailing)
        }
    }
}
