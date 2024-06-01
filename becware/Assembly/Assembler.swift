import Foundation

enum Assembler {
    static func assemble(to host: String, port: Int, @InstructionBuilder opcodeBlock: () -> [Assemblable]) async throws {
        let bytes = try assemble(opcodeBlock: opcodeBlock)
        print("Sending assembled bytes to \(host):\(port) -- ", terminator: "")

        var inputStream: InputStream?
        var outputStream: OutputStream?
        Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        guard let inputStream, let outputStream else {
            print("Error: Could not create streams")
            return
        }

        print("Connecting..", terminator: "")

        inputStream.open()
        defer {
            inputStream.close()
        }

        var ready = false
        while !ready {
            switch inputStream.streamStatus {
            case .notOpen:
                print("Not open")
            case .opening:
                print(".", terminator: "")
            case .open:
                print("Connected", terminator: "… ")
                ready = true
            case .reading:
                print("Reading")
            case .writing:
                print("Writing")
            case .atEnd:
                print("At End")
            case .closed:
                print("Closed")
            case .error:
                print("Error Connecting")
                return
            @unknown default:
                fatalError()
            }
            try? await Task.sleep(for: .seconds(1))
        }

        let readyBytes = malloc(8)!
        var count = 0
        while count < 8 {
            count += inputStream.read(readyBytes, maxLength: 8 - count) // ready line
        }
        let readyMessage = String(unsafeUninitializedCapacity: 8) { buffer in
            memcpy(buffer.baseAddress!, readyBytes, 8)
            return 8
        }
        if readyMessage == "\nREADY> " {
            print("Got ready state", terminator: "… ")
        } else {
            print("Error: Did not get READY header")
            return
        }

        Task.detached { [outputStream] in
            outputStream.open()
            print("Sending \(bytes.count) bytes.")

            for byte in bytes {
                let byteString = formatted(byte, radix: 16, max: 2) + " "
                outputStream.write(text: byteString)
            }
            outputStream.write(text: "\n")
            outputStream.close()
        }

        while true {
            let text = String(unsafeUninitializedCapacity: 1024) { buf in
                inputStream.read(buf.baseAddress!, maxLength: 1024)
            }
            if text.count == 0 {
                break
            }
            print(text, terminator: "")
            if text.contains(">") {
                break
            }
        }
        print()
        print()
        print("Done")
        print()
    }

    static func assemble(to file: String, @InstructionBuilder opcodeBlock: () -> [Assemblable]) throws {
        let bytes = try assemble(opcodeBlock: opcodeBlock)
        print("Writing assembled bytes… ", terminator: "")
        try bytes.write(to: home.appendingPathComponent(file))
        print("Done")
        print()
    }

    static func assemble(@InstructionBuilder opcodeBlock: () -> [Assemblable]) throws -> Data {
        print("Assembling: ")
        print()

        var parseState = ParseState(labels: [:])
        var len = 0
        let opcodes = opcodeBlock()

        for opcode in opcodes {
            if let label = opcode.label {
                parseState.labels[label] = UInt16(len)
                print("   Label `\(label)` -> ", terminator: "")
                print(formatted(len, radix: 16, max: 4).uppercased())
            }
            len = opcode.updatedOrg(from: len)
        }
        if !parseState.labels.isEmpty {
            print()
        }

        var bytes = Data(repeating: 0, count: len)
        var org = 0
        for opcode in opcodes {
            let assembledBytes = try opcode.bytes(with: parseState)
            if !assembledBytes.isEmpty {
                print("  ", formatted(org, radix: 16, max: 4).uppercased(), terminator: ": ")
            }

            for byte in assembledBytes.enumerated() {
                print("[", terminator: "")
                print(formatted(byte.element, radix: 16, max: 2).uppercased(), terminator: "] ")
                let address = org + byte.offset
                bytes[address] = byte.element
            }

            if !assembledBytes.isEmpty {
                print()
            }

            org = opcode.updatedOrg(from: org)
        }

        print()
        return bytes
    }
}
