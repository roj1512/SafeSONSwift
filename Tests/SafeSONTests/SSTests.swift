import XCTest
@testable import SafeSON

func v<T: Codable & Equatable>(_ value: T) throws {
    let decoded = try SSDecoder().decode(T.self, from: try SSEncoder().encode(value))
    XCTAssertEqual(value, decoded)
}

final class SSTests: XCTestCase {
    func testNegative() throws {
        try v(false)
    }

    func testPositive() throws {
        try v(true)
    }

    func testNil() throws {
        try v(nil as Bool?)
    }

    func testNumber() throws {
        try v(0)
        try v(1)
        try v(0.01)
        try v(-100.232)
        try v(9_007_199_254_740_991)
        try v(-9_007_199_254_740_991)
    }

    func testString() throws {
        try v("Hello")
    }
    
    func testString2() throws {
        try v(String(repeating: "Hello, world!", count: 50))
    }

    func testArray() throws {
        try v([312312, 312321, 3123, 32, 542, -1.23232323])
    }
    
    func testArray2() throws {
        let arr: [String?] = ["String", nil]
        try v(arr)
    }

    func testArray3() throws {
        let arr = [Int]()
        try v(arr)
    }

    func testArray4() throws {
        var arr = [String]()
        for _ in 1...300 {
            arr.append("Hello, world!")
        }
        try v(arr)
    }

    func testObject() throws {
        let responseMessages = [
            200: "OK",
            403: "Forbidden",
            404: "Not Found",
            500: "Internal Server Error",
        ]
        try v(responseMessages)
    }
    
    func testObject2() throws {
        var maybeDict: [String:String]? = [
            "v": "1"
        ]
        try v(maybeDict)
        maybeDict = nil
        try v(maybeDict)
    }
    
    func testObject3() throws {
        var kv = [String:String]()
        for _ in 1...300 {
            kv[UUID().uuidString] = UUID().uuidString
        }
        try v(kv)
    }
}
