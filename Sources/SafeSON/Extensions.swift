import Foundation

extension Data {
    func getContainer() -> DataContainer {
        DataContainer(self)
    }

    func rleEncode() -> Data {
        var encoded = Data()
        var n = 0 as UInt8

        for b in self {
            if b == 0 {
                if n == 255 {
                    encoded.append(contentsOf: [0])
                    encoded.append(contentsOf: [n])
                    n = 1
                } else {
                    n += 1
                }
            } else {
                if n != 0 {
                    encoded.append(contentsOf: [0])
                    encoded.append(contentsOf: [n])
                    n = 0
                }

                encoded.append(contentsOf: [b])
            }
        }

        if n != 0 {
            encoded.append(contentsOf: [0])
            encoded.append(contentsOf: [n])
        }

        return encoded
    }

    func rleDecode() -> Data {
        var encoded = Data()
        var z = false

        for b in self {
            if b == 0 {
                z = true
                continue
            }

            if z {
                for _ in 0..<b {
                    encoded.append(contentsOf: [0])
                    z = false
                }
            } else {
                encoded.append(contentsOf: [b])
            }
        }

        return encoded
    }
}
