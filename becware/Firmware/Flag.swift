import Foundation

struct Flag: OptionSet {
    let rawValue: Int

    static let carry = Flag(rawValue: 1 << 0)
    static let zero = Flag(rawValue: 1 << 1)

    var indicator: String {
        switch self {
        case .carry: "C"
        case .zero: "Z"
        default: "?"
        }
    }

    var name: String {
        var res = [String]()
        for f in [Flag.carry, Flag.zero] {
            if contains(f) {
                res.append(f.indicator)
            }
        }
        return res.joined(separator: ", ")
    }
}
