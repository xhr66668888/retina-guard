import SwiftUI

// MARK: - ChecklistRow (port of Android ChecklistRow)

struct ChecklistRow: View {
    let title: String
    let description: String
    let granted: Bool
    let actionLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Status circle
                ZStack {
                    Circle()
                        .fill(granted ? Color.red : Color(.systemGray5))
                        .frame(width: 24, height: 24)
                    if granted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("·")
                            .font(.caption)
                            .foregroundColor(Color("Charcoal"))
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundColor(Color("Charcoal"))
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(granted ? "Granted" : actionLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(granted ? .secondary : .red)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }

        Divider()
    }
}

// MARK: - RedBand (port of Android RedBand)

struct RedBand: View {
    var body: some View {
        Color.red
            .frame(height: 4)
            .padding(.vertical, 24)
    }
}
