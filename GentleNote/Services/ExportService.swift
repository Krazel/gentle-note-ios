import AVFoundation
import Foundation
import UIKit

enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf = "Readable PDF"
    case text = "Plain Text"
    case originalMedia = "Original Media"
    var id: String { rawValue }
    var title: String { rawValue.gentleLocalized }
}

struct ExportService {
    let store: SecureVaultStore

    func journalEntry(_ entry: JournalEntry, format: ExportFormat) throws -> URL {
        let text = render(entry)
        switch format {
        case .text:
            return try write(text, named: safe(entry.displayTitle), ext: "txt")
        case .pdf:
            return try writePDF(text, named: safe(entry.displayTitle))
        case .originalMedia:
            throw CocoaError(.fileWriteUnsupportedScheme)
        }
    }

    func libraryItem(_ item: LibraryItem, format: ExportFormat) throws -> URL {
        if item.kind != .note,
           let filename = item.encryptedMediaFilename,
           let ext = item.mediaFileExtension {
            return try store.readableMediaURL(filename: filename, extension: ext)
        }
        let text = [item.displayTitle, "", item.body].joined(separator: "\n")
        return format == .pdf ? try writePDF(text, named: safe(item.displayTitle))
                              : try write(text, named: safe(item.displayTitle), ext: "txt")
    }

    func allReadable(vault: VaultSnapshot, format: ExportFormat) throws -> URL {
        var sections = vault.journalEntries.sorted { $0.createdAt < $1.createdAt }.map(render)
        sections += vault.libraryItems.filter { $0.kind == .note }.map {
            "LIBRARY NOTE".gentleLocalized + "\n\($0.displayTitle)\n\($0.createdAt.formatted(date: .long, time: .shortened))\n\n\($0.body)"
        }
        let text = sections.joined(separator: "\n\n————————————\n\n")
        return format == .pdf ? try writePDF(text, named: "Gentle Note Export")
                              : try write(text, named: "Gentle Note Export", ext: "txt")
    }

    private func render(_ entry: JournalEntry) -> String {
        var lines = [entry.displayTitle,
                     entry.createdAt.formatted(date: .long, time: .shortened), ""]
        if !entry.body.isEmpty { lines.append(entry.body) }
        for (index, answer) in entry.answers.enumerated() where !answer.isEmpty {
            if index < entry.templateID.prompts.count { lines.append(entry.templateID.prompts[index]) }
            lines.append(answer)
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func write(_ text: String, named name: String, ext: String) throws -> URL {
        let url = store.temporaryURL.appendingPathComponent(name + "." + ext)
        try text.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                              ofItemAtPath: url.path)
        return url
    }

    private func writePDF(_ text: String, named name: String) throws -> URL {
        let url = store.temporaryURL.appendingPathComponent(name + ".pdf")
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        try renderer.writePDF(to: url) { context in
            let paragraphs = text.components(separatedBy: "\n")
            var y: CGFloat = 54
            for paragraph in paragraphs {
                if y > 730 { context.beginPage(); y = 54 }
                let heading = y == 54 || paragraph.allSatisfy { !$0.isLowercase }
                let font = heading ? UIFont(name: "NewYork-Regular", size: 18) ?? .boldSystemFont(ofSize: 18)
                                   : UIFont.preferredFont(forTextStyle: .body)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(red: 0.08, green: 0.20, blue: 0.15, alpha: 1)
                ]
                let rect = CGRect(x: 54, y: y, width: 504, height: 690 - y)
                let box = (paragraph as NSString).boundingRect(with: rect.size,
                                                                options: [.usesLineFragmentOrigin],
                                                                attributes: attributes,
                                                                context: nil)
                paragraph.draw(in: CGRect(x: rect.minX, y: y, width: rect.width, height: max(24, box.height)),
                               withAttributes: attributes)
                y += max(24, box.height) + 8
            }
        }
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                              ofItemAtPath: url.path)
        return url
    }

    private func safe(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let cleaned = value.components(separatedBy: invalid).joined(separator: "-")
        return String(cleaned.prefix(60)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
