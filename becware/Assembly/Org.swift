import Foundation

struct Org: Assemblable {
    let org: UInt16

    init(_ org: UInt16) {
        self.org = org
    }

    func updatedOrg(from _: UInt16) -> UInt16 {
        org
    }
}
