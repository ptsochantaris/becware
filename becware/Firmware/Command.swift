import Foundation

extension UInt16 {
    var bytes: [UInt8] {
        let AL = UInt8(self & 0xFF)
        let AH = UInt8(self >> 8)
        return [AH, AL]
    }
}

enum Command: CaseIterable, Assemblable {
    enum Location {
        case address(UInt16), label(String)

        func bytes(with parseState: ParseState) throws -> [UInt8] {
            switch self {
            case let .label(name):
                if let address = parseState.labels[name] {
                    address.bytes
                } else {
                    throw "Unknown label: \(name)"
                }

            case let .address(value):
                value.bytes
            }
        }
    }

    enum Arithmetic {
        case addition, subtraction

        var byte: UInt8 {
            switch self {
            case .addition:
                0b1001

            case .subtraction:
                0b0110
            }
        }
    }

    case NoOp,
         LoadA(from: Location),
         LoadB(from: Location),
         Calculate(using: Arithmetic),
         Store(to: Location),
         SetA(number: UInt8),
         Jump(to: Location),
         JumpOnCarry(to: Location),
         JumpOnZero(to: Location),
         Out,
         Halt

    private static let nullLocation = Location.address(0)

    static var allCases: [Command] {
        [
            .NoOp,
            .LoadA(from: nullLocation),
            .LoadB(from: nullLocation),
            .Calculate(using: .addition),
            .Store(to: nullLocation),
            .SetA(number: 0),
            .Jump(to: nullLocation),
            .JumpOnCarry(to: nullLocation),
            .JumpOnZero(to: nullLocation),
            .Out,
            .Halt
        ]
    }

    var byte: UInt8 {
        switch self {
        case .NoOp: 0b0000
        case .LoadA: 0b0001 // Address to load into A
        case .LoadB: 0b0010 // Address to load into B
        case .Calculate: 0b0011 // Set ALU function and store result in A
        case .Store: 0b0100 // Address to store the contents of A
        case .SetA: 0b0101 // Value to set A
        case .Jump: 0b0110 // Address to jump to
        case .JumpOnCarry: 0b0111 // Address to jump to
        case .JumpOnZero: 0b1000 // Address to jump to
        case .Out: 0b1110
        case .Halt: 0b1111
        }
    }

    var name: String {
        switch self {
        case .NoOp: "NoOp"
        case .Calculate: "Calculate"
        case .Halt: "Halt"
        case .LoadA: "LoadA"
        case .LoadB: "LoadB"
        case .Out: "Out"
        case .Store: "Store"
        case .SetA: "SetA"
        case .Jump: "Jump"
        case .JumpOnCarry: "JumpOnCarry"
        case .JumpOnZero: "JumpOnZero"
        }
    }

    var expectedLength: Int {
        switch self {
        case .Jump, .JumpOnCarry, .JumpOnZero, .LoadA, .LoadB, .Store:
            3
        case .Calculate, .SetA:
            2
        case .Halt, .NoOp, .Out:
            1
        }
    }

    private static let instructionFetch: [[Signal]] = [
        [.addressHIn, .counterHOut],
        [.addressLIn, .counterLOut],
        [.ramOut, .instructionIn, .counterIncrement]
    ]

    private static let argumentFetch8: [[Signal]] = [
        [.addressHIn, .counterHOut],
        [.addressLIn, .counterLOut],
        [.ramOut, .argumentLIn, .counterIncrement]
    ]

    private static let argumentFetch16: [[Signal]] = [
        [.addressHIn, .counterHOut],
        [.addressLIn, .counterLOut],
        [.ramOut, .argumentHIn, .counterIncrement],
        [.addressHIn, .counterHOut],
        [.addressLIn, .counterLOut],
        [.ramOut, .argumentLIn, .counterIncrement]
    ]

    private static let jumpSignals: [[Signal]] = [
        [.addressHIn, .argumentHOut],
        [.addressLIn, .argumentLOut],
        [.argumentHOut, .counterHIn],
        [.argumentLOut, .counterLIn]
    ]

    private static let skipArguments: [[Signal]] = [
        [.counterIncrement],
        [.counterIncrement]
    ]

    private func specificSteps(for flags: Flag) -> [[Signal]] {
        switch self {
        case .NoOp: []

        case .LoadA: Self.argumentFetch16 + [
                [.addressHIn, .argumentHOut],
                [.addressLIn, .argumentLOut],
                [.ramOut, .regAIn]
            ]

        case .LoadB: Self.argumentFetch16 + [
                [.addressHIn, .argumentHOut],
                [.addressLIn, .argumentLOut],
                [.ramOut, .regBIn]
            ]

        case .Calculate: Self.argumentFetch8 + [
                [.calcIn, .argumentLOut],
                [.regAIn, .calcOut, .flagsIn]
            ]

        case .Out: [
                [.regAOut, .displayIn]
            ]

        case .SetA: Self.argumentFetch8 + [
                [.argumentLOut, .regAIn]
            ]

        case .Halt: [
                [.halt]
            ]

        case .Store: Self.argumentFetch16 + [
                [.addressHIn, .argumentHOut],
                [.addressLIn, .argumentLOut],
                [.regAOut, .ramIn]
            ]

        case .Jump: Self.argumentFetch16 + Self.jumpSignals

        case .JumpOnCarry:
            flags.contains(.carry) ? (Self.argumentFetch16 + Self.jumpSignals) : Self.skipArguments

        case .JumpOnZero:
            flags.contains(.zero) ? (Self.argumentFetch16 + Self.jumpSignals) : Self.skipArguments
        }
    }

    func steps(for flags: Flag) -> [[Signal]] {
        (Self.instructionFetch
            + specificSteps(for: flags)
            + [[.nextCommand]]).filter { !$0.isEmpty }
    }

    func bytes(with parseState: ParseState) throws -> [UInt8] {
        var bytes = [byte]

        switch self {
        case .Halt, .NoOp, .Out: break
        case let .Jump(location),
             let .JumpOnCarry(location),
             let .JumpOnZero(location),
             let .LoadA(location),
             let .LoadB(location),
             let .Store(location):
            bytes += try location.bytes(with: parseState)

        case let .SetA(number):
            bytes += [number]

        case let .Calculate(operation):
            bytes += [operation.byte]
        }

        if bytes.count == expectedLength {
            return bytes
        }

        throw "Command \(name) requires a parameter"
    }

    func updatedOrg(from original: Int) -> Int {
        original + expectedLength
    }
}
