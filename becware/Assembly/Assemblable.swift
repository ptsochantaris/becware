import Foundation

protocol Assemblable {
    func assembledLength() -> Int
    func updatedOrg() -> Int?
    func providesLabel() -> String?
    func bytes(with parseState: ParseState) throws -> [UInt8]
}
