import Foundation

extension UInt16 {
    var bytes: [UInt8] {
        [UInt8(self & 0xFF), UInt8(self >> 8)]
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

         SetBFromA,

         SetAFromC, SetCFromA, SwapAC,

         SetAFromD, SetDFromA, SwapAD,

         SetAFromE, SetEFromA,

         Calculate(using: Arithmetic),

         Jump(to: Location),
         JumpOnCarry(to: Location),
         JumpOnZero(to: Location),

         OutCommand,
         Out,

         PushA,
         PopA,
         PushE,
         PopE,

         Halt

    private static let nullLocation = Location.address(0)

    static var allCases: [Command] {
        [
            NoOp,
            LoadA(from: .address(0)),
            StoreA(to: .address(0)),
            SetA(number: 0),
            
            SetBFromA,
            SetAFromC, SetCFromA, SwapAC,
            SetAFromD, SetDFromA, SwapAD,
            SetAFromE, SetEFromA,

            Calculate(using: .addition),
            
            Jump(to: .address(0)),
            JumpOnCarry(to: .address(0)),
            JumpOnZero(to: .address(0)),
            
            OutCommand, Out,

            PushA, PopA,

            Halt
        ]
    }

    var byte: UInt8 {
        switch self {
        case .NoOp: 0
        case .LoadA: 1
        case .StoreA: 2
        case .SetA: 3

        case .SetBFromA: 4
        
        case .SetAFromC: 5
        case .SetCFromA: 6
        case .SwapAC: 7

        case .SetAFromD: 8
        case .SetDFromA: 9
        case .SwapAD: 10

        case .SetAFromE: 11
        case .SetEFromA: 12

        case .Calculate: 13

        case .Jump: 14
        case .JumpOnCarry: 15
        case .JumpOnZero: 16

        case .OutCommand: 17
        case .Out: 18

        case .PushA: 19
        case .PopA: 20

        case .PushE: 21
        case .PopE: 22

        case .Halt: 23
        }
    }

    var name: String {
        switch self {
        case .NoOp: "No Op"
        case .LoadA: "Load A"
        case .StoreA: "Store A"
        case .SetA: "Set A"

        case .SetBFromA: "Copy A → B"

        case .SetAFromC: "Copy C → A"
        case .SetCFromA: "Copy A → C"
        case .SwapAC: "Swap A ↔ C"

        case .SetAFromD: "Copy D → A"
        case .SetDFromA: "Copy A → D"
        case .SwapAD: "Swap A ↔ D"

        case .SetAFromE: "Copy E → A"
        case .SetEFromA: "Copy A → E"

        case .Calculate: "Calculate"

        case .Jump: "Jump"
        case .JumpOnCarry: "Jump On Carry"
        case .JumpOnZero: "Jump On Zero"

        case .OutCommand: "Out Register Select"
        case .Out: "Out Data"

        case .PushA: "Push A"
        case .PopA: "Pop A"
        case .PushE: "Push E"
        case .PopE: "Pop E"

        case .Halt: "Halt"
        }
    }

    var expectedLength: Int {
        switch self {
        case .Jump, .JumpOnCarry, .JumpOnZero, .LoadA, .StoreA:
            3
        case .Calculate, .SetA:
            2
        case .Halt, .NoOp, .Out, .OutCommand, .SetAFromC, .SetAFromD, .SetAFromE, .SetBFromA, .SetCFromA, .SetDFromA, .SetEFromA, .PushA, .PopA, .SwapAC, .SwapAD, .PushE, .PopE:
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
            
        case .SetAFromC: [
            [.regCOut, .regAIn]
        ]
            
        case .SwapAC: [
            [.regAOut, .regEIn],
            [.regCOut, .regAIn],
            [.regEOut, .regCIn]
        ]
            
        case .SwapAD: [
            [.regAOut, .regEIn],
            [.regDOut, .regAIn],
            [.regEOut, .regDIn]
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
            [.regAOut, .stackDecrement]
            // TODO
        ]
            
        case .PopA: [
            [.regAIn, .stackIncrement]
            // TODO
        ]
            
        case .PushE: [
            [.regEOut, .stackDecrement]
            // TODO
        ]
            
        case .PopE: [
            [.regEIn, .stackIncrement]
            // TODO
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
        case .Halt, .NoOp, .Out, .OutCommand, .SetAFromC, .SwapAC, .SetAFromD, .SwapAD, .SetAFromE, .SetBFromA, .SetCFromA, .SetDFromA, .SetEFromA, .PushA, .PopA, .PushE, .PopE: break

        case let .Jump(location),
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

        if bytes.count == expectedLength {
            return bytes
        }

        throw "Command \(name) requires a parameter"
    }

    func updatedOrg(from original: Int) -> Int {
        original + expectedLength
    }
}
