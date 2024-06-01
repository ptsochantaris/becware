import Foundation

extension OutputStream: @unchecked Sendable {}

extension OutputStream {
    func write(text: String) {
        text.utf8CString.withUnsafeBytes { buffer in
            let count = buffer.count - 1
            var offset = 0
            while offset < count {
                offset += write(buffer.baseAddress! + offset, maxLength: count - offset)
            }
        }
    }
}
