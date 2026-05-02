import SwiftUI

// MARK: - RedPillButton (port of Android RedPillButton)

struct RedPillButton: View {
    let text: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(enabled ? Color.red : Color(.systemGray5))
                .foregroundColor(enabled ? .white : .gray)
                .cornerRadius(24)
        }
        .disabled(!enabled)
    }
}

// MARK: - GhostRectangleButton (port of Android GhostRectangleButton)

struct GhostRectangleButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(.systemGray6))
                .foregroundColor(Color("Charcoal"))
                .cornerRadius(24)
        }
    }
}
