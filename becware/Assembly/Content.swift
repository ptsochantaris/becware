import Foundation

struct Content: Assemblable {
    let bytes: [UInt8]

    func updatedOrg() -> Int? {
        nil
    }

    func bytes(with _: ParseState) throws -> [UInt8] {
        bytes
    }

    func providesLabel() -> String? {
        nil
    }

    func assembledLength() -> Int {
        bytes.count
    }
}
