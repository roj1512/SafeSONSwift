import Foundation

public class SSDecoder {
  public init() {}

  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let ss = try SSDecoderImpl(data.rleDecode().getContainer())
    return try ss.singleValueContainer().decode(type)
  }
}

public enum SSDecodingError: Error {
  case dataCorrupted
  case expectedNull
  case invalidLength
  case invalidType(actual: UInt8?, expectedOneOf: [UInt8])
}

public struct SSUndecodedValue: Codable {  // Must not be encoded. Must be decoded only using SSDecoder.
  public let data: Data

  init(data: Data) {
    self.data = data
  }
}

struct SSDecoderImpl: Decoder {
  var codingPath: [CodingKey] = []

  var userInfo: [CodingUserInfoKey: Any] = [:]

  var container: DataContainer

  init(_ container: DataContainer) throws {
    self.container = container
  }

  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
  where Key: CodingKey {
    var container = try SSKeyedDecoding<Key>(container)
    container.codingPath = codingPath
    return KeyedDecodingContainer(container)
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    var container = try SSUnkeyedDecoding(container)
    container.codingPath = codingPath
    return container
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    var container = SSSingleValueDecoding(container)
    container.codingPath = codingPath
    return container
  }
}

struct SSKeyedDecoding<Key: CodingKey>: KeyedDecodingContainerProtocol {
  var codingPath: [CodingKey] = []

  var allKeys: [Key] = []

  private var container: DataContainer

  private var dataMap: [String: Data] = [:]

  init(_ container: DataContainer) throws {
    self.container = container

    let byte = try container.readByte()
    if byte != SSType.object.rawValue {
      throw SSDecodingError.invalidType(
        actual: byte, expectedOneOf: [SSType.object.rawValue])
    }

    let length = try container.readLength()
    for _ in 0..<length {
      let key = try container.readString()
      if let key = Key(stringValue: key) {
        allKeys.append(key)
      }
      let value = try container.collect()
      dataMap[key] = value
    }
  }

  func contains(_ key: Key) -> Bool {
    return dataMap.keys.contains(key.stringValue)
  }

  func decodeNil(forKey key: Key) throws -> Bool {
    let container = DataContainer(dataMap[key.stringValue] ?? Data())
    return SSSingleValueDecoding(container).decodeNil()
  }

  func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
    let container = DataContainer(dataMap[key.stringValue] ?? Data())
    return try SSSingleValueDecoding(container).decode(type)
  }

  func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
    -> KeyedDecodingContainer<NestedKey>
  {
    var container = try SSKeyedDecoding<NestedKey>(container)
    container.codingPath = codingPath + [key]
    return KeyedDecodingContainer(container)
  }

  func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
    var container = try SSUnkeyedDecoding(container)
    container.codingPath = codingPath + [key]
    return container
  }

  func superDecoder() throws -> Decoder {
    var decoder = try SSDecoderImpl(container)
    decoder.codingPath = codingPath
    return decoder
  }

  func superDecoder(forKey key: Key) throws -> Decoder {
    var decoder = try SSDecoderImpl(container)
    decoder.codingPath = codingPath + [key]
    return decoder
  }
}

struct SSUnkeyedDecoding: UnkeyedDecodingContainer {
  var codingPath: [CodingKey] = []

  var count: Int? = nil

  var isAtEnd: Bool = false

  var currentIndex: Int = 0

  var container: DataContainer

  var singleValueDecoding: SSSingleValueDecoding

  init(_ container: DataContainer) throws {
    self.container = container
    let byte = try container.readByte()
    if byte != SSType.array.rawValue {
      throw SSDecodingError.invalidType(
        actual: byte, expectedOneOf: [SSType.array.rawValue])
    }
    count = try container.readLength()
    if count == 0 {
      isAtEnd = true
    }
    singleValueDecoding = SSSingleValueDecoding(container)
  }

  private mutating func increment() {
    if !isAtEnd {
      currentIndex += 1
      if count! == currentIndex {
        isAtEnd = true
      }
    }
  }

  mutating func decodeNil() -> Bool {
    increment()
    return singleValueDecoding.decodeNil()
  }

  mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    increment()
    return try singleValueDecoding.decode(type)
  }

  mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws
    -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey
  {
    var container = try SSKeyedDecoding<NestedKey>(container)
    container.codingPath = codingPath
    return KeyedDecodingContainer(container)
  }

  mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
    var container = try SSUnkeyedDecoding(container)
    container.codingPath = codingPath
    return container
  }

  mutating func superDecoder() throws -> Decoder {
    var decoder = try SSDecoderImpl(container)
    decoder.codingPath = codingPath
    return decoder
  }

}

struct SSSingleValueDecoding: SingleValueDecodingContainer {
  private var container: DataContainer
  var codingPath: [CodingKey] = []

  init(_ container: DataContainer) {
    self.container = container
  }

  func decodeNil() -> Bool {
      if container.data.first == SSType.null.rawValue {
          if let byte = try? container.readByte() {
              if byte == SSType.null.rawValue {
                  return true
              }
          }
          fatalError("UNREACHABLE")
      } else {
          return false
      }
  }

  func decode(_ type: Bool.Type) throws -> Bool {
    let byte = try container.readByte()
    switch byte {
    case SSType.false$.rawValue:
      return false
    case SSType.true$.rawValue:
      return true
    default:
      throw SSDecodingError.invalidType(
        actual: byte,
        expectedOneOf: [SSType.false$.rawValue, SSType.true$.rawValue])
    }
  }

  func decode(_ type: String.Type) throws -> String {
    let byte = try container.readByte()
    if byte != SSType.string.rawValue {
      throw SSDecodingError.invalidType(
        actual: byte, expectedOneOf: [SSType.string.rawValue])
    }
    return try container.readString()
  }

  func decode(_ type: Float64.Type) throws -> Float64 {
    let byte = try container.readByte()
    if byte != SSType.number.rawValue {
      throw SSDecodingError.invalidType(
        actual: byte, expectedOneOf: [SSType.number.rawValue])
    }
    return try container.readNumber()
  }

  func decode(_ type: Float.Type) throws -> Float {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: Int.Type) throws -> Int {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: Int8.Type) throws -> Int8 {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: Int16.Type) throws -> Int16 {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: Int32.Type) throws -> Int32 {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: Int64.Type) throws -> Int64 {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: UInt.Type) throws -> UInt {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: UInt8.Type) throws -> UInt8 {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: UInt16.Type) throws -> UInt16 {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: UInt32.Type) throws -> UInt32 {
    type.init(try decode(Float64.self))
  }

  func decode(_ type: UInt64.Type) throws -> UInt64 {
    type.init(try decode(Float64.self))
  }

  func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    if type == SSUndecodedValue.self {
      let data = try container.collect()
      return SSUndecodedValue(data: data.rleEncode()) as! T
    }

    var ss = try SSDecoderImpl(container)
    ss.codingPath = codingPath
    return try type.init(from: ss)
  }
}
