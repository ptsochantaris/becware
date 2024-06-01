import Foundation

protocol Assemblable {
    var label: String? { get }
    func updatedOrg(from original: Int) -> Int
    func bytes(with parseState: ParseState) throws -> [UInt8]
}

extension Assemblable {
    var label: String? {
        nil
    }

    func bytes(with _: ParseState) throws -> [UInt8] {
        []
    }

    func updatedOrg(from original: Int) -> Int {
        original
    }
}
