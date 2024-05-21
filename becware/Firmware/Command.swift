import Foundation

enum Command: Int, CaseIterable {
    case NOP  = 0b0000,
         LDA  = 0b0001, // Load A              Address to load into A
         LDB  = 0b0010, // Load B              Address to load into B
         CALC = 0b0011, // Calculate           Set ALU function and store result in A
         STOR = 0b0100, // Store into Address  Address to store the contents of A
         LDI  = 0b0101, // Load immediate      Value to set A
         JMP  = 0b0110, // Jump                Address to jump to
         JC   = 0b0111, // Jump on carry       Address to jump to
         JZ   = 0b1000, // Jump on zero        Address to jump to

         OUT  = 0b1110, // Display A           (no args)
         HALT = 0b1111  // Halt                (no args)

    var name: String {
        switch self {
        case .NOP: "NOP"
        case .CALC: "CALC"
        case .HALT: "HALT"
        case .LDA: "LDA"
        case .LDB: "LDB"
        case .OUT: "OUT"
        case .STOR: "STOR"
        case .LDI: "LDI"
        case .JMP: "JMP"
        case .JC: "JC"
        case .JZ: "JZ"
        }
    }

    var byte: UInt8 {
        UInt8(rawValue)
    }

    var takesParam: Bool {
        switch self {
        case .CALC, .JC, .JMP, .JZ, .LDA, .LDB, .LDI, .STOR:
            true
        case .HALT, .NOP, .OUT:
            false
        }
    }

    private static let instructionFetch: [[Microcode]] = [
        [.addressIn, .counterOut],
        [.ramOut, .instructionIn, .counterIncrement]
    ]

    private static let parameterFetch: [[Microcode]] = [
        [.addressIn, .counterOut],
        [.ramOut, .argumentIn, .counterIncrement]
    ]

    private static let next: [[Microcode]] = [
        [.nextCommand]
    ]

    private func specificSteps(for flags: Flag) -> [[Microcode]] {
        switch self {
        case .NOP: [
            ]

        case .LDA: [
                [.addressIn, .argumentOut],
                [.ramOut, .regAIn]
            ]

        case .LDB: [
                [.addressIn, .argumentOut],
                [.ramOut, .regBIn]
            ]

        case .CALC: [
                [.calcIn, .argumentOut],
                [.regAIn, .calcOut, .flagsIn]
            ]

        case .OUT: [
                [.regAOut, .displayIn]
            ]

        case .LDI: [
                [.argumentOut, .regAIn]
            ]

        case .HALT: [
                [.halt]
            ]

        case .STOR: [
                [.addressIn, .argumentOut],
                [.regAOut, .ramIn]
            ]

        case .JMP: [
                [.argumentOut, .counterIn]
            ]

        case .JC:
            flags.contains(.carry) ? [[.argumentOut, .counterIn]] : []

        case .JZ:
            flags.contains(.zero) ? [[.argumentOut, .counterIn]] : []
        }
    }

    func steps(for flags: Flag) -> [[Microcode]] {
        (Self.instructionFetch
            + (takesParam ? Self.parameterFetch : [])
            + specificSteps(for: flags)
            + Self.next).filter { !$0.isEmpty }
    }
}
