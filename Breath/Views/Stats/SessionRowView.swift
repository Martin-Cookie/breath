import SwiftUI

struct SessionRowView: View {
    let session: Session

    private var dateString: String {
        session.date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Constants.Palette.primaryTeal)
                Text("\(session.totalRounds) kol • avg \(TimeFormatter.mmss(session.averageRetention))")
                    .font(.caption)
                    .foregroundStyle(Constants.Palette.textSecondary)
            }
            Spacer()
            Text(TimeFormatter.mmss(session.bestRetention))
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(Constants.Palette.primaryTeal)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
