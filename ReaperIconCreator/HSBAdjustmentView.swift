import SwiftUI

struct HSBAdjustmentView: View {
    let title: String
    @Binding var adjustment: HSBAdjustment
    let defaultAdjustment: HSBAdjustment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .frame(width: 80, alignment: .leading)

                Spacer()

                Button("Reset") {
                    adjustment = defaultAdjustment
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.accentColor)
            }

            HStack(spacing: 16) {
                SliderRow(label: "Hue", value: $adjustment.hue, range: -1...1)
                SliderRow(label: "Sat", value: $adjustment.saturation, range: -1...1)
                SliderRow(label: "Bri", value: $adjustment.brightness, range: -1...1)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .leading)

            Slider(value: $value, in: range)
                .frame(minWidth: 80)

            Text(String(format: "%+.0f%%", value * 100))
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

struct HSBAdjustmentView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HSBAdjustmentView(
                title: "Normal",
                adjustment: .constant(HSBAdjustment.normal),
                defaultAdjustment: HSBAdjustment.normal
            )
            HSBAdjustmentView(
                title: "Hover",
                adjustment: .constant(HSBAdjustment.hover),
                defaultAdjustment: HSBAdjustment.hover
            )
            HSBAdjustmentView(
                title: "Active",
                adjustment: .constant(HSBAdjustment.active),
                defaultAdjustment: HSBAdjustment.active
            )
        }
        .padding()
        .frame(width: 500)
    }
}
