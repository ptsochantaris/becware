import Foundation

// TODO:
// Stack
// Random Generator

// Build EEPROM files
Firmware.build()

// Example Code to display characters on an LCD screen

/*
// Using RAM for storage

 do {
     try await Assembler.assemble(to: "192.168.1.218", port: 80) {
         Command.SetA(number: 1)
         Command.SetBFromA

         Command.SetA(number: 0b00100000 | 0b00011000)  // 8 bit mode, 2 lines, 5x8 font
         Command.OutCommand
         Command.SetA(number: 0b00001000 | 0b00000111)  // display on, cursor on, blink
         Command.OutCommand
         Command.SetA(number: 0b00000100 | 0b00000010)  // increment cursor when writing, do not shift display
         Command.OutCommand
         Command.SetA(number: 0b00000001)               // boot
         Command.OutCommand

         Label("Start")

         Command.SetA(number: 33)
         Command.StoreA(to: .address(11000))

         Command.SetA(number: 96)
         Command.StoreA(to: .address(12000))

         Label("Loop")
         Command.LoadA(from: .address(11000))
         Command.Out
         Command.Calculate(using: .addition)
         Command.StoreA(to: .address(11000))

         Command.LoadA(from: .address(12000))

         Command.SetCFromA
         Command.SetDFromA
         Command.SetEFromA

         Command.Calculate(using: .subtraction)
         Command.JumpOnZero(to: .label("Start"))
         Command.StoreA(to: .address(12000))

         Command.Jump(to: .label("Loop"))
     }
 } catch {
     print("Assembly error: \(error.localizedDescription)")
 }
*/

// Using registers
do {
    try await Assembler.assemble(to: "192.168.1.218", port: 80) {
        Command.SetA(number: 1)
        Command.SetBFromA

        Command.SetA(number: 0b0010_0000 | 0b0001_1000) // 8 bit mode, 2 lines, 5x8 font
        Command.OutCommand
        Command.SetA(number: 0b0000_1000 | 0b0000_0111) // display on, cursor on, blink
        Command.OutCommand
        Command.SetA(number: 0b0000_0100 | 0b0000_0010) // increment cursor when writing, do not shift display
        Command.OutCommand
        Command.SetA(number: 0b0000_0001) // boot
        Command.OutCommand

        Label("Start")

        Command.SetA(number: 33)
        Command.SetCFromA
        Command.SetA(number: 96)
        Command.SetDFromA

        Label("Loop")

        Command.SetAFromC
        Command.Out
        Command.Calculate(using: .addition)
        Command.SetCFromA

        Command.SetAFromD
        Command.Calculate(using: .subtraction)
        Command.JumpOnZero(to: .label("Start"))
        Command.SetDFromA

        Command.Jump(to: .label("Loop"))
    }
} catch {
    print("Assembly error: \(error.localizedDescription)")
}

/*
// Testing register swapping
do {
     try await Assembler.assemble(to: "192.168.1.218", port: 80) {
         Command.SetA(number: 0b11111111)
         Label("Loop")
         Command.SwapAB
         Command.SwapAB
         Command.SwapAC
         Command.SwapAC
         Command.SwapAD
         Command.SwapAD
         Command.SwapAE
         Command.SwapAE
         Command.Jump(to: .label("Loop"))
     }
} catch {
    print("Assembly error: \(error.localizedDescription)")
}
*/

/*
// Testing register assignment
do {
     try await Assembler.assemble(to: "192.168.1.218", port: 80) {
         Command.SetA(number: 0b11111111)
         Label("Loop")
         Command.SetBFromA
         Command.SetA(number: 0)
         Command.SetAFromB
         Command.Jump(to: .label("Loop"))
     }
} catch {
    print("Assembly error: \(error.localizedDescription)")
}
*/

/*
// Testing conditional jump
do {
    try await Assembler.assemble(to: "192.168.1.218", port: 80) {
        Command.SetA(number: 0b1)
        Command.SetBFromA
        Command.SetA(number: 0b11111100)
        Label("Loop")
        Command.Calculate(using: .addition)
        Command.JumpOnCarry(to: .label("End"))
        Command.Jump(to: .label("Loop"))
        Label("End")
        Command.Halt
    }
} catch {
    print("Assembly error: \(error.localizedDescription)")
}
*/

/*
// Testing stack push and pop
do {
    try await Assembler.assemble(to: "192.168.1.218", port: 80) {
        Command.PushA

        Command.SetA(number: 1)
        Command.SetBFromA
        Command.PushA

        Command.Calculate(using: .addition)
        Command.PushA

        Command.Calculate(using: .addition)
        Command.PushA

        Command.Calculate(using: .addition)
        Command.PushA

        Command.Calculate(using: .addition)
        Command.PushA

        Command.Calculate(using: .addition)
        Command.PushA

        Command.Calculate(using: .addition)
        Command.PushA

        Command.Calculate(using: .addition)
        Command.PushA

        Command.Calculate(using: .addition)
        Command.PushA

        Command.PopA
        Command.PopA
        Command.PopA
        Command.PopA
        Command.PopA
        Command.PopA
        Command.PopA
        Command.PopA
        Command.PopA
        Command.PopA

        Command.Halt
    }
} catch {
    print("Assembly error: \(error.localizedDescription)")
}
*/

/*
// Call and ret testing
do {
    try await Assembler.assemble(to: "192.168.1.218", port: 80) {
        Command.Call(to: .label("LcdInit"))

        Command.SetA(number: 1)
        Command.SetBFromA

        Label("Start")

        Command.SetA(number: 33)
        Command.SetCFromA
        Command.SetA(number: 96)
        Command.SetDFromA

        Label("Loop")

        Command.SetAFromC
        Command.Out
        Command.Calculate(using: .addition)
        Command.SetCFromA

        Command.SetAFromD
        Command.Calculate(using: .subtraction)
        Command.JumpOnZero(to: .label("Start"))
        Command.SetDFromA

        Command.Jump(to: .label("Loop"))

        Label("LcdInit")
        Command.SetA(number: 0b0010_0000 | 0b0001_1000) // 8 bit mode, 2 lines, 5x8 font
        Command.OutCommand
        Command.SetA(number: 0b0000_1000 | 0b0000_0111) // display on, cursor on, blink
        Command.OutCommand
        Command.SetA(number: 0b0000_0100 | 0b0000_0010) // increment cursor when writing, do not shift display
        Command.OutCommand
        Command.SetA(number: 0b0000_0001) // boot
        Command.OutCommand
        Command.Return
    }
} catch {
    print("Assembly error: \(error.localizedDescription)")
}
*/
