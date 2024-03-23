import Foundation

struct Label: Assemblable {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    func updatedOrg() -> Int? {
        nil
    }

    func bytes(with _: ParseState) throws -> [UInt8] {
        []
    }

    func providesLabel() -> String? {
        label
    }

    func assembledLength() -> Int {
        0
    }
}
