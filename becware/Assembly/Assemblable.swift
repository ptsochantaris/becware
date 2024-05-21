import Foundation

protocol Assemblable {
    var label: String? { get }
    func updatedOrg(from original: UInt16) -> UInt16
    func bytes(with parseState: ParseState) throws -> [UInt8]
}

extension Assemblable {
    var label: String? {
        nil
    }

    func bytes(with _: ParseState) throws -> [UInt8] {
        []
    }

    func updatedOrg(from original: UInt16) -> UInt16 {
        original
    }
}
