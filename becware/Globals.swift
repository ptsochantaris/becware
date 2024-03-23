import Foundation

extension String: Error {}

func fixedWidthRepresentation(of val: some FixedWidthInteger, radix: Int, max: Int) -> String {
    let binaryString = String(val, radix: radix)
    return String((String(repeating: "0", count: val.leadingZeroBitCount) + binaryString).suffix(max))
}

let home = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
