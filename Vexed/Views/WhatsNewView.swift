import SwiftUI

/// One-time "what changed" recap shown to returning players after an update that added mechanics —
/// distinct from a first-time tutorial. Recommended by the onboarding research specifically because
/// this sprint shipped several mechanics at once, so existing installs (not just new players) need
/// reintroducing. New installs never see this (they get first-encounter tips instead); see
/// `WhatsNew.shouldPresent`.
struct WhatsNewView: View {
    let onDismiss: () -> Void

    private struct Item: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let blurb: String
    }

    private let items: [Item] = [
        Item(emoji: "🔒", title: "Locked & Multiplier tiles", blurb: "New bonus tiles: slide past a locked tile twice to free it; score through a ⭐️ tile to double the points."),
        Item(emoji: "⚡️", title: "Double Play", blurb: "Collect a row and column word that cross on one tile — score both at once for a bonus."),
        Item(emoji: "💣", title: "Power-ups", blurb: "Earn Bomb and Reveal charges to clear a stuck tile or surface a word instantly."),
        Item(emoji: "✨", title: "Ghost Preview & No-Repeat", blurb: "New optional modes in Settings — sparkle hints for scoring slides, or a no-repeated-words challenge."),
    ]

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.12, green: 0.12, blue: 0.20),
                         Color(red: 0.04, green: 0.04, blue: 0.08)],
                center: UnitPoint(x: 0.5, y: 0.32),
                startRadius: 0, endRadius: 520
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 44)
                Text("WHAT'S NEW")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.0))
                Text("Fresh ways to play")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(items) { item in
                            HStack(alignment: .top, spacing: 14) {
                                Text(item.emoji).font(.system(size: 26))
                                    .frame(width: 34)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.system(size: 15, weight: .black, design: .rounded))
                                        .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.35))
                                    Text(item.blurb)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }

                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 12, weight: .bold))
                        Text("LET'S PLAY").font(.system(size: 15, weight: .black, design: .rounded)).tracking(2)
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.0))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 15)
                    .background(
                        Capsule()
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.0).opacity(0.14))
                            .overlay(Capsule().strokeBorder(Color(red: 1.0, green: 0.85, blue: 0.0).opacity(0.7), lineWidth: 1.5))
                    )
                    .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.0).opacity(0.4), radius: 12)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 44)
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// Permanent reference for the mechanics that first-encounter tips explain — reachable any time
/// from the burger menu's Help section. The contextual tips fire once per install and are then
/// gone, so this gives a lasting home for "what does a Locked tile do again?" It reuses the same
/// `MechanicTip` title/body/emoji content, so it stays in sync automatically.
struct MechanicsReferenceView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(MechanicTip.allCases) { tip in
                    HStack(alignment: .top, spacing: 14) {
                        Text(tip.emoji).font(.system(size: 24)).frame(width: 32)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tip.title)
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.35))
                            Text(tip.referenceBody)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.82))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
                    )
                }
            }
            .padding(20)
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea())
        .navigationTitle("Mechanics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.09), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

/// Decides whether the "What's New" recap should appear this launch, keyed on the app's build
/// number. Shows once per build bump — but never on a genuinely fresh install (no prior build
/// recorded), since new players are onboarded through first-encounter tips instead.
enum WhatsNew {
    private static let key = "lastSeenWhatsNewBuild"

    static var currentBuild: Int {
        Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0
    }

    static func shouldPresent() -> Bool {
        let ud = UserDefaults.standard
        guard let previous = ud.object(forKey: key) as? Int else {
            // No record yet. If the app has been launched before (existing install that predates
            // this tracking), show it once so returning testers get caught up; a genuinely fresh
            // install records silently and relies on first-encounter tips instead.
            let launchedBefore = ud.bool(forKey: "vexed.launched")
            ud.set(currentBuild, forKey: key)
            return launchedBefore
        }
        return currentBuild > previous
    }

    static func markSeen() {
        UserDefaults.standard.set(currentBuild, forKey: key)
    }
}
