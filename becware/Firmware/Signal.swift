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
    case regBOut
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
    case regIIn
    case regIOut
    case stackIncrement
    case stackDecrement
    case stackHOut
    case stackLOut

    enum Bit {
        case zero(Int), one(Int), two(Int), three(Int), four(Int)
    }

    var bit: Bit {
        switch self {
        case .regIIn: .zero(0)
        case .regIOut: .zero(1)
        case .stackHOut: .zero(4)
        case .stackLOut: .zero(5)
        case .stackIncrement: .zero(6)
        case .stackDecrement: .zero(7)
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
        case .regBOut: .three(7)
        case .regCIn: .four(0)
        case .regCOut: .four(1)
        case .regDIn: .four(2)
        case .regDOut: .four(3)
        case .regEIn: .four(4)
        case .regEOut: .four(5)
        case .flagsIn: .four(7)
        }
    }
}
