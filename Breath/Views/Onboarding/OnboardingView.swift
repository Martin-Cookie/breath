import SwiftUI

struct OnboardingView: View {
    @AppStorage(SettingsKey.hasSeenOnboarding) private var hasSeenOnboarding: Bool = false
    @State private var page: Int = 0

    private let lastPage = 2

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Constants.Palette.primaryTeal.opacity(0.1), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    if page != lastPage {
                        Button(action: skip) {
                            Text(String(localized: "onboarding.skip"))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .frame(height: 24)

                TabView(selection: $page) {
                    OnboardingPage(
                        icon: "wind",
                        color: Constants.Palette.tealLight,
                        title: String(localized: "onboarding.welcome.title"),
                        subtitle: String(localized: "onboarding.welcome.subtitle"),
                        text: String(localized: "onboarding.welcome.body"),
                        animationKind: .breath
                    )
                    .tag(0)

                    OnboardingPage(
                        icon: "exclamationmark.triangle.fill",
                        color: Constants.Palette.accentOrange,
                        title: String(localized: "onboarding.safety.title"),
                        subtitle: String(localized: "onboarding.safety.subtitle"),
                        text: String(localized: "onboarding.safety.body"),
                        animationKind: .shake
                    )
                    .tag(1)

                    OnboardingPage(
                        icon: "bell.fill",
                        color: Constants.Palette.accentGreen,
                        title: String(localized: "onboarding.notifications.title"),
                        subtitle: String(localized: "onboarding.notifications.subtitle"),
                        text: String(localized: "onboarding.notifications.body"),
                        animationKind: .ring
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0...lastPage, id: \.self) { i in
                        Circle()
                            .fill(i == page
                                  ? Constants.Palette.primaryTeal
                                  : Constants.Palette.primaryTeal.opacity(0.25))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 12)

                Button(action: next) {
                    Text(page == lastPage
                         ? String(localized: "onboarding.start")
                         : String(localized: "onboarding.next"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Constants.Palette.primaryTeal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Constants.Palette.primaryTeal.opacity(0.25), radius: 12, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    private func skip() {
        hasSeenOnboarding = true
    }

    private func next() {
        if page < lastPage {
            withAnimation { page += 1 }
        } else {
            if page == lastPage {
                Task {
                    let granted = await NotificationService.requestAuthorization()
                    if granted {
                        NotificationService.scheduleDailyReminder(hour: 8, minute: 0)
                        UserDefaults.standard.set(true, forKey: SettingsKey.notificationsEnabled)
                        UserDefaults.standard.set(8, forKey: SettingsKey.notificationHour)
                        UserDefaults.standard.set(0, forKey: SettingsKey.notificationMinute)
                    }
                    await MainActor.run { hasSeenOnboarding = true }
                }
            }
        }
    }
}

enum OnboardingAnimation {
    case breath
    case shake
    case ring
}

private struct OnboardingPage: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let text: String
    let animationKind: OnboardingAnimation

    @State private var animate = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(maxHeight: 40)
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: icon)
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(color)
                    .scaleEffect(scaleValue)
                    .rotationEffect(.degrees(rotationValue))
            }
            .onAppear {
                startAnimation()
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Constants.Palette.primaryTeal)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
    }

    private var scaleValue: CGFloat {
        switch animationKind {
        case .breath: return animate ? 1.08 : 0.92
        case .ring:   return animate ? 1.05 : 1.0
        case .shake:  return 1.0
        }
    }

    private var rotationValue: Double {
        switch animationKind {
        case .breath: return 0
        case .shake:  return animate ? 2 : -2
        case .ring:   return animate ? 6 : -6
        }
    }

    private func startAnimation() {
        switch animationKind {
        case .breath:
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                animate = true
            }
        case .shake:
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animate = true
            }
        case .ring:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
