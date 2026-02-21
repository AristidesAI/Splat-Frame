import Foundation
import Observation

/// A single item in the splat feed, scraped from splats.com.
struct SplatFeedItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var title: String
    var thumbnailURL: URL?
    var watchURL: URL
    var splatFileURL: URL?
    var duration: String?
    var viewCount: String?
}

/// Fetches and parses splat content from splats.com for the native feed.
@Observable
final class SplatFeedService {
    private(set) var items: [SplatFeedItem] = []
    private(set) var isLoading = false
    private(set) var error: String?

    private let cacheURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("splat_feed_cache.json")
    }()

    private let splatsDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Splats", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Shared session with a browser-style User-Agent to avoid bot blocking
    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
        ]
        return URLSession(configuration: config)
    }()

    init() {
        loadCachedItems()
    }

    /// Fetch the latest content from splats.com
    func refresh() async {
        isLoading = true
        error = nil

        do {
            let url = URL(string: "https://www.splats.com/")!
            let (data, _) = try await urlSession.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                error = "Failed to decode response"
                isLoading = false
                return
            }

            let parsed = parseFeedItems(from: html)
            if !parsed.isEmpty {
                items = parsed
                saveCachedItems()
            } else {
                error = "No content found"
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Download a splat file from its watch page URL.
    /// Returns the local file URL on success.
    func downloadSplat(item: SplatFeedItem) async throws -> URL {
        // If we already have a direct file URL from parsing, try that first
        if let directURL = item.splatFileURL {
            return try await downloadFile(from: directURL, title: item.title)
        }

        // Otherwise, fetch the watch page to find the actual file URL
        let (pageData, _) = try await urlSession.data(from: item.watchURL)
        guard let pageHTML = String(data: pageData, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }

        // Look for .splat/.ply/.spz file URLs in the page
        guard let fileURL = extractSplatFileURL(from: pageHTML) else {
            throw URLError(.fileDoesNotExist, userInfo: [
                NSLocalizedDescriptionKey: "Could not find a splat file on this page. The page may use a different format."
            ])
        }

        return try await downloadFile(from: fileURL, title: item.title)
    }

    private func downloadFile(from fileURL: URL, title: String) async throws -> URL {
        let (tempURL, response) = try await urlSession.download(from: fileURL)

        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.fileDoesNotExist, userInfo: [
                NSLocalizedDescriptionKey: "Download failed with status \(httpResponse.statusCode)"
            ])
        }

        // Move to our splats directory
        let filename = title.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let ext = fileURL.pathExtension.isEmpty ? "splat" : fileURL.pathExtension
        let localURL = splatsDirectory.appendingPathComponent("\(filename).\(ext)")

        if FileManager.default.fileExists(atPath: localURL.path) {
            try FileManager.default.removeItem(at: localURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: localURL)

        return localURL
    }

    /// Check if a splat file is already downloaded locally.
    func localFileURL(for item: SplatFeedItem) -> URL? {
        let filename = item.title.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let extensions = ["splat", "ply", "spz"]
        for ext in extensions {
            let url = splatsDirectory.appendingPathComponent("\(filename).\(ext)")
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    // MARK: - HTML Parsing

    /// Parse splat feed items from the HTML response.
    /// This extracts thumbnail URLs, titles, and watch page links.
    private func parseFeedItems(from html: String) -> [SplatFeedItem] {
        var items: [SplatFeedItem] = []

        // Look for watch page links with pattern: /watch/NUMBER or /watch/SLUG
        let watchPattern = #"/watch/([a-zA-Z0-9_-]+)"#
        guard let watchRegex = try? NSRegularExpression(pattern: watchPattern) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        let matches = watchRegex.matches(in: html, range: range)

        var seenIDs = Set<String>()
        for match in matches {
            guard let idRange = Range(match.range(at: 1), in: html) else { continue }
            let id = String(html[idRange])
            guard !seenIDs.contains(id) else { continue }
            seenIDs.insert(id)

            let watchURL = URL(string: "https://www.splats.com/watch/\(id)")!

            // Try to find a nearby thumbnail image
            let thumbnailURL = findThumbnail(near: match.range.location, in: html)

            // Try to find a nearby splat file URL
            let splatFileURL = findSplatFile(near: match.range.location, in: html)

            // Try to find a nearby title text
            let title = findTitle(near: match.range.location, in: html) ?? "Splat #\(id)"

            items.append(SplatFeedItem(
                id: id,
                title: title,
                thumbnailURL: thumbnailURL,
                watchURL: watchURL,
                splatFileURL: splatFileURL
            ))
        }

        return items
    }

    private func findThumbnail(near location: Int, in html: String) -> URL? {
        // Search in a larger window around the watch link for an img src
        let searchStart = max(0, location - 1000)
        let searchEnd = min(html.count, location + 1000)
        let startIdx = html.index(html.startIndex, offsetBy: searchStart)
        let endIdx = html.index(html.startIndex, offsetBy: searchEnd)
        let window = String(html[startIdx..<endIdx])

        // Match src="..." patterns that look like image URLs - broader matching
        let patterns = [
            #"(?:src|poster|data-src|srcset)="(https?://[^"\s]+(?:\.jpg|\.png|\.webp|\.jpeg|thumbnail|image|thumb|preview)[^"\s]*)"#,
            #"(?:src|poster|data-src)="(https?://[^"]+)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let windowRange = NSRange(window.startIndex..., in: window)
            guard let match = regex.firstMatch(in: window, range: windowRange),
                  let urlRange = Range(match.range(at: 1), in: window) else { continue }

            let urlString = String(window[urlRange])
            // Skip non-image URLs
            if urlString.contains(".js") || urlString.contains(".css") || urlString.contains("favicon") { continue }
            if let url = URL(string: urlString) { return url }
        }

        return nil
    }

    private func findSplatFile(near location: Int, in html: String) -> URL? {
        let searchStart = max(0, location - 2000)
        let searchEnd = min(html.count, location + 2000)
        let startIdx = html.index(html.startIndex, offsetBy: searchStart)
        let endIdx = html.index(html.startIndex, offsetBy: searchEnd)
        let window = String(html[startIdx..<endIdx])

        let pattern = #"(https?://[^\s"']+\.(?:splat|ply|spz))"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let windowRange = NSRange(window.startIndex..., in: window)
        guard let match = regex.firstMatch(in: window, range: windowRange),
              let urlRange = Range(match.range(at: 1), in: window) else { return nil }
        return URL(string: String(window[urlRange]))
    }

    private func findTitle(near location: Int, in html: String) -> String? {
        let searchStart = max(0, location - 500)
        let searchEnd = min(html.count, location + 500)
        let startIdx = html.index(html.startIndex, offsetBy: searchStart)
        let endIdx = html.index(html.startIndex, offsetBy: searchEnd)
        let window = String(html[startIdx..<endIdx])

        // Look for title-like text in nearby elements
        let patterns = [
            #"title="([^"]+)"#,
            #"alt="([^"]+)"#,
            #">([A-Z][^<]{3,40})<"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let windowRange = NSRange(window.startIndex..., in: window)
            guard let match = regex.firstMatch(in: window, range: windowRange),
                  let textRange = Range(match.range(at: 1), in: window) else { continue }
            let text = String(window[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if text.count > 2 { return text }
        }
        return nil
    }

    /// Extract the actual splat file URL from a watch page.
    private func extractSplatFileURL(from html: String) -> URL? {
        // Look for URLs ending in .splat, .ply, or .spz — broader matching
        let patterns = [
            #"(https?://[^\s"'<>]+\.(?:splat|ply|spz)(?:\?[^\s"'<>]*)?)"#,
            #"["']([^"']+\.(?:splat|ply|spz)(?:\?[^"']*)?)"#,
            #"url\s*[:=]\s*["']?(https?://[^\s"'<>]+)["']?"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, range: range),
               let urlRange = Range(match.range(at: 1), in: html) {
                let urlString = String(html[urlRange])
                if let url = URL(string: urlString) { return url }
            }
        }
        return nil
    }

    // MARK: - Cache

    private func saveCachedItems() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: cacheURL)
    }

    private func loadCachedItems() {
        guard let data = try? Data(contentsOf: cacheURL),
              let cached = try? JSONDecoder().decode([SplatFeedItem].self, from: data) else { return }
        items = cached
    }
}
