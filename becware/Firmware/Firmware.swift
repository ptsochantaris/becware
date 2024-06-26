import Foundation

enum Firmware {
    private static func byte(for flagSet: Flag) -> UInt8 {
        var base: UInt8 = 0
        if flagSet.contains(.zero) {
            base |= 0b10
        }
        if flagSet.contains(.carry) {
            base |= 0b01
        }
        return base
    }

    private static func bytes(for steps: [Signal]) -> (UInt8, UInt8, UInt8, UInt8, UInt8) {
        var zeroByte: UInt8 = 0
        var firstByte: UInt8 = 0
        var secondByte: UInt8 = 0
        var thirdByte: UInt8 = 0
        var fourthByte: UInt8 = 0
        for step in steps {
            switch step.bit {
            case let .zero(bit):
                zeroByte |= 1 << bit
            case let .one(bit):
                firstByte |= 1 << bit
            case let .two(bit):
                secondByte |= 1 << bit
            case let .three(bit):
                thirdByte |= 1 << bit
            case let .four(bit):
                fourthByte |= 1 << bit
            }
        }
        return (zeroByte, firstByte, secondByte, thirdByte, fourthByte)
    }

    static func build() {
        print("BEC1 Firmware - Controller")
        print()

        let commandBitCount = 5
        let stepBitCount = 4
        let flagBitCount = 2
        let bits = commandBitCount + stepBitCount + flagBitCount
        let total = 1 << bits

        var data0 = Data(repeating: 0, count: total)
        var data1 = Data(repeating: 0, count: total)
        var data2 = Data(repeating: 0, count: total)
        var data3 = Data(repeating: 0, count: total)
        var data4 = Data(repeating: 0, count: total)

        for command in Command.allCases {
            print(command.name, formatted(command.byte, radix: 2, max: commandBitCount))

            let flagSets: [Flag] = [[], .carry, .zero, [.carry, .zero]]
            for flagSet in flagSets {
                if !flagSet.isEmpty {
                    print("Flags: \(flagSet.name)")
                }
                let flagBase = Int(byte(for: flagSet)) << (commandBitCount + stepBitCount)
                let commandBase = Int(command.byte) << stepBitCount
                for stepBlock in command.steps(for: flagSet).enumerated() {
                    let address = flagBase | commandBase | stepBlock.offset

                    (data0[address], data1[address], data2[address], data3[address], data4[address]) = bytes(for: stepBlock.element)

                    print(formatted(address, radix: 2, max: bits), terminator: ": ")
                    print(formatted(data0[address], radix: 2, max: 8), terminator: "  ")
                    print(formatted(data1[address], radix: 2, max: 8), terminator: "  ")
                    print(formatted(data2[address], radix: 2, max: 8), terminator: "  ")
                    print(formatted(data3[address], radix: 2, max: 8), terminator: "  ")
                    print(formatted(data4[address], radix: 2, max: 8), terminator: " - ")
                    print(stepBlock.element.map(\.rawValue).joined(separator: ", "))
                }
            }

            print()
        }

        /*
         for index in stride(from: 0, to: total, by: 8) {
             print(formatted(index, radix: 2, max: bits), terminator: ": ")

             for array in [data0, data1, data2, data3, data4] {
                 for i in index ..< index + 8 {
                     print(formatted(array[i], radix: 16, max: 2), terminator: " ")
                 }
                 print(" ", terminator: "")
             }

             print()
         }
          */

        print()
        print("Writing data files… ", terminator: "")
        do {
            try data0.write(to: home.appendingPathComponent("control0.bin"))
            try data1.write(to: home.appendingPathComponent("control1.bin"))
            try data2.write(to: home.appendingPathComponent("control2.bin"))
            try data3.write(to: home.appendingPathComponent("control3.bin"))
            try data4.write(to: home.appendingPathComponent("control4.bin"))
            print("Done")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        print()
    }
}
