import Foundation

struct Label: Assemblable {
    let label: String?

    init(_ label: String) {
        self.label = label
    }
}
