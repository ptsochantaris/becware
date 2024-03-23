import Foundation

struct Org: Assemblable {
    let org: Int

    func updatedOrg() -> Int? {
        org
    }

    func bytes(with _: ParseState) throws -> [UInt8] {
        []
    }

    func providesLabel() -> String? {
        nil
    }

    func assembledLength() -> Int {
        0
    }
}
