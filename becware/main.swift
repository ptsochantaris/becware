import Foundation

let firmware = Firmware()

firmware.build()

do {
    try firmware.assemble(to: "assembled.bin") {
        Org(0)

        Command.LoadA(from: .label("startValue"))
        Command.LoadB(from: .label("one"))
        Command.Out

        Label("Ascending")
        Command.Calculate(using: .addition)
        Command.JumpOnCarry(to: .label("Descending"))
        Command.Out
        Command.Jump(to: .label("Ascending"))

        Label("Descending")
        Command.Calculate(using: .subtraction)
        Command.Out
        Command.JumpOnZero(to: .label("Ascending"))
        Command.Jump(to: .label("Descending"))

        Label("one")
        Content(bytes: [1])

        Label("startValue")
        Content(bytes: [0])
    }
} catch {
    print("Assembly error: \(error.localizedDescription)")
}
