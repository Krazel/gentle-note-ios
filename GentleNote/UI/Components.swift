import AVKit
import SwiftUI
import UIKit

struct RootTabBar: View {
    @Binding var selection: RootTab
    var body: some View {
        HStack {
            tab(.journal, "Journal", "book.closed")
            tab(.library, "Library", "books.vertical")
            tab(.settings, "Settings", "gearshape")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    private func tab(_ value: RootTab, _ title: LocalizedStringKey, _ icon: String) -> some View {
        Button {
            selection = value
        } label: {
            VStack(spacing: 3) {
                Image(systemName: selection == value ? icon + ".fill" : icon)
                    .font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(selection == value ? QuietLinen.forest : QuietLinen.ink)
        }
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(selection == value ? .isSelected : [])
    }
}

struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]
    var completion: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in completion?() }
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MediaPlayerView: View {
    let url: URL
    let kind: LibraryItemKind
    @State private var player: AVPlayer

    init(url: URL, kind: LibraryItemKind) {
        self.url = url
        self.kind = kind
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        Group {
            if kind == .video {
                VideoPlayer(player: player)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LinenCard {
                    VStack(spacing: 18) {
                        DecorativeWaveform(level: 0.56)
                            .frame(height: 82)
                        Button { player.rate == 0 ? player.play() : player.pause() } label: {
                            Label("Play or Pause", systemImage: "playpause.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
        }
        .onDisappear { player.pause() }
    }
}

struct DecorativeWaveform: View {
    var level: Float
    var body: some View {
        Canvas { context, size in
            for index in 0..<45 {
                let x = CGFloat(index) / 44 * size.width
                let pattern = CGFloat((index * 17) % 13) / 13
                let height = max(4, size.height * (0.12 + pattern * CGFloat(level) * 0.82))
                var line = Path()
                line.move(to: CGPoint(x: x, y: (size.height - height) / 2))
                line.addLine(to: CGPoint(x: x, y: (size.height + height) / 2))
                context.stroke(line, with: .color(QuietLinen.forest), lineWidth: 1.1)
            }
        }
        .accessibilityHidden(true)
    }
}

struct PermissionStatusRow: View {
    let title: LocalizedStringKey
    let icon: String
    let state: MediaPermissionState
    var body: some View {
        HStack {
            Image(systemName: icon).frame(width: 28)
            Text(title)
            Spacer()
            Text(state.title).foregroundStyle(QuietLinen.muted)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

extension Date {
    var gentleDate: String { formatted(date: .abbreviated, time: .omitted) }
}

extension TimeInterval {
    var clockString: String {
        let total = max(0, Int(self))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
