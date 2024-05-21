import Foundation

struct Content: Assemblable {
    let bytes: [UInt8]

    func bytes(with _: ParseState) throws -> [UInt8] {
        bytes
    }

    func updatedOrg(from original: Int) -> Int {
        original + bytes.count
    }
}
