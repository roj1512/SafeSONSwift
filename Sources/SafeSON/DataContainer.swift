import Foundation

class DataContainer {
    private var data_: Data

    var data: Data {
        get {
            data_
        }
    }

    init(_ data: Data = Data()) {
        self.data_ = data
    }

    func writeType(_ type: SSType) {
        data_.append(type.rawValue)
    }

    func writeNumber(_ number: Float64) {
        var numberCopy = number
        let bytes = withUnsafeBytes(of: &numberCopy) { Data($0) }
        data_.append(bytes)
    }

    func writeNumber(_ number: any BinaryInteger) {
        writeNumber(Float64(number))
    }
    
    func writeLength(_ length: Int) {
        if length <= 254 {
            data_.append(contentsOf: [UInt8(length)])
        } else {
            data_.append(contentsOf: [255])
            writeNumber(Float64(length))
        }
    }

    func writeLength(_ length: Int, at offset: Int, withPreviousLength previousLength: Int) {
        if length <= 254 {
            data_[offset] = UInt8(length)
        } else {
            var numberCopy = Float64(length)
            let bytes = withUnsafeBytes(of: &numberCopy) { Data($0) }
            if previousLength <= 254 {
                data_[offset] = 255
                data_.insert(contentsOf: bytes, at: offset+1)
            } else {
                data_.replaceSubrange(offset+1..<offset+9, with: bytes)
            }
        }
    }

    func writeString(_ string: String) {
        writeLength(string.lengthOfBytes(using: .utf8))
        data_.append(Data(string.utf8))
    }

    fileprivate func read(_ amount: Int) throws -> Data {
        var data = Data()
        for _ in 0..<amount {
            if let byte = self.data_.popFirst() {
                data.append(byte)
            } else {
                throw SSDecodingError.dataCorrupted
            }
        }
        return data
    }
    
    func readByte() throws -> UInt8 {
        try read(1)[0]
    }

    func readNumberAndBytes() throws -> (Float64, Data) {
        let bytes = try read(8)
        return (bytes.withUnsafeBytes({ $0.load(as: Float64.self) }), bytes)
    }

    func readNumber() throws -> Float64 {
        try readNumberAndBytes().0
    }
    
    func readLengthAndBytes() throws -> (Int, Data) {
        let b = try read(1)
        if b[0] <= 254 {
            return (Int(b[0]), b)
        } else {
            let (f, n) = try readNumberAndBytes()
            if f < 0 || f.truncatingRemainder(dividingBy: 1) != 0 {
                throw SSDecodingError.invalidLength
            } else {
                return (Int(f), b + n)
            }
        }
    }
    
    func readLength() throws -> Int {
        try readLengthAndBytes().0
    }

    func readString() throws -> String {
        let length = try readLength()
        if let string = String(data: try read(length), encoding: .utf8) {
            return string
        } else {
            throw SSDecodingError.dataCorrupted
        }
    }

    func collect() throws -> Data {
        var data = try read(1)
        switch SSType(rawValue: data[0]) {
        case .false$, .true$, .null:
            break
        case .number:
            data.append(try read(8))
        case .string:
            let (length, lengthBytes) = try readLengthAndBytes()
            data.append(lengthBytes)
            data.append(try read(length))
        case .array:
            let (length, lengthBytes) = try readLengthAndBytes()
            data.append(lengthBytes)
            for _ in 0..<length {
                data.append(try collect())
            }
        case .object:
            let (length, lengthBytes) = try readLengthAndBytes()
            data.append(lengthBytes)
            for _ in 0..<length {
                let lengthBytes = try read(8)
                let length = Int(lengthBytes.withUnsafeBytes { $0.load(as: Float64.self) })
                data.append(lengthBytes)
                data.append(try read(length))
                data.append(try collect())
            }
        default:
            throw SSDecodingError.dataCorrupted
        }

        return data
    }
}
