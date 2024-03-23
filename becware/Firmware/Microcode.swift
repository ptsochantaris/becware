import Foundation

enum Microcode {
    case halt
    case addressIn
    case ramIn
    case ramOut
    case instructionIn
    case argumentIn
    case argumentOut
    case regAIn
    case regAOut
    case regBIn
    case flagsIn
    case calcIn
    case calcOut
    case displayIn
    case counterIn
    case counterOut
    case counterIncrement
    case nextCommand

    enum Bit {
        case one(Int), two(Int), three(Int)
    }

    var bit: Bit {
        switch self {
        case .halt: .one(0)
        case .addressIn: .one(1)
        case .ramIn: .one(2)
        case .ramOut: .one(3)
        case .instructionIn: .one(4)
        case .argumentIn: .one(5)
        case .argumentOut: .one(6)

        case .calcOut: .two(0)
        case .calcIn: .two(1)
        case .displayIn: .two(2)
        case .counterIncrement: .two(3)
        case .counterOut: .two(4)
        case .counterIn: .two(5)

        case .regAIn: .three(0)
        case .regAOut: .three(1)
        case .regBIn: .three(2)
        case .flagsIn: .three(3)
        case .nextCommand: .three(4)
        }
    }
}
