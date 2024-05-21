import Foundation

struct Opcode: Assemblable {
    enum Param {
        case number(UInt8), address(UInt8), location(String), addition, subtraction

        func byte(with parseState: ParseState) throws -> UInt8 {
            switch self {
            case let .location(name):
                if let address = parseState.labels[name] {
                    UInt8(address)
                } else {
                    throw "Unknown label: \(name)"
                }
            case let .address(value), let .number(value):
                value
            case .addition:
                0b0000_1001
            case .subtraction:
                0b0000_0110
            }
        }
    }

    let command: Command
    let param: Param?

    init(_ command: Command, _ param: Param? = nil) {
        self.command = command
        self.param = param
    }

    func bytes(with parseState: ParseState) throws -> [UInt8] {
        if command.takesParam {
            if let param {
                try [command.byte, param.byte(with: parseState)]
            } else {
                throw "Command \(command.name) requires a parameter"
            }
        } else {
            [command.byte]
        }
    }

    func updatedOrg(from original: Int) -> Int {
        original + (command.takesParam ? 2 : 1)
    }
}
