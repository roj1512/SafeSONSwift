import Foundation
import SafeSON

let value = "Hello, world!"

let encoded = try SSEncoder().encode(value)
print(Array(encoded))

let decoded = try SSDecoder().decode(String.self, from: encoded)
print(decoded)
