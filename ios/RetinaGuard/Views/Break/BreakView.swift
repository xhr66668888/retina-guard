import SwiftUI

struct BreakView: View {
    @EnvironmentObject var store: PreferencesStore
    @Environment(\.dismiss) private var dismiss

    @State private var remaining: Int = 20
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color("Charcoal").ignoresSafeArea()

            VStack {
                Spacer()

                Text("\(remaining)")
                    .font(.system(size: 120, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)

                Text("Look at something far away")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                HStack(spacing: 12) {
                    GhostRectangleButton(text: "Skip") { onSkip() }
                    RedPillButton(text: "Done", enabled: true) { onDone() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            remaining = store.settings.breakSeconds
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                remaining -= 1
                if remaining <= 0 { onDone() }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func onDone() {
        timer?.invalidate()
        store.recordCompleted()
        store.resetAccumulatedMs()
        NotificationManager.shared.cancelBreak()
        dismiss()
    }

    private func onSkip() {
        timer?.invalidate()
        store.recordSkipped()
        store.resetAccumulatedMs()
        NotificationManager.shared.cancelBreak()
        dismiss()
    }
}
