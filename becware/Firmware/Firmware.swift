import Foundation

final class Firmware {
    private func bytes(for steps: [Microcode]) -> (UInt8, UInt8, UInt8) {
        var firstByte: UInt8 = 0
        var secondByte: UInt8 = 0
        var thirdByte: UInt8 = 0
        for c in steps {
            switch c.bit {
            case let .one(bit):
                firstByte |= 1 << bit
            case let .two(bit):
                secondByte |= 1 << bit
            case let .three(bit):
                thirdByte |= 1 << bit
            }
        }
        return (firstByte, secondByte, thirdByte)
    }

    private func printBinary(at i: Int) {
        print(formatted(i, radix: 2, max: Self.bits), terminator: ": ")
        print(formatted(data1[i], radix: 2, max: 8), terminator: "  ")
        print(formatted(data2[i], radix: 2, max: 8), terminator: "  ")
        print(formatted(data3[i], radix: 2, max: 8))
    }

    private static let commandBitCount = 4
    private static let stepBitCount = 4
    private static let flagBitCount = 2
    private static let bits = commandBitCount + stepBitCount + flagBitCount
    private static let total = 1 << bits

    private var data1 = Data(repeating: 0, count: total)
    private var data2 = Data(repeating: 0, count: total)
    private var data3 = Data(repeating: 0, count: total)

    private func byte(for flagSet: Flag) -> UInt8 {
        var base: UInt8 = 0
        if flagSet.contains(.zero) {
            base |= 0b10
        }
        if flagSet.contains(.carry) {
            base |= 0b01
        }
        return base
    }

    func build() {
        print("BEC1 Firmware - Controller")
        print()

        for command in Command.allCases {
            print("Adding", command.name, formatted(command.byte, radix: 2, max: Self.commandBitCount))

            let flagSets: [Flag] = [[], .carry, .zero, [.carry, .zero]]
            for flagSet in flagSets {
                if !flagSet.isEmpty {
                    print("Flags: \(flagSet.name)")
                }
                let flagBase = Int(byte(for: flagSet)) << (Self.commandBitCount + Self.stepBitCount)
                let commandBase = Int(command.byte) << Self.stepBitCount
                for stepBlock in command.steps(for: flagSet).enumerated() {
                    let address = flagBase | commandBase | stepBlock.offset

                    (data1[address], data2[address], data3[address]) = bytes(for: stepBlock.element)

                    printBinary(at: address)
                }
            }

            print()
        }

        for index in stride(from: 0, to: Self.total, by: 8) {
            print(formatted(index, radix: 2, max: Self.bits), terminator: ": ")

            for array in [data1, data2, data3] {
                for i in index ..< index + 8 {
                    print(formatted(array[i], radix: 16, max: 2), terminator: " ")
                }
                print(" ", terminator: "")
            }

            print()
        }

        print()
        print("Writing data files… ", terminator: "")
        do {
            try data1.write(to: home.appendingPathComponent("control1.bin"))
            try data2.write(to: home.appendingPathComponent("control2.bin"))
            try data3.write(to: home.appendingPathComponent("control3.bin"))
            print("Done")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        print()
    }

    func assemble(to file: String, @InstructionBuilder opcodeBlock: () -> [Assemblable]) throws {
        print("Assembling: ")
        print()

        var parseState = ParseState(labels: [:])
        var org: UInt16 = 0
        let opcodes = opcodeBlock()

        for opcode in opcodes {
            if let label = opcode.label {
                parseState.labels[label] = org
                print("   Label `\(label)` -> ", terminator: "")
                print(formatted(org, radix: 16, max: 2).uppercased())
            }
            org = opcode.updatedOrg(from: org)
        }
        if !parseState.labels.isEmpty {
            print()
        }

        var bytes = Data(repeating: 0, count: Int(org))
        org = 0
        for opcode in opcodes {
            let assembledBytes = try opcode.bytes(with: parseState)
            if !assembledBytes.isEmpty {
                print("  ", formatted(org, radix: 16, max: 2).uppercased(), terminator: ": ")
            }

            for byte in assembledBytes.enumerated() {
                print("[", terminator: "")
                print(formatted(byte.element, radix: 16, max: 2).uppercased(), terminator: "] ")
                let address = Int(org) + byte.offset
                bytes[address] = byte.element
            }

            if !assembledBytes.isEmpty {
                print()
            }

            org = opcode.updatedOrg(from: org)
        }

        print()
        print("Binary:")
        print()
        for byte in bytes {
            print(formatted(byte, radix: 16, max: 2).uppercased(), terminator: " ")
        }

        print()
        print()
        print("Writing assembled bytes… ", terminator: "")
        try bytes.write(to: home.appendingPathComponent(file))
        print("Done")
        print()
    }
}
