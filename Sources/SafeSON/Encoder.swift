import Foundation

public class SSEncoder {
    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let ss = SSEncoderImpl()
        try value.encode(to: ss)
        return ss.data.rleEncode()
    }
}

struct SSEncoderImpl: Encoder {
    fileprivate var container: DataContainer

    init(_ container: DataContainer = DataContainer()) {
        self.container = container
    }

    var codingPath: [CodingKey] = []

    let userInfo: [CodingUserInfoKey: Any] = [:]

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        var container = SSKeyedEncoding<Key>(container)
        container.codingPath = codingPath
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        var container = SSUnkeyedEncoding(container)
        container.codingPath = codingPath
        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        var container = SSSingleValueEncoding(container)
        container.codingPath = codingPath
        return container
    }

    var data: Data {
        container.data
    }
}

struct SSKeyedEncoding<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] = []

    private var count = 0

    private var container: DataContainer

    private var singleValueEncoding: SSSingleValueEncoding

    private var lengthOffset: Int

    init(_ container: DataContainer) {
        self.container = container
        container.writeType(.object)
        container.writeLength(count)

        singleValueEncoding = SSSingleValueEncoding(container)
        lengthOffset = container.data.count - 1
    }

    private mutating func encodeKey(_ key: Key) throws {
        let previousLength = count
        count += 1
        container.writeLength(count, at: lengthOffset, withPreviousLength: previousLength)
        let keyRepr = (codingPath + [key]).map({ $0.stringValue }).joined(separator: ".")
        container.writeString(keyRepr)
    }

    mutating func encodeNil(forKey key: Key) throws {
        try encodeKey(key)
        try singleValueEncoding.encodeNil()
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        try encodeKey(key)
        try singleValueEncoding.encode(value)
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        var container = SSKeyedEncoding<NestedKey>(container)
        container.codingPath = codingPath + [key]
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        var container = SSUnkeyedEncoding(container)
        container.codingPath = codingPath + [key]
        return container
    }

    mutating func superEncoder() -> Encoder {
        var stringsEncoding = SSEncoderImpl(container)
        stringsEncoding.codingPath = codingPath
        return stringsEncoding
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        var stringsEncoding = SSEncoderImpl(container)
        stringsEncoding.codingPath = codingPath + [key]
        return stringsEncoding
    }
}

struct SSUnkeyedEncoding: UnkeyedEncodingContainer {
    private var container: DataContainer

    private var singleValueEncoding: SSSingleValueEncoding

    private var lengthOffset: Int

    init(_ container: DataContainer) {
        self.container = container
        container.writeType(.array)
        container.writeLength(0)

        singleValueEncoding = SSSingleValueEncoding(container)
        lengthOffset = container.data.count - 1
    }

    var codingPath: [CodingKey] = []

    private(set) var count = 0

    private var items = 0 as Float64

    mutating func increment() {
        let previousLength = count
        count += 1
        container.writeLength(count, at: lengthOffset, withPreviousLength: previousLength)
    }

    mutating func encodeNil() throws {
        increment()
        try singleValueEncoding.encodeNil()
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        increment()
        try singleValueEncoding.encode(value)
    }

    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type)
        -> KeyedEncodingContainer<NestedKey>
    {
        let container = SSKeyedEncoding<NestedKey>(container)
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return SSUnkeyedEncoding(container)
    }

    mutating func superEncoder() -> Encoder {
        return SSEncoderImpl(container)
    }
}

struct SSSingleValueEncoding: SingleValueEncodingContainer {
    var codingPath: [CodingKey] = []

    var container: DataContainer

    init(_ container: DataContainer) {
        self.container = container
    }

    mutating func encodeNil() throws {
        container.writeType(.null)
    }

    mutating func encode(_ value: Bool) throws {
        if value {
            container.writeType(.true$)
        } else {
            container.writeType(.false$)
        }
    }

    mutating func encode(_ value: String) throws {
        container.writeType(.string)
        container.writeString(value)
    }

    mutating func encode(_ value: Double) throws {
        container.writeType(.number)
        container.writeNumber(value)
    }

    mutating func encode(_ value: Float) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: Int) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: Int8) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: Int16) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: Int32) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: Int64) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: UInt) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: UInt8) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: UInt16) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: UInt32) throws {
        try encode(Float64(value))
    }

    mutating func encode(_ value: UInt64) throws {
        try encode(Float64(value))
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        var ss = SSEncoderImpl(container)
        ss.codingPath = codingPath
        try value.encode(to: ss)
    }
}
