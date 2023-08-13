import Foundation

public enum SSType: UInt8 {
    case false$ = 0
    case true$ = 1
    case null = 2
    case number = 3
    case string = 4
    case array = 5
    case object = 6
}

public struct SSNull: Codable {
    public init() {
    }
    
    public init(from decoder: Decoder) throws {
        if !(try decoder.singleValueContainer().decodeNil()) {
            throw SSDecodingError.expectedNull
        }
    }
    
    public enum CodingKeys: CodingKey {
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
