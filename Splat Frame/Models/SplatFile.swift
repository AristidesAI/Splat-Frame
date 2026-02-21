import Foundation

struct SplatFile: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var localURL: URL
    var sourceURL: URL?
    var fileSize: Int64
    var dateAdded: Date

    init(name: String, localURL: URL, sourceURL: URL? = nil, fileSize: Int64 = 0) {
        self.id = UUID()
        self.name = name
        self.localURL = localURL
        self.sourceURL = sourceURL
        self.fileSize = fileSize
        self.dateAdded = Date()
    }
}
