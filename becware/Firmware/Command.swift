import Foundation

extension UInt16 {
    var bytes: [UInt8] {
        [UInt8(self >> 8), UInt8(self & 0xFF)]
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
         StoreA(to: Location),
         SetA(number: UInt8),

         SetAFromB, SetBFromA, SwapAB,
         SetAFromC, SetCFromA, SwapAC,
         SetAFromD, SetDFromA, SwapAD,
         SetAFromE, SetEFromA, SwapAE,

         Calculate(using: Arithmetic),

         Jump(to: Location),
         JumpOnCarry(to: Location),
         JumpOnZero(to: Location),

         OutCommand, Out,

         PushA, PopA,

         Call(to: Location), Return,

         Halt

    private static let nullLocation = Location.address(0)

    static var allCases: [Command] {
        [
            NoOp,
            LoadA(from: .address(0)),
            StoreA(to: .address(0)),
            SetA(number: 0),

            SetAFromB, SetBFromA, SwapAB,
            SetAFromC, SetCFromA, SwapAC,
            SetAFromD, SetDFromA, SwapAD,
            SetAFromE, SetEFromA, SwapAE,

            Calculate(using: .addition),

            Jump(to: .address(0)),
            JumpOnCarry(to: .address(0)),
            JumpOnZero(to: .address(0)),

            OutCommand, Out,

            PushA, PopA,

            Call(to: .address(0)), Return,

            Halt
        ]
    }

    var byte: UInt8 {
        switch self {
        case .NoOp: 0x00
        case .LoadA: 0x01
        case .StoreA: 0x02
        case .SetA: 0x03
        case .SetAFromB: 0x04
        case .SetBFromA: 0x05
        case .SwapAB: 0x06
        case .SetAFromC: 0x07
        case .SetCFromA: 0x08
        case .SwapAC: 0x09
        case .SetAFromD: 0x0A
        case .SetDFromA: 0x0B
        case .SwapAD: 0x0C
        case .SetAFromE: 0x0D
        case .SetEFromA: 0x0E
        case .SwapAE: 0x0F
        case .Calculate: 0x10
        case .Jump: 0x011
        case .JumpOnCarry: 0x12
        case .JumpOnZero: 0x13
        case .OutCommand: 0x14
        case .Out: 0x15
        case .PushA: 0x16
        case .PopA: 0x17
        case .Halt: 0x18
        case .Call: 0x19
        case .Return: 0x1A
        }
    }

    var name: String {
        switch self {
        case .NoOp: "No Op"
        case .LoadA: "Load A"
        case .StoreA: "Store A"
        case .SetA: "Set A"
        case .SetBFromA: "Copy A → B"
        case .SetAFromB: "Copy B → A"
        case .SwapAB: "Swap A ↔ B"
        case .SetAFromC: "Copy C → A"
        case .SetCFromA: "Copy A → C"
        case .SwapAC: "Swap A ↔ C"
        case .SetAFromD: "Copy D → A"
        case .SetDFromA: "Copy A → D"
        case .SwapAD: "Swap A ↔ D"
        case .SetAFromE: "Copy E → A"
        case .SetEFromA: "Copy A → E"
        case .SwapAE: "Swap A ↔ E"
        case .Calculate: "Calculate"
        case .Jump: "Jump"
        case .JumpOnCarry: "Jump On Carry"
        case .JumpOnZero: "Jump On Zero"
        case .OutCommand: "Out Register Select"
        case .Out: "Out Data"
        case .PushA: "Push A"
        case .PopA: "Pop A"
        case .Halt: "Halt"
        case .Call: "Call"
        case .Return: "Return"
        }
    }

    var expectedLength: Int {
        switch self {
        case .Call, .Jump, .JumpOnCarry, .JumpOnZero, .LoadA, .StoreA:
            3
        case .Calculate, .SetA:
            2
        case .Halt, .NoOp, .Out, .OutCommand, .PopA, .PushA, .Return, .SetAFromB, .SetAFromC, .SetAFromD, .SetAFromE, .SetBFromA, .SetCFromA, .SetDFromA, .SetEFromA, .SwapAB, .SwapAC, .SwapAD, .SwapAE:
            1
        }
    }

    private static let fetchInstruction: [[Signal]] = [
        [.addressHIn, .counterHOut],
        [.addressLIn, .counterLOut],
        [.ramOut, .instructionIn, .counterIncrement]
    ]

    private static let fetch8bitArgument: [[Signal]] = [
        [.addressHIn, .counterHOut],
        [.addressLIn, .counterLOut],
        [.ramOut, .argumentLIn, .counterIncrement]
    ]

    private static let fetch16bitArgument: [[Signal]] = [
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

        case .LoadA: Self.fetch16bitArgument + [
                [.addressHIn, .argumentHOut],
                [.addressLIn, .argumentLOut],
                [.ramOut, .regAIn]
            ]

        case .Calculate: Self.fetch8bitArgument + [
                [.calcIn, .argumentLOut],
                [.regAIn, .calcOut, .flagsIn]
            ]

        case .Out: [
                [.regAOut, .displayIn, .displaySelect]
            ]

        case .OutCommand: [
                [.regAOut, .displayIn]
            ]

        case .SetA: Self.fetch8bitArgument + [
                [.argumentLOut, .regAIn]
            ]

        case .Halt: [
                [.halt]
            ]

        case .StoreA: Self.fetch16bitArgument + [
                [.addressHIn, .argumentHOut],
                [.addressLIn, .argumentLOut],
                [.regAOut, .ramIn]
            ]

        case .Jump: Self.fetch16bitArgument + Self.jumpSignals

        case .JumpOnCarry:
            flags.contains(.carry) ? (Self.fetch16bitArgument + Self.jumpSignals) : Self.skipArguments

        case .JumpOnZero:
            flags.contains(.zero) ? (Self.fetch16bitArgument + Self.jumpSignals) : Self.skipArguments

        case .SetBFromA: [
                [.regAOut, .regBIn]
            ]

        case .SetAFromB: [
                [.regBOut, .regAIn]
            ]

        case .SetAFromC: [
                [.regCOut, .regAIn]
            ]

        case .SwapAB: [
                [.regAOut, .regIIn],
                [.regBOut, .regAIn],
                [.regIOut, .regBIn]
            ]

        case .SwapAC: [
                [.regAOut, .regIIn],
                [.regCOut, .regAIn],
                [.regIOut, .regCIn]
            ]

        case .SwapAD: [
                [.regAOut, .regIIn],
                [.regDOut, .regAIn],
                [.regIOut, .regDIn]
            ]

        case .SwapAE: [
                [.regAOut, .regIIn],
                [.regEOut, .regAIn],
                [.regIOut, .regEIn]
            ]

        case .SetCFromA: [
                [.regAOut, .regCIn]
            ]

        case .SetAFromD: [
                [.regDOut, .regAIn]
            ]

        case .SetDFromA: [
                [.regAOut, .regDIn]
            ]

        case .SetAFromE: [
                [.regEOut, .regAIn]
            ]

        case .SetEFromA: [
                [.regAOut, .regEIn]
            ]

        case .PushA: [
                [.stackDecrement],
                [.addressHIn, .stackHOut],
                [.addressLIn, .stackLOut],
                [.regAOut, .ramIn],
                [.addressHIn, .counterHOut],
                [.addressLIn, .counterLOut]
            ]

        case .PopA: [
                [.addressHIn, .stackHOut],
                [.addressLIn, .stackLOut],
                [.regAIn, .ramOut, .stackIncrement],
                [.addressHIn, .counterHOut],
                [.addressLIn, .counterLOut]
            ]

        case .Call: Self.fetch16bitArgument + [
                [.stackDecrement],
                [.addressHIn, .stackHOut],
                [.addressLIn, .stackLOut],
                [.counterHOut, .ramIn, .stackDecrement],
                [.addressHIn, .stackHOut],
                [.addressLIn, .stackLOut],
                [.counterLOut, .ramIn],

                [.addressHIn, .argumentHOut],
                [.addressLIn, .argumentLOut],
                [.argumentHOut, .counterHIn],
                [.argumentLOut, .counterLIn]
            ]

        case .Return: [
                [.addressHIn, .stackHOut],
                [.addressLIn, .stackLOut],
                [.counterHIn, .ramOut, .stackIncrement],
                [.addressHIn, .stackHOut],
                [.addressLIn, .stackLOut],
                [.counterLIn, .ramOut, .stackIncrement]
            ]
        }
    }

    func steps(for flags: Flag) -> [[Signal]] {
        (Self.fetchInstruction
            + specificSteps(for: flags)
            + [[.nextCommand]]).filter { !$0.isEmpty }
    }

    func bytes(with parseState: ParseState) throws -> [UInt8] {
        var bytes = [byte]

        switch self {
        case .Halt, .NoOp, .Out, .OutCommand, .PopA, .PushA, .Return, .SetAFromB, .SetAFromC, .SetAFromD, .SetAFromE, .SetBFromA, .SetCFromA, .SetDFromA, .SetEFromA, .SwapAB, .SwapAC, .SwapAD, .SwapAE:
            break

        case let .Call(location),
             let .Jump(location),
             let .JumpOnCarry(location),
             let .JumpOnZero(location),
             let .LoadA(location),
             let .StoreA(location):
            bytes += try location.bytes(with: parseState)

        case let .SetA(number):
            bytes += [number]

        case let .Calculate(operation):
            bytes += [operation.byte]
        }

        if bytes.count != expectedLength {
            throw "Command \(name) requires a parameter"
        }

        return bytes
    }

    func updatedOrg(from original: Int) -> Int {
        original + expectedLength
    }
}
