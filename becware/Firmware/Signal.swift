import Foundation

enum Signal: String {
    case halt
    case addressHIn
    case addressLIn
    case ramIn
    case ramOut
    case instructionIn
    case argumentHIn
    case argumentHOut
    case argumentLIn
    case argumentLOut
    case regAIn
    case regAOut
    case regBIn
    case flagsIn
    case calcIn
    case calcOut
    case displayIn
    case displaySelect
    case counterLIn
    case counterHIn
    case counterLOut
    case counterHOut
    case counterIncrement
    case nextCommand
    case regCIn
    case regCOut
    case regDIn
    case regDOut
    case regEIn
    case regEOut
    case stackIncrement
    case stackDecrement

    enum Bit {
        case one(Int), two(Int), three(Int), four(Int)
    }

    var bit: Bit {
        switch self {
        case .halt: .one(0)
        case .instructionIn: .one(1)
        case .addressLIn: .one(2)
        case .addressHIn: .one(3)
        case .ramIn: .one(4)
        case .ramOut: .one(5)
        case .argumentLIn: .one(6)
        case .argumentLOut: .one(7)

        case .calcOut: .two(0)
        case .calcIn: .two(1)
        case .argumentHIn: .two(2)
        case .argumentHOut: .two(3)
        case .displayIn: .two(4)
        case .displaySelect: .two(5)
        case .counterIncrement: .two(6)
        case .nextCommand: .two(7)

        case .counterHIn: .three(0)
        case .counterHOut: .three(1)
        case .counterLIn: .three(2)
        case .counterLOut: .three(3)
        case .regAIn: .three(4)
        case .regAOut: .three(5)
        case .regBIn: .three(6)
        case .flagsIn: .three(7)

        case .regCIn: .three(0)
        case .regCOut: .three(1)
        case .regDIn: .three(2)
        case .regDOut: .three(3)
        case .regEIn: .three(4)
        case .regEOut: .three(5)
        case .stackIncrement: .three(6)
        case .stackDecrement: .three(7)
        }
    }
}
