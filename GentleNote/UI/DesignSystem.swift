import SwiftUI
import UIKit

enum QuietLinen {
    static let paper = Color(light: 0xFAF6ED, dark: 0x171A17)
    static let paperRaised = Color(light: 0xFFFDF8, dark: 0x20251F)
    static let ink = Color(light: 0x173A2B, dark: 0xE8EFE8)
    static let forest = Color(light: 0x285C42, dark: 0x77A98A)
    static let sage = Color(light: 0xAAB59B, dark: 0x697A66)
    static let clay = Color(light: 0xBE6B43, dark: 0xD88B67)
    static let ochre = Color(light: 0xD6B16F, dark: 0xC9A864)
    static let line = Color(light: 0xD8D0C2, dark: 0x465047)
    static let muted = Color(light: 0x58625C, dark: 0xAEB8B0)
    static let danger = Color(light: 0xB63A2B, dark: 0xFF8172)
}

extension Color {
    init(light: UInt, dark: UInt) {
        self.init(UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 0xff) / 255,
                           green: CGFloat((value >> 8) & 0xff) / 255,
                           blue: CGFloat(value & 0xff) / 255,
                           alpha: 1)
        })
    }
}

struct PaperBackground: View {
    var body: some View {
        ZStack {
            QuietLinen.paper
            Canvas { context, size in
                var seed: UInt64 = 0x5EED
                for _ in 0..<240 {
                    seed = seed &* 6364136223846793005 &+ 1
                    let x = CGFloat(seed % 10_000) / 10_000 * size.width
                    seed = seed &* 6364136223846793005 &+ 1
                    let y = CGFloat(seed % 10_000) / 10_000 * size.height
                    let rect = CGRect(x: x, y: y, width: 0.7, height: 0.7)
                    context.fill(Path(ellipseIn: rect), with: .color(QuietLinen.ink.opacity(0.025)))
                }
            }
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

struct BotanicalSprig: View {
    var color = QuietLinen.sage
    var body: some View {
        Canvas { context, size in
            var stem = Path()
            stem.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.72))
            stem.addCurve(to: CGPoint(x: size.width * 0.92, y: size.height * 0.28),
                          control1: CGPoint(x: size.width * 0.34, y: size.height * 0.55),
                          control2: CGPoint(x: size.width * 0.64, y: size.height * 0.5))
            context.stroke(stem, with: .color(color), lineWidth: 1.3)
            for index in 1...6 {
                let t = CGFloat(index) / 7
                let x = size.width * (0.08 + 0.84 * t)
                let y = size.height * (0.72 - 0.44 * t)
                let up = index.isMultiple(of: 2)
                let leaf = Path(ellipseIn: CGRect(x: x - 5,
                                                  y: y + (up ? -11 : 2),
                                                  width: 12,
                                                  height: 7))
                context.fill(leaf, with: .color(color.opacity(0.86)))
            }
        }
        .frame(width: 82, height: 30)
        .accessibilityHidden(true)
    }
}

struct LinenCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(14)
            .background(QuietLinen.paperRaised.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(QuietLinen.line, lineWidth: 0.8))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(.white)
            .background(QuietLinen.forest.opacity(configuration.isPressed ? 0.78 : 1),
                        in: RoundedRectangle(cornerRadius: 9))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(QuietLinen.ink)
            .background(QuietLinen.paperRaised.opacity(configuration.isPressed ? 0.65 : 1),
                        in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(QuietLinen.line))
    }
}

extension View {
    func linenScreen() -> some View {
        background(PaperBackground()).foregroundStyle(QuietLinen.ink)
    }

    func editorialTitle() -> some View {
        font(.system(.largeTitle, design: .serif, weight: .regular))
            .foregroundStyle(QuietLinen.ink)
            .multilineTextAlignment(.center)
    }
}

struct LinenTextEditor: View {
    let prompt: String
    @Binding var text: String
    var minHeight: CGFloat = 104

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(prompt).foregroundStyle(QuietLinen.muted).padding(.horizontal, 13).padding(.vertical, 16)
            }
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: minHeight)
        }
        .background(QuietLinen.paperRaised.opacity(0.78), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(QuietLinen.line))
        .accessibilityLabel(prompt)
    }
}
