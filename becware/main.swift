import Foundation

let firmware = Firmware()
firmware.build()

do {
    try firmware.assemble(to: "assembled.bin") {
        Org(org: 0)

        Opcode(.LDA, .location("startValue"))
        Opcode(.LDB, .location("one"))
        Opcode(.OUT)

        Label("Ascending")
        Opcode(.CALC, .addition)
        Opcode(.JC, .location("Descending"))
        Opcode(.OUT)
        Opcode(.JMP, .location("Ascending"))

        Label("Descending")
        Opcode(.CALC, .subtraction)
        Opcode(.OUT)
        Opcode(.JZ, .location("Ascending"))
        Opcode(.JMP, .location("Descending"))

        Label("one")
        Content(bytes: [1])

        Label("startValue")
        Content(bytes: [0])
    }
} catch {
    print("Assembly error: \(error.localizedDescription)")
}
