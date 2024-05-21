import Foundation

struct Org: Assemblable {
    let org: Int

    func updatedOrg(from _: Int) -> Int {
        org
    }
}
