import Foundation

struct Content: Assemblable {
    let bytes: [UInt8]

    func bytes(with _: ParseState) throws -> [UInt8] {
        bytes
    }

    func updatedOrg(from original: UInt16) -> UInt16 {
        original + UInt16(bytes.count)
    }
}
